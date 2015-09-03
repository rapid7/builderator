require 'thor'
require 'thor/actions'
require_relative './berks'

module Builderator
  module Tasks
    class Vagrant < Thor
      include Thor::Actions
      class_option :config, :aliases => :c, :desc => "Path to Berkshelf's config.json"
      class_option :berksfile, :aliases => :b, :desc => 'Path to the Berksfile to use'

      def initialize(*_)
        unless Gem.loaded_specs.key?('vagrant')
          say '!!! Vagrant is not available in this bundle !!!!', [:red, :bold]
          puts ''
          say 'Please add the following to your Gemfile and update your bundle to use the `vagrant` command:'
          say '  +------------------------------------------------+', :green
          say "  | gem 'vagrant', :github => 'mitchellh/vagrant', |", :green
          say "  |                :tag => 'v1.7.4'                |", :green
          say '  +------------------------------------------------+', :green

          exit 1
        end

        super
      end

      desc 'up ARGS', 'Start Vagrant VM(s)'
      def up(*args)
        command = 'ulimit -n 1024;'
        command << ' VAGRANT_I_KNOW_WHAT_IM_DOING_PLEASE_BE_QUIET=true'
        command << " vagrant up #{ args.join(' ') }"

        invoke Tasks::Berks, 'local', [], options
        run command
      end

      desc 'provision ARGS', 'Provision Vagrant VM(s)'
      def provision(*args)
        command = 'ulimit -n 1024;'
        command << ' VAGRANT_I_KNOW_WHAT_IM_DOING_PLEASE_BE_QUIET=true'
        command << " vagrant provision #{ args.join(' ') }"

        invoke Tasks::Berks, 'local', [], options
        run command
      end

      desc 'destroy ARGS', 'Destroy Vagrant VM(s)'
      option :force, :aliases => :f, :type => :boolean
      def destroy(*args)
        command = 'ulimit -n 1024;'
        command << ' VAGRANT_I_KNOW_WHAT_IM_DOING_PLEASE_BE_QUIET=true'
        command << " vagrant destroy #{ args.join(' ') }"
        command << ' -f' if options['force']

        run command
      end

      desc 'rebuild ARGS', 'Destroy and recreate Vagrant VM(s)'
      def rebuild(*args)
        invoke Tasks::Vagrant, 'destroy', args, options.merge('force' => true)
        invoke Tasks::Vagrant, 'up', args, options
      end
    end
  end
end
