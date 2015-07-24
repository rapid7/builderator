module Builderator
  module Model
    ##
    # Shared model interface
    ##
    class Base
      attr_reader :resources

      def initialize(*args)
        fetch(*args)
      end

      def fetch
        @resources = {}
      end

      def find(filters = {})
        Util.filter(resources, filters)
      end

      def select(set = [])
        resources.select { |k, _| set.include?(k) }
      end

      def reject(set)
        resources.reject { |k, _| set.include?(k) }
      end

      def in_use(options = {})
        find(options.fetch('filters', {}))
      end

      def unused(options = {})
        Util.filter(reject(in_use(options)), options.fetch('filters', {}))
      end
    end
  end
end

require_relative './model/images'
require_relative './model/instances'
require_relative './model/launch_configs'
require_relative './model/scaling_groups'
require_relative './model/snapshots'
require_relative './model/volumes'
