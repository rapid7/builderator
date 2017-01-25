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

        docker_builders = Config.profile.current.packer.build.select do |_, builder|
          builder.to_h[:type] == 'docker'
        end

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
              if build_hash.keys.select { |k| [:commit, :discard, :export_path].include?(k) }.length != 1
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

          json['post-processors'].push(_post_processors)
          json.delete('post-processors') if json['post-processors'].compact.empty?

          ## Initialize the staging directory unless using the docker builder
          json[:provisioners] << {
            :type => 'shell',
            :inline => "sudo mkdir -p #{Config.chef.staging_directory}/cache && "\
                       "sudo chown $(whoami) -R #{Config.chef.staging_directory}"
          } if docker_builders.empty?

          # Only add artifact provisioners if they're defined
          Config.profile.current.artifact.each do |_, artifact|
            json[:provisioners] << _artifact_provisioner(artifact)
          end unless Config.profile.current.artifact.attributes.empty?

          # Only add chef provisioners if they're defined
          unless Config.profile.current.chef.attributes.empty?
            # There are certain options (staging directory, run as sudo) that don't apply
            # to the docker builder.
            json[:provisioners] << if docker_builders.empty?
                                     _chef_provisioner
                                   else
                                     _chef_provisioner_docker
                                   end
          end

          # After adding the default provisioners, we add any additional ones to the provisioners array
          Config.profile.current.provisioner.each do |name, provisioner|
            json[:provisioners] << provisioner.attributes.tap { |p| p[:type] = name.to_s }
          end

          json.delete(:provisioners) if json[:provisioners].empty?
        end
      end

      def render
        JSON.pretty_generate(packerfile)
      end

      private

      def _post_processors
        post_processors = []
        # Post-processors should be considered as a sequence
        Config.profile.current.packer.post_processor.each do |name, post_processor|
          post_processor_hash = post_processor.to_hash

          # Single, named step in a sequence
          if post_processor_hash.empty?
            post_processors << name
            next
          end

          # The post-processor's type should be the same as the name
          post_processor_hash[:type] = name

          post_processors << post_processor_hash
        end
        post_processors.empty? ? nil : post_processors
      end

      ## Upload artifacts to the build container
      def _artifact_provisioner(artifact)
        {
          :type => 'file',
          :source => artifact.path,
          :destination => artifact.destination
        }
      end

      def _chef_provisioner
        _chef_provisioner_base.merge(
          :staging_directory => Config.chef.staging_directory,
          :install_command => _chef_install_command
        )
      end

      def _chef_provisioner_docker
        _chef_provisioner_base.merge(
          :prevent_sudo => true,
          :install_command => _chef_install_command(false)
        )
      end

      def _chef_provisioner_base
        {
          :type => 'chef-solo',
          :run_list => Config.profile.current.chef.run_list,
          :cookbook_paths => Config.local.cookbook_path,
          :data_bags_path => Config.local.data_bag_path,
          :environments_path => Config.local.environment_path,
          :chef_environment => Config.profile.current.chef.environment,
          :json => Config.profile.current.chef.node_attrs,
        }
      end

      def _chef_install_command(sudo = true)
        template = sudo ? 'sudo' : ''
        format("curl -L https://www.chef.io/chef/install.sh | %s bash -s -- -v #{Config.chef.version}", template)
      end
    end
  end
end
