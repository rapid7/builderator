require 'chef/cookbook/metadata'
require 'thor-scmversion'

require_relative '../util'

module Builderator
  module Util
    module Cookbook
      DEFAULT_VENDOR = Util.working_dir('vendor/chef/cookbooks')

      class << self
        def path(arg = nil)
          ## Set an explicit path to a cookbook
          return @path = arg unless arg.nil?
          return @path unless @path.nil?

          ## Check for an embedded cookbook? ('./cookbook')
          return @path = Util.working_dir('cookbook') if File.exist?(Util.working_dir('cookbook'))
          @path = Util.working_dir
        end

        def berksfile
          File.join(path, 'Berksfile')
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
