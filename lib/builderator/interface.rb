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
  class Interface
    class << self
      def command(arg = nil)
        @command = arg unless arg.nil?
        @command
      end

      def from_gem(arg = nil)
        @from_gem = arg unless arg.nil?
        @from_gem || @command
      end

      def template(arg = nil)
        @template = arg unless arg.nil?
        @template
      end
    end

    ## Is vagrant in this bundle?
    def bundled?
      Gem.loaded_specs.key?(self.class.from_gem)
    end

    def which
      return self.class.command if bundled?

      ## Not in the bundle. Use system path
      `which #{self.class.command}`.chomp.tap { |path| fail "Unable to locate a #{self.class.command} executable" if path.empty? }
    end
    alias_method :command, :which

    def directory
      Util.workspace
    end

    def render
      ERB.new(Util.source_path(self.class.template).binread,
              nil, '-', '@output_buffer').result(Config.instance_eval('binding'))
    end

    def source
      fail 'Interface does not provide a source!'
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
