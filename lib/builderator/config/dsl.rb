require_relative './mash'

module Builderator
  module Config
    ##
    # DSL parser base
    ##
    class DSL
      class << self
        def from_file(path)
          new.instance_eval(IO.read(path), path, 0)
        end

        def from_dsl(parent, name, &block)
          new(parent, name).instance_eval(&block)
        end
      end

      def initialize
        @attribures = Mash.new
      end

      def [](key)
        @attribures[key]
      end

      def []=(key, val)
        @attribures[key] = val
      end

      def has?(key)
        @attribures.include?(key)
      end

      private

      ## Allow set_or_return to accept an array of keys
      def expand_attrs_path(path)
        return @attribures if path.empty?

        ## Walk a hash of hashes. This will work nicely with Mash.
        path.inject(@attribures) { |a, e| a[e] }
      end

      def validate_before_set(_keys, arg, _options)
        arg ## NOOP until we define the validation interface
      end

      def set_or_return(keys, arg = nil, default = nil, **options)
        keys = keys.is_a?(Array) ? keys : [keys]
        path = keys[0...-1]
        last = keys.last

        if arg.nil? || (arg.is_a?(Array) && arg.empty?)
          ## Set dafeult value
          return expand_attrs_path(path)[last] = validate_before_set(keys, default, options) if @attribures[name].nil?
          return expand_attrs_path(path)[last]
        end

        expand_attrs_path(path)[last] = validate_before_set(keys, arg, options)
      end
    end
  end
end
