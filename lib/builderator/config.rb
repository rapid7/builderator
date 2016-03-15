require_relative './config/file'
require_relative './config/defaults'

module Builderator
  ##
  # Global Configuration
  ##
  module Config
    class << self
      def reset!
        @layers = nil
        @defaults = nil
        @overrides = nil
        @argv = nil
        @compiled = nil
      end

      ## GLOBAL_DEFAULTS is the lowest-precedence layer, followed by dynamically
      ## defined instance-defaults.
      def layers
        @layers ||= []
      end

      def all_layers
        ([GLOBAL_DEFAULTS, defaults] + layers + [overrides, argv])
      end

      def defaults
        @defaults ||= File.new({}, :source => 'defaults')
      end

      def overrides
        @overrides ||= File.new({}, :source => 'overrides')
      end

      def argv(options = {})
        @argv ||= File.new(options, :source => 'argv')
      end

      def append(path)
        layers << File.from_file(path) if ::File.exist?(path)
      end
      alias_method :load, :append

      def append_json(path)
        layers << File.from_json(path) if ::File.exist?(path)
      end
      alias_method :load_json, :append_json

      def prepend(path)
        layers.unshift(File.from_file(path)) if ::File.exist?(path)
      end

      def prepend_json(path)
        layers.unshift(File.from_json(path)) if ::File.exist?(path)
      end

      def compile(max_iterations = 6)
        compiled.unseal
        compile_iterations = 0

        ## Inject GLOBAL_DEFAULTS before starting compile
        compiled.merge(GLOBAL_DEFAULTS.compile)

        ## Automatically recompile while layers are dirty
        loop do
          fail "Re-compile iteration limit of #{max_iterations} has been exceeded" if compile_iterations >= max_iterations

          ## Merge layers from lowest to highest. Compile, then merge.
          all_layers.each do |layer|
            layer.compile
          end

          all_layers.each do |layer|
            layer.policies.each { |_, policy| compiled.merge(policy) }

            ## Merge layer after its policy documents to allow overides
            compiled.merge(layer)
          end

          break unless dirty?
          compile_iterations += 1
        end

        ## Don't auto-populate keys anymore
        compiled.seal
      end
      alias_method :recompile, :compile

      def dirty?
        all_layers.any?(&:dirty)
      end

      def compiled
        @compiled ||= File.new({}, :source => 'compiled')
      end

      def reset
        @layers = []

        @defaults = File.new({}, :source => 'defaults')
        @overrides = File.new({}, :source => 'overrides')
        @argv = File.new(options, :source => 'argv')

        @compiled = File.new({}, :source => 'compiled')
      end

      def fetch(key, *args)
        compiled.send(key, *args)
      end
      alias_method :[], :fetch

      def method_missing(method_name, *args)
        return super unless compiled.respond_to?(method_name)

        compiled.send(method_name, *args)
      end
    end
  end
end
