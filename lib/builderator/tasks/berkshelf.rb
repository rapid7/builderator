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


      def self.exit_on_failure?
        true
      end

      desc 'configure', 'Write a Berksfile into the project workspace'
      def configure
        Interface.berkshelf.write
      end

      desc 'vendor', 'Vendor a cookbook release and its dependencies'
      def vendor
        empty_directory Interface.berkshelf.vendor

        command = "berks vendor #{Interface.berkshelf.vendor} "
        command << "-c #{Interface.berkshelf.berkshelf_config} "
        command << "-b #{Interface.berkshelf.source}"

        inside Interface.berkshelf.directory do
          remove_file Interface.berkshelf.lockfile
          run command
        end
      end

      desc 'upload', 'Upload the local cookbook source and its dependencies to the Chef server'
      def upload
        vendor

        command = 'berks upload '
        command << "-c #{Interface.berkshelf.berkshelf_config} "
        command << "-b #{Interface.berkshelf.source}"

        run command
      end

      desc 'uncache', 'Delete the Berkshelf cache'
      def uncache
        remove_dir File.join(ENV['HOME'], '.berkshelf/cookbooks')
      end

      desc 'clean', 'Remove a local vendor directory'
      def clean
        remove_dir Interface.berkshelf.vendor
        remove_file Interface.berkshelf.source
        remove_file Interface.berkshelf.lockfile
      end
    end
  end
end
