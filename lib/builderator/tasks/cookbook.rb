require 'thor'
require 'thor/actions'
require_relative '../util/cookbook'

module Builderator
  module Tasks
    class Cookbook < Thor
      include Thor::Actions
      class_option :version, :type => :boolean,
                             :default => true,
                             :desc => 'Write current verison to file'

      desc 'metadata [PATH = ./]', 'Use cookbook matadata file at PATH/metadata.rb to generate PATH/matadata.json'
      def metadata(cookbook_path = './')
        invoke 'version:current', [], options if options['version']
        Util::Cookbook.path(cookbook_path)

        create_file File.join(Util::Cookbook.path, 'metadata.json'),
                    Util::Cookbook.metadata.to_json, :force => true
      end

      desc 'version COOKBOOK', 'Print the current version of a vendored cookbook'
      option :path, :default => Util::Cookbook::DEFAULT_VENDOR, :desc => 'Path to vendored cookbooks'
      def version(cookbook)
        Util::Cookbook.path(File.join(options['path'], cookbook))
        puts Util::Cookbook.metadata.version
      end
    end
  end
end
