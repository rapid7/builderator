require 'thor'

require_relative './config'
require_relative './patch/thor-actions'

# require_relative './tasks/cookbook'
require_relative './tasks/vendor'
require_relative './tasks/version'

require_relative './tasks/berkshelf'
require_relative './tasks/packer'
require_relative './tasks/vagrant'

module Builderator
  module Tasks
    ##
    # Top-level command line tasks
    ##
    class CLI < Thor
      include Thor::Actions
      VERSION = ['--version', '-v'].freeze

      map VERSION => :print_version

      def initialize(*_)
        super

        # Ignore existing config when we don't need it: i.e. `help`
        ignore_existing_config = ['help'] + VERSION
        return if ignore_existing_config.any? do |i|
          ARGV.include?(i) || ARGV.empty?
        end

        Config.argv(options) ## Load command flags
        Config.load(File.join(ENV['HOME'], '.builderator/Buildfile'))
        Config.load(Util.relative_path('Buildfile').to_s)
        Config.compile
      end

      desc '--version, -v', 'Print Builderator version'
      def print_version
        say Gem.loaded_specs['builderator'].version
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
        invoke Tasks::Vendor, :all, [], options
        invoke Tasks::Version, :current, [], options
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
      method_option :remote_tag, :type => :boolean, :default => true
      method_option :copy, :type => :boolean, :default => true
      def image(profile = :default)
        prepare

        invoke Tasks::Packer, :build, [profile], options
        invoke Tasks::Packer, :copy, [profile], options if options['copy']
        invoke Tasks::Packer, :remote_tag, [profile], options if options['remote_tag']
      end

      desc 'container [PROFILE = docker]', 'Build a container of PROFILE'
      method_option :debug, :type => :boolean
      def container(profile = :docker)
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
      def config(key = nil)
        invoke Tasks::Version, :current, [], options

        return puts Config.compiled.send(key).to_json unless key.nil?
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
      # Generator
      ##
      desc 'generate [PROJECT=default]', 'Run a generator'
      method_option 'build-name', :type => :string
      method_option :ignore, :type => :array
      method_option :sync, :type => :array
      method_option :rm, :type => :array
      def generate(project = :default)
        fail 'Please provide a valid build name with the `--build-name=VALUE` option!' unless Config.has?(:build_name)
        Config.generator.project.use(project)

        Config.generator.project.current.resource.each do |rname, resource|
          next if (options['ignore'] && options['ignore'].include?(rname.to_s)) ||
                  resource.action == :ignore

          if (options['sync'] && options['sync'].include?(rname.to_s)) ||
             resource.action == :sync
            template resource.template, resource.path.first
            next
          end

          if (options['rm'] && options['rm'].include?(rname.to_s)) ||
             resource.action == :rm
            resource.path.each { |rm| remove_file rm }
            next
          end

          ## Create
          template resource.template, resource.path.first, :skip => true
        end
      end
    end
  end
end
