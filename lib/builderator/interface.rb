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

    def initialize(*_)
      ## Ensure that Config is compiled before reading from it
      Config.recompile

      super
    end

    def directory
      Util.workspace
    end

    def render
      ERB.new(Util.source_path(self.class.template).binread,
              nil, '-', '@output_buffer').result(instance_eval('binding'))
    end

    def write
      directory.mkpath
      source.write(render)
      self
    end

    def clean
      source.unlink
    end
  end
end
