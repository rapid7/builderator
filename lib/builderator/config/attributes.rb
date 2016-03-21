require 'forwardable'
require 'json'

require_relative './rash'
require_relative './list'

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
            define_method(attribute_name) do |*arg, **run_options|
              ## Instantiate List if it doesn't exist yet. `||=` will always return a new Rash.
              @attributes[attribute_name] = Config::List.new(run_options) unless @attributes.has?(attribute_name, Config::List)

              @attributes[attribute_name].set(*arg.flatten) unless arg.empty?
              @attributes[attribute_name]
            end

            define_method(options[:singular]) do |*arg, **run_options|
              send(attribute_name, run_options).push(*arg.flatten)
            end if options.include?(:singular)

            return
          end

          ##
          # Helpers for Hash-type attributes
          ##
          if options[:type] == :hash
            define_method(attribute_name) do |arg = nil|
              ## Instantiate List if it doesn't exist yet. `||=` will always return a new Rash.
              @attributes[attribute_name] = Config::Rash.new unless @attributes.has?(attribute_name, Config::Rash)

              dirty(@attributes[attribute_name].merge!(Config::Rash.coerce(arg)).any?) unless arg.nil?
              @attributes[attribute_name]
            end

            return
          end

          ## Getter/Setter
          define_method(attribute_name) do |*arg|
            set_or_return(attribute_name, arg.first, default, options)
          end

          ## Setter
          define_method("#{attribute_name}=") do |arg|
            set_if_valid(attribute_name, arg, options)
          end
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
        # Multiple calls to the DSL method are safe and will
        # update the same sub-node.
        ##
        def namespace(namespace_name, &definition)
          namespace_class = Namespace.create(namespace_name, &definition)

          define_method(namespace_name) do |&block|
            nodes[namespace_name] ||= namespace_class.new(
              @attributes[namespace_name],
              :name => namespace_name,
              :parent => self, &block)
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
        #
        # An entry can be defined as an extension of another node by passing a hash
        # as the instance name: `name => Config.node(:name)`. This will use the values
        # defined in `Config.node(:name)` as defaults for the new entry
        ##
        def collection(collection_name, &definition)
          collection_class = Collection.create(collection_name, &definition)

          define_method(collection_name) do |instance_name = nil, &block|
            extension_base = nil

            ## Allow extension to be defined as a key-value
            if instance_name.is_a?(Hash)
              extension_base = instance_name.first.last
              instance_name = instance_name.first.first
            end

            nodes[collection_name] ||= collection_class.new(
              @attributes[collection_name],
              :parent => self)

            return nodes[collection_name] if instance_name.nil?
            nodes[collection_name].fetch(instance_name, :extends => extension_base, &block)
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

      ## Get the root Attributes object
      def root
        return self if root?

        parent.root
      end

      def root?
        parent == self
      end

      ## All dirty state should aggregate at the root node
      def dirty(update = false)
        return @dirty ||= update if root?
        root.dirty(update)
      end

      def dirty!(set)
        @dirty = set
      end

      def ==(other)
        attributes == other.attributes
      end

      attr_reader :attributes
      attr_reader :nodes
      attr_reader :parent
      attr_reader :extends

      def initialize(attributes = {}, options = {}, &block)
        @attributes = Rash.coerce(attributes)
        @nodes = {}
        @block = block

        ## Track change status for consumers
        @parent = options.fetch(:parent, self)
        @extends = options[:extends]
        @dirty = false
      end

      ## Clear dirty state flag
      def clean
        @dirty = false
      end

      def reset!
        @attributes = Config::Rash.new
        @nodes = {}
        @dirty = false
      end

      def compile(evaluate = true)
        ## Underlay base values if present
        if extends.is_a?(Attributes)
          previous_state = attributes
          dirty_state = dirty

          attributes.merge!(extends.attributes)

          @block.call(self) if @block && evaluate
          nodes.each { |_, node| node.compile }

          root.dirty!(dirty_state || previous_state.diff(attributes).any?)

          return self
        end

        ## Compile this node and its children
        @block.call(self) if @block && evaluate
        nodes.each { |_, node| node.compile }

        self
      end

      def merge(other)
        dirty(attributes.merge!(other.attributes).any?)
        self
      end

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

        dirty(true) ## A mutation has occured
        @attributes[key] = arg
      end

      def set_or_return(key, arg = nil, default = nil, **options)
        if arg.nil?
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
          super(attributes, options, &block)

          @name = options.fetch(:name, self.class.name)
          @collection = options[:collection]
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

        ## Allow a single instance to be selected
        attr_reader :current
        def use(instance_name)
          @current = fetch(instance_name)
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
        def fetch(instance_name, **options, &block)
          nodes[instance_name] ||= self.class.namespace_class.new(
            attributes[instance_name],
            :collection => self,
            :name => instance_name,
            :parent => self,
            :extends => options[:extends], &block)
        end
        alias_method :[], :fetch
      end
    end
  end
end
