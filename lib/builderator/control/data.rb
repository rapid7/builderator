module Builderator
  module Control
    ##
    # Wrapper module for lookup controllers
    module Data
      def self.lookup(source, query)
        fail "#{ source } is not a valid data type!" unless respond_to?(source)

        send(source, query)
      end
    end
  end
end

require_relative './data/image'
