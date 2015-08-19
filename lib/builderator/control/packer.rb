require 'json'
require_relative '../util'

module Builderator
  module Control
    ##
    # Helpers for packer
    ##
    module Packer
      class << self
        def version(arg = nil)
          return @version = arg unless arg.nil?
          @version || '0.8.2'
        end
        alias_method :use, :version

        def installed?
          File.exist?(path)
        end

        def platform
          `uname -s`.chomp.downcase
        end

        def path
          File.join(ENV['HOME'], "packer_#{ version }")
        end

        def bin
          File.join(ENV['HOME'], "packer/packer")
        end

        def url
          "https://dl.bintray.com/mitchellh/packer/packer_#{ version }_#{ platform }_amd64.zip"
        end
      end
    end
  end
end
