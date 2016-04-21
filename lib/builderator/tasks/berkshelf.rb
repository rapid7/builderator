require 'chef/cookbook/metadata'
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

      desc 'metadata COOKBOOK', 'Generate metadata.json from metadata.rb for a COOKBOOK that has a path'
      def metadata(cookbook)
        fail "Cookbook #{ cookbook } does not have a path!" unless Config.cookbook.depends.has?(cookbook) &&
                                                                   !Config.cookbook.depends[cookbook].path.nil?

        cookbook_path = Config.cookbook.depends[cookbook].path
        metadata_rb = Chef::Cookbook::Metadata.new

        metadata_rb.from_file(::File.join(cookbook_path, 'metadata.rb'))

        say_status :metadata, "for cookbook #{ metadata_rb.name }@#{ metadata_rb.version }"
        create_file ::File.join(cookbook_path, 'metadata.json'), metadata_rb.to_json, :force => true
      end

      desc 'vendor', 'Vendor a cookbook release and its dependencies'
      def vendor
        invoke :configure, [], options
        empty_directory Interface.berkshelf.vendor

        command = "#{Interface.berkshelf.command} vendor #{Interface.berkshelf.vendor} "
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

        command = "#{Interface.berkshelf.command} upload "
        command << "-c #{Interface.berkshelf.berkshelf_config} "
        command << "-b #{Interface.berkshelf.source}"

        inside Interface.berkshelf.directory do
          run command
        end
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
