module Builderator
  module Config
    ##
    # Extend Array with context about how its values should be merged with other
    # configuration layers. Possible modes are:
    #
    # * 'override' - Do not merge. Replace the other node's elements
    # * 'union' - Perform a set-union on the elements of this and the other node
    ##
    class List < Array
      class << self
        def coerce(somehting, options = {})
          return somehting if somehting.is_a?(self)
          return new(options).push(*somehting) if somehting.is_a?(Array)

          ## `somehting` is not a valid input. Just give back an instance.
          new([], options)
        end
      end

      attr_reader :mode

      def initialize(from = nil, **options)
        @mode = options.fetch(:mode, :union)

        merge!(from) unless from.nil?
      end

      def clone
        self.class.new(self, :mode => mode)
      end

      def set(*elements)
        clear
        push(*elements)
      end

      ##
      # Combine elements with `other` according to `other`'s `mode`
      ##
      def merge!(other)
        other = self.class.coerce(other)

        case other.mode
        when :override
          return false if self == other
          set(*other)

        when :union
          merged = self | other
          return false if merged == self

          set(*merged)

        else
          fail "Invalid List mode #{other.mode}!"
        end

        true
      end
    end
  end
end
