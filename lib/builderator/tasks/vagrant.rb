require 'thor'

require_relative '../interface/vagrant'
require_relative '../patch/thor-actions'

module Builderator
  module Tasks
    ##
    # Wrap vagrant commands
    ##
    class Vagrant < Thor
      include Thor::Actions
      class_option :config, :aliases => :c, :desc => "Path to Berkshelf's config.json"
      class_option :berksfile, :aliases => :b, :desc => 'Path to the Berksfile to use'

      attr_reader :config, :command

      def initialize(*_)
        @command = Gem.loaded_specs.key?('vagrant') ? 'vagrant' : '/usr/bin/vagrant'
        # unless Gem.loaded_specs.key?('vagrant')
        #   say '!!! Vagrant is not available in this bundle !!!!', [:red, :bold]
        #   puts ''
        #   say 'Please add the following to your Gemfile and update your bundle to use the `vagrant` command:'
        #   say '  +------------------------------------------------+', :green
        #   say "  | gem 'vagrant', :github => 'mitchellh/vagrant', |", :green
        #   say "  |                :tag => 'v1.7.4'                |", :green
        #   say '  +------------------------------------------------+', :green
        #
        #   exit 1
        # end

        super
      end

      def self.exit_on_failure?
        true
      end

      desc 'local [PROFILE [ARGS ...]]', 'Start VirtualBox VM(s)'
      def local(profile = :default, *args)
        @config ||= Interface.vagrant(profile)
        config.write

        inside config.directory do
          command = 'ulimit -n 1024; '
          command << 'VAGRANT_I_KNOW_WHAT_IM_DOING_PLEASE_BE_QUIET=true '
          command << "#{@command} up --provider=#{config.local.provider} #{args.join(' ')}"

          run command
        end
      end

      desc 'ec2 [PROFILE [ARGS ...]]', 'Start EC2 instances'
      def ec2(profile = :default, *args)
        @config ||= Interface.vagrant(profile)
        config.write

        inside config.directory do
          command = 'ulimit -n 1024; '
          command << 'VAGRANT_I_KNOW_WHAT_IM_DOING_PLEASE_BE_QUIET=true '
          command << "#{@command} up --provider=#{config.ec2.provider} #{args.join(' ')}"

          run command
        end
      end

      desc 'provision [PROFILE [ARGS ...]]', 'Reprovision Vagrant VM(s)'
      def provision(profile = :default, *args)
        @config ||= Interface.vagrant(profile)

        inside config.directory do
          command = 'ulimit -n 1024; '
          command << 'VAGRANT_I_KNOW_WHAT_IM_DOING_PLEASE_BE_QUIET=true '
          command << "#{@command} provision #{args.join(' ')}"

          run command
        end
      end

      desc 'destroy [PROFILE [ARGS ...]]', 'Destroy Vagrant VM(s)'
      method_option :force, :aliases => :f, :type => :boolean, :default => true
      def destroy(profile = :default, *args)
        @config ||= Interface.vagrant(profile)

        inside config.directory do
          command = 'ulimit -n 1024; '
          command << 'VAGRANT_I_KNOW_WHAT_IM_DOING_PLEASE_BE_QUIET=true '
          command << "#{@command} destroy #{args.join(' ')} "
          command << '-f' if options['force']

          run command
        end
      end

      desc 'rebuild ARGS', 'Destroy and recreate Vagrant VM(s)'
      method_option :force, :aliases => :f, :type => :boolean, :default => true
      def rebuild(profile = :default, *args)
        destroy(profile, *args)
        up(profile, *args)
      end

      desc 'clean', 'Destroy VMs and clean up local files'
      method_option :force, :aliases => :f, :type => :boolean, :default => true
      def clean(profile = :default)
        destroy(profile)

        remove_dir config.directory.join('.vagrant')
        remove_file config.source
      end
    end
  end
end
