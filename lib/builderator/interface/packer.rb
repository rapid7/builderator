require_relative '../interface'

module Builderator
  # :nodoc:
  class Interface
    class << self
      def packer
        @packer ||= Packer.new
      end
    end

    ##
    # Generate packer.json
    ##
    class Packer < Interface
      command 'packer'
      attr_reader :packerfile

      def initialize(*_)
        super

        @packerfile ||= {
          :builders => [],
          :provisioners => [],
          'post-processors' => []
        }.tap do |json|
          Config.profile.current.packer.build.each do |_, build|
            build_hash = build.to_hash.tap do |b|
              b[:tags] = Config.profile.current.tags unless Config.profile.current.tags.empty?
            end

            if build_hash[:type] == 'docker'
              raise 'The Docker builder requires a base image' unless build_hash.key?(:image)

              # The Docker builder requires one and only one of 'commit', 'discard', or 'export_path' set
              if build_hash.keys.find_all { |k| [:commit, :discard, :export_path].include?(k) }.length != 1
                raise 'The Docker builder requires one and only one of `commit`, `discard`, or `export_path` attributes to be defined'
              end
            end

            # If we specify encrypted boot, packer won't allow ami_users.
            # See: https://github.com/MYOB-Technology/packer/blob/509cd7dcf194beb6ca6d0c39057f7490fa630d78/builder/amazon/common/ami_config.go#L59-L61

            # A PR (https://github.com/mitchellh/packer/pull/4023) has been
            # submitted to resolve this issue but we shouldn't remove this
            # until a new Packer release with this feature.
            if build_hash.key?(:encrypt_boot)
              build_hash.delete(:ami_users)
            end

            ## Support is missing for several regions in some versions of Packer
            # Moving this functionality into a task until we can confirm that Packer
            # has full support again.
            build_hash.delete(:ami_regions)

            # This is not directly supported by Packer
            build_hash.delete(:tagging_role)

            json[:builders] << build_hash
          end

          post_processors = []

          # Post-processors should be considered as a sequence
          Config.profile.current.packer.post_processor.each do |name, post_processor|
            post_processor_hash = post_processor.to_hash

            # Single, named step in a sequence
            if post_processor_hash.empty?
              post_processors << name
              next
            end

            post_processors << post_processor_hash
          end
          json['post-processors'].push(post_processors)

          ## Initialize the staging directory
          json[:provisioners] << {
            :type => 'shell',
            :inline => "sudo mkdir -p #{Config.chef.staging_directory}/cache && "\
                       "sudo chown $(whoami) -R #{Config.chef.staging_directory}"
          }

          json.delete('post-processors') if json['post-processors'].empty?
        end

        _artifact_provisioners
        _chef_provisioner
      end

      def render
        JSON.pretty_generate(packerfile)
      end

      private

      ## Upload artifacts to the build container
      def _artifact_provisioners
        Config.profile.current.artifact.each do |_, artifact|
          packerfile[:provisioners] << {
            :type => 'file',
            :source => artifact.path,
            :destination => artifact.destination
          }
        end
      end

      def _chef_provisioner
        packerfile[:provisioners] << {
          :type => 'chef-solo',
          :run_list => Config.profile.current.chef.run_list,
          :cookbook_paths => Config.local.cookbook_path,
          :data_bags_path => Config.local.data_bag_path,
          :environments_path => Config.local.environment_path,
          :chef_environment => Config.profile.current.chef.environment,
          :json => Config.profile.current.chef.node_attrs,
          :staging_directory => Config.chef.staging_directory,
          :install_command => "curl -L https://www.chef.io/chef/install.sh | sudo bash -s -- -v #{Config.chef.version}"
        }
      end
    end
  end
end
