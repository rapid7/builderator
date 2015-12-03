module Builderator
  module Config
    ##
    # A self-populating sparse Hash by Rapid7 ([R]apid7 h[ASH]). Definetly
    # not a Mash or Smash...
    ##
    class Rash < Hash
      class << self
        def coerce(somehting)
          return somehting if somehting.is_a?(self)
          return new(somehting) if somehting.is_a?(Hash)

          ## `somehting` is not a valid input. Just give back an instance.
          new
        end
      end

      attr_accessor :sealed

      def initialize(from = {}, seal = false)
        @sealed = seal
        super() do |_, k|
          self[k] = self.class.new unless sealed
        end

        merge!(from) ## Clone a Rash or coerce a Hash to a new Rash
      end

      def seal(action = true)
        @sealed = action
        each_value { |v| v.seal(action) if v.is_a?(self.class) }
      end

      def unseal
        seal(false)
      end

      alias_method :has?, :include?

      ## Symbolize keys
      [:include?, :[], :fetch, :[]=, :store].each do |m|
        define_method(m) do |key, *args|
          super(key.to_sym, *args)
        end
      end

      def merge!(other)
        fail TypeError, 'Argument other of  `Rash#merge!(other)` must be a Hash.'\
                        " Recieved #{other.class}" unless other.is_a?(Hash)

        other.each do |k, v|
          ## Replace `-`s with `_`s in in String keys
          k = k.gsub(/\-/, '_') if k.is_a?(String)

          ## Merge Arrays
          next self[k] += v if fetch(k, nil).is_a?(Array) && v.is_a?(Array)

          ## Overwrite non-Hash values
          next self[k] = v unless v.is_a?(Hash)

          ## Replace `self[k]` with a new Rash unless it already is one
          self[k] = self.class.new unless fetch(k, nil).is_a?(self.class)

          ## Merge recursivly coerces `v` to a Rash
          self[k].merge!(v)
        end
      end

      def to_hash
        each_with_object({}) do |(k, v), hash|
          ## Not a hash-value
          next hash[k] = v unless v.is_a?(self.class)

          ## Recursivly coerces `v` to a Hash
          hash[k] = v.to_hash
        end
      end
    end
  end
end
