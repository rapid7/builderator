require 'forwardable'
require 'json'

require_relative './rash'

module Builderator
  module Config
    ##
    # Shared Attribute Mixin
    ##
    class Attributes
      ##
      # DSL Definition
      ##
      class << self
        def attribute(attribute_name, default = nil, **options)
          ##
          # Helpers for Array-type attributes
          ##
          if options[:type] == :list
            default = Array

            ## Add an appender DSL method
            define_method(options[:singular]) do |*args|
              append_if_valid(attribute_name, args.flatten, default, options)
            end if options.include?(:singular)
          end

          ## Getter/Setter
          define_method(attribute_name) do |*arg|
            arg.flatten!
            arg = arg.first unless options[:type] == :list

            set_or_return(attribute_name, arg, default, options)
          end

          ## Setter
          define_method("#{attribute_name}=") do |arg|
            set_if_valid(attribute_name, arg, options)
          end
        end

        ## Add a method the DSL
        def define(method_name, &block)
          define_method(method_name, &block)
        end

        ##
        # A Namespace is a singleton sub-node of the attribute-set
        #
        # e.g. `namespace :chef ...` maps to `attributes[:chef]` and adds a
        # method `chef(&block)` to the DSL which is used as follows:
        #
        # ```
        # chef do
        #   run_list 'foo', 'bar'
        #   ...
        # end
        # ```
        #
        # Multiple calls to the DSL method will are safe and will
        # update the same sub-node.
        ##
        def namespace(namespace_name, &definition)
          namespace_class = Namespace.create(namespace_name, &definition)

          define_method(namespace_name) do |&block|
            namespace_class.new(
              @attributes[namespace_name],
              :name => namespace_name, &block).compile
          end
        end

        ##
        # A Collection is a named-set of items in a sub-node of the attribute-set.
        #
        # Like Namespaces, Collections map to a top-level key, but they also have
        # multiple second-order keys:
        #
        # e.g. `collection :vagrant ...` adds a DSL method
        # `vagrant(name = :default, &block)` which maps to
        # `attributes[:vagrant][<name>]`
        #
        # Multiple entities can be added to the collection by calling the DSL method
        # with unique `name` arguments. Multiple calls to the DSL method with the
        # same name argument will update the existing entity in place
        ##
        def collection(collection_name, &definition)
          collection_class = Collection.create(collection_name, &definition)

          define_method(collection_name) do |instance_name = nil, &block|
            collection_instance = collection_class.new(
              @attributes[collection_name])

            return collection_instance if instance_name.nil?
            collection_instance.fetch(instance_name, &block).compile
          end
        end
      end

      extend Forwardable
      include Enumerable

      ## Delegate enumerables to underlying storage structure
      def_delegators :@attributes, :[], :fetch,
                     :keys, :values, :has?, :each,
                     :to_hash

      def seal
        attributes.seal
        self
      end

      def unseal
        attributes.unseal
        self
      end

      attr_reader :attributes
      attr_reader :dirty

      def initialize(attributes = {}, &block)
        @attributes = Rash.coerce(attributes)
        @block = block

        ## Track change status for comsumers
        @dirty = false
      end

      ## Clear dirty state flag
      def clean
        @dirty = false
      end

      def compile
        instance_eval(&@block) if @block
        self
      end

      def merge(other)
        attributes.merge!(other.attributes)
        self
      end
      alias_method :includes, :merge

      def to_json(*_)
        JSON.pretty_generate(to_hash)
      end

      protected

      def set_if_valid(key, arg, options = {})
        ## TODO: define validation interface

        ## Mutation helpers

        # Input is a path relative to the working directory
        arg = Util.relative_path(arg).to_s if options[:relative]

        # Input is a path relative to the workspace
        arg = Util.workspace(arg).to_s if options[:workspace]

        ## Unchanged
        return if @attributes[key] == arg

        @dirty = true ## A mutation has occured
        @attributes[key] = arg
      end

      def append_if_valid(key, arg, default = Array, **options)
        ## TODO: define validation interface

        attribute = set_or_return(key, nil, default, options)
        arg.reject! { |item| attribute.include?(item) }

        return if arg.empty?

        @dirty = true ## A mutation has occured
        attribute.push(*arg)
      end

      def set_or_return(key, arg = nil, default = nil, **options)
        if arg.nil? || (arg.is_a?(Array) && arg.empty?)
          return @attributes[key] if @attributes.has?(key)

          ## Default
          return if default.is_a?(NilClass) ## No default

          ## Allow a default to be a static value, or instantiated
          ## at call-time from a class (e.g. Array or Hash)
          default_value = default.is_a?(Class) ? default.new : default
          return default_value if @attributes.sealed

          return set_if_valid(key, default_value, options)
        end

        ## Set value
        set_if_valid(key, arg, options)
      end

      ##
      # Define a namespace for attributes
      ##
      class Namespace < Attributes
        class << self
          attr_accessor :name

          ##
          # Construct a new child-class to define the interface. The constructor
          # accepts an attributes argument, which should be a sub-node of the root
          # attribute-set.
          ##
          def create(namespace_name, &definition)
            space = Class.new(self)
            space.name = namespace_name

            ## Define DSL interface
            space.instance_eval(&definition) if definition

            space
          end
        end

        attr_reader :name
        attr_reader :collection

        def initialize(attributes, options = {}, &block)
          super(attributes, &block)

          @name = options.fetch(:name, self.class.name)
          @collection = options[:collection]
        end

        def compile
          @block.call(self) if @block
          self
        end

        ## Copy attributes from another instance in the same collection
        def extends(instance_name)
          return unless collection.is_a?(Collection)
          merge(collection[instance_name])
        end
      end

      ##
      # Enumerable wrapper for collections
      ##
      class Collection < Attributes
        class << self
          attr_accessor :name
          attr_accessor :namespace_class

          def create(collection_name, &definition)
            collection = Class.new(self)
            collection.name = collection_name
            collection.namespace_class = Namespace.create(collection_name, &definition)

            collection
          end
        end

        ## Enumerable methods return namespace instances
        def each(&block)
          attributes.each_key do |instance_name|
            block.call(instance_name, fetch(instance_name))
          end
        end

        def name
          self.class.name
        end

        ## Get namespace instances
        def fetch(instance_name, &block)
          self.class.namespace_class.new(
            attributes[instance_name],
            :collection => self,
            :name => instance_name, &block)
        end
        alias_method :[], :fetch
      end
    end
  end
end
