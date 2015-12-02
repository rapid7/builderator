require_relative './config/file'
require_relative './config/defaults'

module Builderator
  ##
  # Global Configuration
  ##
  module Config
    class << self
      ## GLOBAL_DEFAULTS is the lowest-precedence layer, followed by dynamically
      ## defined instance-defaults.
      def layers
        @layers ||= []
      end

      def defaults
        @defaults ||= File.new({}, :source => 'defaults', :config => self)
      end

      def overrides
        @overrides ||= File.new({}, :source => 'overrides', :config => self)
      end

      def argv(options = {})
        @argv ||= File.new(options, :source => 'overrides', :config => self)
      end

      def append(path)
        layers << File.from_file(path, :config => self) if ::File.exist?(path)
      end
      alias_method :load, :append

      def append_json(path)
        layers << File.from_json(path, :config => self) if ::File.exist?(path)
      end
      alias_method :load_json, :append_json

      def prepend(path)
        layers.unshift(File.from_file(path, :config => self)) if ::File.exist?(path)
      end

      def prepend_json(path)
        layers.unshift(File.from_json(path, :config => self)) if ::File.exist?(path)
      end

      def compile
        ## Merge layers from lowest to highest
        compiled_layers = ([GLOBAL_DEFAULTS, defaults] + layers + [overrides, argv])
                          .reduce(File.new({}, :config => self)) do |file, layer|
                            file.merge(layer.compile)
                          end

        ## Don't auto-populate keys anymore
        compiled_layers.seal
      end

      def recompile
        @compiled = compile
      end

      def compiled
        @compiled ||= compile
      end

      def compiled?
        !@compiled.nil?
      end

      def fetch(key, *args)
        compiled.send(key, *args)
      end
      alias_method :[], :fetch

      def method_missing(method_name, *args)
        return super unless compiled? && compiled.respond_to?(method_name)

        compiled.send(method_name, *args)
      end
    end
  end
end
