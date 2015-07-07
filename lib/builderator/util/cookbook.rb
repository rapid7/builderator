require 'chef/cookbook/metadata'
require 'thor-scmversion'

module Builderator
  module Util
    module Cookbook
      DEFAULT_VENDOR = './vendor/chef/cookbooks'
      class << self
        def path(arg = nil)
          return @path = arg unless arg.nil?
          @path || './'
        end

        def metadata
          Chef::Cookbook::Metadata.new.tap do |c|
            if File.exist?(File.join(path, 'metadata.rb'))
              c.from_file(File.join(path, 'metadata.rb'))
            elsif File.exist?(File.join(path, 'metadata.json'))
              c.from_json(IO.read(File.join(path, 'metadata.json')))
            else
              fail IOError, 'Unable to read metadata.rb or metadata.json!'
            end
          end
        end
      end
    end
  end
end
