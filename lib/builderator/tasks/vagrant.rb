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

      def self.exit_on_failure?
        true
      end

      desc 'configure [PROFILE]', 'Write a Vagrantfile into the project workspace'
      def configure(profile = :default)
        Config.profile.use(profile)
        invoke Tasks::Version, :current, [], options

        Interface.vagrant.write
      end

      desc 'local [PROFILE [ARGS ...]]', 'Start VirtualBox VM(s)'
      def local(profile = :default, *args)
        invoke :configure, [profile], options

        inside Interface.vagrant.directory do
          command = Interface.vagrant.command
          command << " up --provider=#{Config.profile.current.vagrant.local.provider} "
          command << args.join(' ')

          run command
        end
      end

      desc 'ec2 [PROFILE [ARGS ...]]', 'Start EC2 instances'
      def ec2(profile = :default, *args)
        invoke :configure, [profile], options

        inside Interface.vagrant.directory do
          command = Interface.vagrant.command
          command << " up --provider=#{Config.profile.current.vagrant.ec2.provider} "
          command << args.join(' ')

          run command
        end
      end

      desc 'provision [PROFILE [ARGS ...]]', 'Reprovision Vagrant VM(s)'
      def provision(profile = :default, *args)
        invoke :configure, [profile], options

        inside Interface.vagrant.directory do
          command = Interface.vagrant.command
          command << " provision #{args.join(' ')}"

          run command
        end
      end

      desc 'status [PROFILE [ARGS ...]]', 'Reprovision Vagrant VM(s)'
      def status(profile = :default, *args)
        invoke :configure, [profile], options

        inside Interface.vagrant.directory do
          command = Interface.vagrant.command
          command << " status #{args.join(' ')}"

          run command
        end
      end

      desc 'ssh [PROFILE [ARGS ...]]', 'SSH into Vagrant VM(s)'
      def ssh(profile = :default, *args)
        invoke :configure, [profile], options

        inside Interface.vagrant.directory do
          command = Interface.vagrant.command
          command << " ssh #{args.join(' ')}"

          ## Connect to subprocesses STDIO
          exec(command)
        end
      end

      desc 'destroy [PROFILE [ARGS ...]]', 'Destroy Vagrant VM(s)'
      method_option :force, :aliases => :f, :type => :boolean, :default => true
      def destroy(profile = :default, *args)
        invoke :configure, [profile], options

        inside Interface.vagrant.directory do
          command = Interface.vagrant.command
          command << " destroy #{args.join(' ')}"
          command << ' -f' if options['force']

          run command
        end
      end

      desc 'clean', 'Destroy VMs and clean up local files'
      method_option :force, :aliases => :f, :type => :boolean, :default => true
      def clean(profile = :default)
        destroy(profile)

        remove_dir Interface.vagrant.directory.join('.vagrant')
        remove_file Interface.vagrant.source
      end

      desc 'plugins [PROJECT=default]', 'Install plugins required for PROJECT'
      def plugins(project = :default)
        if Interface.vagrant.bundled?
          say 'Vagrant is already bundled. Required plugins are already part of the bundle as well'
          return
        end

        Config.generator.project.use(project)
        Config.generator.project.current.vagrant.plugin.each do |pname, plugin|
          command = Interface.vagrant.command
          command << " plugin install #{ pname }"
          command << " --plugin-version #{ plugin.version }" if plugin.has?(:version)

          run command
        end
      end
    end
  end
end
