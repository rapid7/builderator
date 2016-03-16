require_relative './list'

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

      def clone
        self.class.new(self, sealed)
      end

      def seal(action = true)
        @sealed = action
        each_value { |v| v.seal(action) if v.is_a?(self.class) }
      end

      def unseal
        seal(false)
      end

      def has?(key, klass = BasicObject)
        include?(key) && fetch(key).is_a?(klass)
      end

      ## Symbolize keys
      [:include?, :[], :fetch, :[]=, :store].each do |m|
        define_method(m) do |key, *args|
          super(key.to_sym, *args)
        end
      end

      def merge!(other)
        fail TypeError, 'Argument other of  `Rash#merge!(other)` must be a Hash.'\
                        " Recieved #{other.class}" unless other.is_a?(Hash)

        other.each_with_object([]) do |(k, v), diff|
          ## Replace `-`s with `_`s in in String keys
          k = k.gsub(/\-/, '_') if k.is_a?(String)

          next if has?(k) && self[k] == v

          ## Merge Arrays
          if v.is_a?(Array)
            self[k] = has?(k) ? Config::List.coerce(self[k]) : Config::List.new
            self[k].merge!(v)

            diff << k
            next
          end

          ## Overwrite non-Hash values
          unless v.is_a?(Hash)
            self[k] = v
            diff << k

            next
          end

          ## Merge recursivly coerces `v` to a Rash
          self[k] = self.class.coerce(self[k])
          diff << self[k].merge!(v)
        end
      end

      def diff(other)
        fail TypeError, 'Argument other of `Rash#diff(other)` must be a Hash.'\
                        " Recieved #{other.class}" unless other.is_a?(Hash)

        other.each_with_object({}) do |(k, v), diff|
          next if has?(k) && self[k] == v

          ## Merge Arrays
          if v.is_a?(Array)
            a = has?(k) ? Config::List.coerce(self[k]) : Config::List.new
            b = Config::List.coerce(v)

            diff[k] = {
              :+ => b - a,
              :- => a - b
            }

            next
          end

          ## Overwrite non-Hash values
          unless v.is_a?(Hash)
            diff[k] = {
              :+ => v,
              :- => fetch(k, nil)
            }

            next
          end

          diff[k] = self.class.coerce(fetch(k, {})).diff(self.class.coerce(v))
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
