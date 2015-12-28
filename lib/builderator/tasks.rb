require 'thor'

require_relative './config'

# require_relative './tasks/cookbook'
require_relative './tasks/vendor'
require_relative './tasks/version'

require_relative './tasks/berkshelf'
require_relative './tasks/packer'
require_relative './tasks/vagrant'

require_relative './tasks/generator'

module Builderator
  module Tasks
    ##
    # Top-level command line tasks
    ##
    class CLI < Thor
      def initialize(*_)
        super

        Config.argv(options) ## Load command flags
        Config.load(File.join(ENV['HOME'], '.builderator/Buildfile'))
        Config.load(Util.relative_path('Buildfile').to_s)

        Config.compile
      end

      def self.exit_on_failure?
        true
      end

      ## Globally enable/disable workspace cleanup
      class_option 'cleanup', :type => :boolean, :default => true

      ##
      # Tasks common to local, ec2, and ami builds
      ##
      desc 'prepare', 'Common preparation tasks for Vagrant and Packer'
      def prepare
        invoke Tasks::Version, :current, [], options
        invoke Tasks::Vendor, :all, [], options
        invoke Tasks::Berkshelf, :vendor, [], options
        # mvn package?
        # invoke Tasks::Cookbook, :prepare, []
      end

      ##
      # Main commands.
      #
      # `local`, `ec2`, and `build` invoke sets of subcommands to build VMs or images
      ##
      desc 'local [PROFILE = default VAGRANT_ARGS]', 'Provision a local VM of PROFILE'
      def local(*args)
        prepare
        invoke Tasks::Vagrant, :local, args, options
      end

      desc 'ec2 [PROFILE = default VAGRANT_ARGS]', 'Provision an EC2 instance of PROFILE'
      def ec2(*args)
        prepare
        invoke Tasks::Vagrant, :ec2, args, options
      end

      desc 'image [PROFILE = default]', 'Build an AMI of PROFILE'
      method_option :debug, :type => :boolean
      def image(profile = :default)
        prepare
        invoke Tasks::Packer, :build, [profile], options
      end

      # desc 'cookbook SUBCOMMAND', 'Cookbook tasks'
      # subcommand 'cookbook', Tasks::Cookbook

      desc 'vendor SUBCOMMAND', 'Vendor loading tasks'
      subcommand 'vendor', Tasks::Vendor

      desc 'version SUBCOMMAND', 'Version management tasks'
      subcommand 'version', Tasks::Version

      ##
      # Helper/utility commands
      ##
      desc 'config', 'Print compiled configuration'
      def config
        invoke Tasks::Version, :current, [], options
        puts Config.compiled.to_json
      end

      desc 'clean', 'Run cleanup tasks'
      def clean
        invoke Tasks::Vagrant, :clean
        invoke Tasks::Berkshelf, :clean
        invoke Tasks::Vendor, :clean
      end

      ##
      # CLI Wrappers
      ##
      desc 'berks SUBCOMMAND', 'Berkshelf helpers'
      subcommand 'berks', Tasks::Berkshelf

      desc 'packer SUBCOMMAND', 'Run Packer tasks'
      subcommand 'packer', Tasks::Packer

      desc 'vagrant SUBCOMMAND', 'Run Vagrant tasks'
      subcommand 'vagrant', Tasks::Vagrant

      ##
      # Generator subcommands
      ##
      desc 'generate SUBCOMMAND', 'Run a generator'
      subcommand 'generate', Tasks::Generator::Types
    end
  end
end
