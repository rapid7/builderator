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

      ##
      # The compile method renders a single File instance from all of the configured
      # input layers. It follows the following algorithm:
      #
      # => `DIRTY` is defined as the logical OR of the dirty state of each layer.
      #    Layers are responsible for detecting changes to their own properties
      #    while being compiled.
      #
      # => LOOP unitl not DIRTY plus 1 iteration
      #     1. Call each layer's own compile method.
      #     2. For each layer, merge it into the COMPILED output.
      #     FAIL if ITERATIONS > LIMIT
      #
      # => The additional iteration after DIRTY becomes false is to ensure that
      #    any changes to the compiled output during the final merge are passed
      #    back through each layer's compile.
      ##
      def compile(max_iterations = 6)
        compiled.unseal
        compile_iterations = 0
        break_break = false

        ## Inject GLOBAL_DEFAULTS before starting compile
        compiled.merge(GLOBAL_DEFAULTS.compile)

        ## Automatically recompile while layers are dirty
        loop do
          fail "Re-compile iteration limit of #{max_iterations} has been exceeded. "\
               "#{all_layers.select(&:dirty).map(&:source).join(', ')} are dirty." if compile_iterations >= max_iterations

          ## Merge layers from lowest to highest. Compile, then merge.
          all_layers.each do |layer|
            layer.compile
          end

          all_layers.each do |layer|
            layer.policies.each { |_, policy| compiled.merge(policy) }

            ## Merge layer after its policy documents to allow overides
            compiled.merge(layer)
          end

          break if break_break && !dirty?

          break_break = !dirty?
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

      def reset!
        @layers = []

        @defaults = File.new({}, :source => 'defaults')
        @overrides = File.new({}, :source => 'overrides')
        @argv = File.new({}, :source => 'argv')

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
