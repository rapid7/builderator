require_relative '../util'

module Builderator
  module Control
    ##
    # Helpers for packer
    ##
    module Berks
      class << self
        def file
          dir = Dir.pwd

          ## Search in parent directory
          until File.exist?(File.join(dir, 'Berksfile'))
            return nil if dir == '/' ## Not found
            dir = File.dirname(dir)
          end

          File.join(dir, 'Berksfile')
        end

        def file!
          file.tap { |f| fail 'Unable to locate Berksfile!' if f.nil? }
        end
      end
    end
  end
end
