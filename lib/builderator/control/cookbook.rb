require 'pathname'

module Builderator
  module Control
    ##
    # Cookbook logic and helpers
    ##
    module Cookbook
      class << self
        def exist?
          Pathname.new(Config.cookbook.path).join('metadata.rb').exist?
        end
      end
    end
  end
end
