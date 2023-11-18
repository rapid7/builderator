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

      class_option :debug, :type => :boolean, :desc => 'Show debug output'

      def self.exit_on_failure?
        true
      end

      desc 'configure', 'Write a Berksfile into the project workspace'
      def configure
        Interface.berkshelf.write
      end

      desc 'chefignore', 'Create or Update chefignore to ignore .builderator directory'
      def chefignore
        ignore_file_list = ['.builderator']
        ignore = Util.relative_path('chefignore').to_s
        ignore_file = ::File.readlines(ignore)
        ignore_file.map! { |i| i.chomp }
        files = ignore_file_list.all? { |i| ignore_file.include?(i) }
        unless files
          file = ::File.open(ignore, 'a')
          file.printf("\n# Builderator Added Values\n")
          say_status :chefignore, "Adding the following to chefignore: #{ignore_file_list.join(',')}.  Add this to SCM!", :yellow
          ignore_file_list.each do |ignore|
            file.puts(ignore)
          end
        end
        dest_chefignore = Interface.berkshelf.directory.join('chefignore')
        ::FileUtils.rm dest_chefignore if ::File.exist?(dest_chefignore)
        ::FileUtils.cp ignore, dest_chefignore
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
        invoke :chefignore, [], options
        invoke :configure, [], options

        empty_directory Interface.berkshelf.vendor

        command = "#{Interface.berkshelf.command} vendor #{Interface.berkshelf.vendor} "
        command << "-d " if options[:debug]
        command << "-c #{Interface.berkshelf.berkshelf_config} " unless Interface.berkshelf.berkshelf_config.nil?
        command << "-b #{Interface.berkshelf.source}"

        remove_file Interface.berkshelf.lockfile
        inside Interface.berkshelf.directory do
          run command
        end
      end

      desc 'upload', 'Upload the local cookbook source and its dependencies to the Chef server'
      def upload
        vendor

        command = "#{Interface.berkshelf.command} upload "
        command << "-d " if options[:debug]
        command << "-c #{Interface.berkshelf.berkshelf_config} " unless Interface.berkshelf.berkshelf_config.nil?
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
