require 'thor'

require_relative '../interface/berkshelf'
require_relative '../patch/thor-actions'

module Builderator
  module Tasks
    ##
    # Wrap Berkshelf commands
    ##
    class Berkshelf < Thor
      include Thor::Actions

      attr_reader :config

      def initialize(*_)
        super
        @config = Interface.berkshelf.write
      end

      def self.exit_on_failure?
        true
      end

      desc 'vendor', 'Vendor a cookbook release and its dependencies'
      def vendor
        empty_directory config.vendor

        command = "berks vendor #{config.vendor} "
        command << "-c #{config.berkshelf_config} "
        command << "-b #{config.source}"

        inside config.directory do
          remove_file config.lockfile
          run command
        end
      end

      desc 'upload', 'Upload the local cookbook source and its dependencies to the Chef server'
      def upload
        vendor

        command = 'berks upload '
        command << "-c #{config.berkshelf_config} "
        command << "-b #{config.source}"

        run command
      end

      desc 'uncache', 'Delete the Berkshelf cache'
      def uncache
        remove_dir File.join(ENV['HOME'], '.berkshelf/cookbooks')
      end

      desc 'clean', 'Remove a local vendor directory'
      def clean
        remove_dir Interface.berkshelf.vendor
        remove_file config.source
        remove_file config.lockfile
      end
    end
  end
end
