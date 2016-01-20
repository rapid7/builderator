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
        ([defaults] + layers + [overrides, argv])
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

        ## Initialize with global defaults
        compiled.merge(GLOBAL_DEFAULTS.compile)

        ## Automatically recompile while layers are dirty
        loop do
          fail "Re-compile iteration limit of #{max_iterations} has been exceeded" if compile_iterations >= max_iterations

          ## Reset flags before next iteration
          compiled.clean

          ## Merge layers from lowest to highest. Compile, then merge.
          all_layers.each(&:compile)
          all_layers.each do |layer|
            compiled.merge(layer)

            layer.policies.each { |_, policy| compiled.merge(policy) }
          end

          break unless dirty?
          compile_iterations += 1
        end

        ## Don't auto-populate keys anymore
        compiled.seal
      end
      alias_method :recompile, :compile

      def dirty?
        all_layers.any?(&:dirty) || compiled.dirty
      end

      def compiled
        @compiled ||= File.new({}, :source => 'compiled')
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
