require 'thor'
require 'thor/actions'
require_relative './cookbook'
require_relative '../control/berks'

module Builderator
  module Tasks
    class Berks < Thor
      include Thor::Actions
      class_option :config, :aliases => :c, :desc => "Path to Berkshelf's config.json"
      class_option :berksfile, :aliases => :b, :desc => 'Path to the Berksfile to use'

      desc "local [PATH = #{ Util::Cookbook::DEFAULT_VENDOR }]", 'Vendor the local cookbook source and its dependencies'
      def local(path = Util::Cookbook::DEFAULT_VENDOR)
        command = 'BERKS_INSTALL_FROM=source'
        command << " berks vendor #{ path }"
        command << " -c #{ options['config'] }" if options.include?('config')
        command << " -b #{ options['berksfile'] }" if options.include?('berksfile')

        remove_file File.expand_path('../Berksfile.lock', Control::Berks.file!(options['berksfile']))

        cookbook_path = options.include?('berksfile') ? File.dirname(options['berksfile']) : './'
        invoke Tasks::Cookbook, 'metadata', [cookbook_path], {}

        run command
      end

      desc "vendor [PATH = #{ Util::Cookbook::DEFAULT_VENDOR }]", 'Vendor a cookbook release and its dependencies'
      def vendor(path = Util::Cookbook::DEFAULT_VENDOR)
        command = 'BERKS_INSTALL_FROM=release'
        command << " berks vendor #{ path }"
        command << " -c #{ options['config'] }" if options.include?('config')
        command << " -b #{ options['berksfile'] }" if options.include?('berksfile')

        remove_file File.expand_path('../Berksfile.lock', options.fetch('berksfile', Control::Berks.file!))
        run command
      end

      desc 'upload', 'Upload the local cookbook source and its dependencies to the Chef server'
      option 'dry-run', :type => :boolean, :default => false
      option :path, :default => Util::Cookbook::DEFAULT_VENDOR
      def upload
        command = 'BERKS_INSTALL_FROM=source'
        command << " berks upload"
        command << " -c #{ options['config'] }" if options.include?('config')
        command << " -b #{ options['berksfile'] }" if options.include?('berksfile')

        invoke Tasks::Berks, :local, [options.delete('path')], options

        return say_status :dryrun, command if options['dry-run']
        run command
      end

      desc 'uncache', 'Delete the Berkshelf cache'
      def uncache
        remove_dir File.join(ENV['HOME'], '.berkshelf/cookbooks')
      end

      desc "clean [PATH = #{ Util::Cookbook::DEFAULT_VENDOR }]", 'Remove a local vendor directory'
      def clean(path = Util::Cookbook::DEFAULT_VENDOR)
        remove_dir path
      end
    end
  end
end
