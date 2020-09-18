require 'aws-sdk'
require 'thor'
require 'retryable'

require_relative '../control/data'
require_relative '../interface/packer'
require_relative '../patch/thor-actions'

module Builderator
  module Tasks
    ##
    # Wrap Packer commands
    ##
    class Packer < Thor
      include Thor::Actions

      def self.exit_on_failure?
        true
      end

      class_option :debug, :type => :boolean

      desc 'configure [PROFILE=default]', 'Generate a packer configuration'
      def configure(profile = :default)
        Config.profile.use(profile)

        invoke Tasks::Version, :current, [], options
        puts Interface.packer.render if options['debug']
      end

      desc 'build [PROFILE=default *ARGS]', 'Run a build with the installed version of packer'
      def build(profile = :default, *args)
        invoke :configure, [profile], options
        run_with_input "#{Interface.packer.command} build #{options['debug'] ? '-debug -on-error=abort' : ''} - #{args.join('')}", Interface.packer.render
      end

      desc 'copy PROFILE', 'Copy AMIs generated by packer to other regions'
      def copy(profile)
        invoke :configure, [profile], options

        images.each do |image_name, (image, build)|
          parameters = {
            :source_region => Config.aws.region,
            :source_image_id => image.image_id,
            :name => image_name,
            :description => image.description
          }

          build.ami_regions.each do |region|
            say_status :copy, "image #{image_name} (#{image.image_id}) from #{Config.aws.region} to #{region}"
            copy_image(region, parameters)
          end
        end

        invoke :wait, [profile], options
        invoke :tag, [profile], options
        invoke :share, [profile], options
      end

      desc 'tag PROFILE', 'Tag AMIs in other regions'
      def tag(profile)
        invoke :configure, [profile], options

        images.each do |image_name, (image, build)|
          ## Add some additional tags about the regional source
          image.tags << {
            :key => 'source_region',
            :value => Config.aws.region
          }
          image.tags << {
            :key => 'source_ami',
            :value => image.image_id
          }

          build.ami_regions.each do |region|
            regional_image = find_image(region, image_name)

            say_status :tag, "AMI #{image_name} (#{regional_image.image_id}) in #{region}"
            Util.ec2(region).create_tags(:resources => [regional_image.image_id], :tags => image.tags)
          end
        end
      end

      desc 'wait PROFILE', 'Wait for copied AMIs to become available in another region'
      def wait(profile)
        invoke :configure, [profile], options

        waiting = true

        images.each do |image_name, (image, build)|
          say_status :wait, "for #{image.image_id} (#{image_name}) to be available in #{build.ami_regions.join(', ')}", :yellow
        end

        while waiting
          waiting = false

          images.each do |image_name, (image, build)|
            build.ami_regions.each do |region|
              regional_image = find_image(region, image_name)

              ## It takes a few seconds for the new AMI to show up in the `describe_images` response-set
              state = regional_image.nil? ? 'unknown' : regional_image.state
              image_id = regional_image.nil? ? 'unknown' : regional_image.image_id

              waiting = (state != 'available') || waiting
              status_color = case state
                             when 'pending', 'unknown' then :yellow
                             when 'available' then :green
                             else :red
                             end

              say_status :image, "#{image_id} (#{image.name}) is #{state} in #{region}", status_color
            end
          end

          ## If waiting == false, loop immediately to break
          sleep(20) if waiting
        end

        say_status :complete, 'All copied images are available'
      end

      desc 'remote_tag PROFILE', 'Apply existing tags to the AMI in remote AWS accounts'
      def remote_tag(profile)
        invoke :configure, [profile], options

        allowed_cred_keys = %w(access_key_id secret_access_key session_token)

        images.each do |image_name, (image, build)|
          ami_regions = build.ami_regions
          ami_regions << Config.aws.region
          ami_regions.uniq!
          ami_regions.each do |region|

            sts_client = Aws::STS::Client.new(region: region)

            if build.tagging_role.nil?
              say_status :complete, 'No remote tagging to be performed as no IAM role is defined'
              return
            end

            regional_image = find_image(region, image_name)

            build.ami_users.each do |account|
              role_arn = "arn:aws:iam::#{account}:role/#{build.tagging_role}"
              begin
                response = sts_client.assume_role( :role_arn => role_arn, :role_session_name => "tag-new-ami")
                raise "Could not assume role [#{role_arn}].  Perhaps it does not exist?" unless response.successful?
              rescue => e
                say_status :skip, "Got error when trying to assume role: #{e.message} - continuing."
                next
              end

              creds_hash = response.credentials.to_h.keep_if { |k,v| allowed_cred_keys.include?(k.to_s) }

              say_status :remote_tag, "Tag AMI #{image_name} (#{regional_image.image_id}) in #{region} (#{account})"
              Util.ec2(region, creds_hash)
                  .create_tags(:dry_run => false, :resources => [regional_image.image_id], :tags => image.tags)
            end
          end
        end
        say_status :complete, 'Remote tagging complete'
      end

      desc 'share PROFILE', 'Share copied AMIs in other accounts'
      def share(profile)
        invoke :configure, [profile], options

        shared = false

        images.each do |image_name, (image, build)|
          build.ami_regions.each do |region|
            build.ami_users.each do |user|
              shared = true

              regional_image = find_image(region, image_name)

              say_status :share, "image #{image_name} (#{regional_image.image_id}) with #{user}"

              share_image_parameters = {
                :image_id => regional_image.image_id,
                :launch_permission => {
                  :add => [
                    {
                      :user_id => user
                    }
                  ]
                }
              }

              Util.ec2(region).modify_image_attribute(share_image_parameters)
            end
          end
        end
        say_status :complete, 'All images are shared' if shared
      end

      private

      ## Find details for generated images in current region
      def images
        Retryable.retryable(:sleep => lambda { |n| 4**n }, :tries => 10, :on => [NoMethodError]) do |retries, _|
          @images ||= Config.profile.current.packer.build.each_with_object({}) do |(_, build), memo|
            memo[build.ami_name] = [Control::Data.lookup(:image, :name => build.ami_name).first, build]
          end
          @images.length # Will throw NoMethodError if no images found; triggers retry
        end
        @images
      end

      def copy_image(region, params)
        Retryable.retryable(:sleep => lambda { |n| 4**n }, :tries => 4, :on => [Aws::EC2::Errors::ServiceError]) do |retries, _|
          say_status :error, 'Error copying image', :red if retries > 0
          Util.ec2(region).copy_image(params)
        end
      end

      def find_image(region, image_name)
        filters = [{
          :name => 'name',
          :values => [image_name]
        }]

        image = nil
        Retryable.retryable(:sleep => lambda { |n| 4**n }, :tries => 4, :on => [Aws::EC2::Errors::ServiceError]) do |retries, _|
          say_status :error, 'Error finding image', :red if retries > 0
          image = Util.ec2(region).describe_images(:filters => filters).images.first
        end
        image
      end
    end
  end
end
