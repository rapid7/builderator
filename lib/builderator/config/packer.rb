require_relative './dsl'
require_relative './mash'

module Builderator
  module Config
    ##
    # DSL Loader for a Packer build configuration
    ##
    class Packer < Config::DSL
      def initialize(parent, name)
        super

        @parent = parent
        @name = name
      end

      ##
      # Builder parameters
      ##
      def instance_type(arg = nil)
        set_or_return(:instance_type, arg, 't2.small')
      end

      def region(arg = nil)
        set_or_return(:region, arg, @parent.aws_region)
      end

      def ssh_username(arg = nil)
        set_or_return(:instance_type, arg, 'ubuntu')
      end

      def source_ami(arg = nil)
        set_or_return(:source_ami, arg)
      end

      def virtualization_type(arg = nil)
        set_or_return(:ami_virtualization_type, arg, 'hvm')
      end

      def description(arg = nil)
        set_or_return(:source_ami, arg)
      end

      def tags
        set_or_return(:tags, nil, Mash.new)
      end

      def version(arg = nil)
        set_or_return(:version, arg, @parent.version)
      end

      ##
      # Chef Provisioner parameters
      ##
      def run_list(*args)
        set_or_return(:run_list, args.flatten, @parent.run_list)
      end

      def environment(arg = nil)
        set_or_return(:environment, arg, @parent.environment)
      end

      def node_attrs(arg = nil)
        set_or_return(:environment, arg, @parent.node_attrs)
      end

      def cookbook_paths(*args)
        set_or_return(:cookbook_paths, args.flatten, @parent.cookbook_paths)
      end

      def data_bag_path(arg = nil)
        set_or_return(:data_bag_path, arg, @parent.data_bag_path)
      end

      def environment_path(arg = nil)
        set_or_return(:environment_path, arg, @parent.environment_path)
      end

      def chef_directory(arg = nil)
        set_or_return(:chef_directory, arg, '/var/chef')
      end
    end
  end
end
