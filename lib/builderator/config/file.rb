require_relative './mash'
require_relative './packer'
require_relative './vagrant'

module Builderator
  module Config
    ##
    # DSL Loader for a configuration file
    ##
    class File < DSL
      def initialize
        super

        @packer = {}
        @vagrant = {}
        @vendors = {}
      end

      ##
      # Chef configurations
      ##
      def run_list(*args)
        set_or_return([:chef, :run_list], args.flatten)
      end

      def environment(arg = nil)
        set_or_return([:chef, :environment], arg)
      end

      def node_attrs(arg = nil)
        set_or_return([:chef, :node_attrs], arg, Mash.new)
      end

      def cookbook_paths(*args)
        set_or_return([:chef, :cookbooks_path], args.flatten, [])
      end

      def data_bag_path(arg = nil)
        set_or_return([:chef, :data_bag_path], arg)
      end

      def environment_path(arg = nil)
        set_or_return([:chef, :environment_path], arg)
      end

      ##
      # AWS configurations
      ##
      def aws_region(arg = nil)
        set_or_return([:aws, :region], arg, 'us-east-1')
      end

      def aws_key(arg = nil)
        set_or_return([:aws, :key], arg)
      end

      def aws_secret(arg = nil)
        set_or_return([:aws, :secret], arg)
      end

      ## Add a Packer build
      def packer(name = 'default', &block)
        return @packer[name] if block.nil?

        @packer[name] = Packer.from_dsl(self, name, &block)
      end

      ## Add a Vagrant VM
      def vagrant(name = 'default', &block)
        return @vagrant[name] if block.nil?

        @vagrant[name] = Vagrant.from_dsl(self, name, &block)
      end

      ## Add a vendor source
      def vendor(name, source)
        @vendors[name] = source
      end
    end
  end
end
