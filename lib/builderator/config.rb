require_relative './config/file'
require_relative './config/mash'

module Builderator
  ##
  # Global Configuration
  ##
  module Config
    class << self
      def layers
        @layers ||= []
      end

      def defaults
        @default ||= Mash.new(
          :aws => {
            :region => 'us-east-1'
          },
          :cleaner => {
            :limits => {
              :images => 24,
              :launch_configs => 24,
              :snapshots => 24,
              :volumes => 8
            }
          }
        )
      end

      def overrides
        @override ||= Mash.new
      end

      def load(path)
        layers << Config::File.load(path) if ::File.exist?(path)
      end

      ## Get the most precedent attribute value
      def get(k)
        ## Overrides beat everything
        return overrides[k] if overrides.has?(k)

        ## The last layer is the most precedent: Search in reverse.
        layers.reverse_each do |layer|
          return layer[k] if layer.has?(k)
        end

        ## Defaults are last
        defaults[k]
      end

      alias_method :[], :get

      ## Getters for composed hashes of vandors, Packerfiles,and Vagrantfiles
      [:vendors, :packer, :vagrant].each do |col|
        define_method(col) do
          ## In order of precedence, compose a single hash. Last occurance
          ## of a key wins, which works because the layers stack is ordered low -> high
          layers.each_with_object({}) do |layer, memo|
            memo.merge(layer.send(col))
          end
        end
      end
    end
  end
end
