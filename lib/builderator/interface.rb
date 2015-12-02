require 'erb'
require 'fileutils'
require 'securerandom'

require_relative './config/attributes'
require_relative './config/rash'
require_relative './util'

module Builderator
  ##
  # Base class for integration interfaces
  ##
  class Interface < Config::Attributes
    class << self
      def template(arg = nil)
        @template = arg unless arg.nil?
        @template
      end
    end

    def directory
      Util.workspace
    end

    def write
      directory.mkpath
      source.write(
        ERB.new(Util.source_path(self.class.template).binread,
                nil, '-', '@output_buffer').result(instance_eval('binding')))
      self
    end

    def clean
      source.unlink
    end
  end
end
