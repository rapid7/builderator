require_relative './task_exception'

module Builderator
  module Util
    ##
    # Exception raised if a safety limit is exceeded
    ##
    class LimitException < TaskException
      DEFAULT_LIMIT = 4

      attr_reader :resource_name
      attr_reader :resources

      def initialize(resource_name, task, resources)
        super(:limit, task, :yellow)

        @resource_name = resource_name
        @resources = resources
      end

      def count
        @resources.size
      end

      def limit
        Config[:cleaner][:limits].fetch(resource_name, DEFAULT_LIMIT)
      end

      def message
        "Safety limit exceeded for task `#{ task }`: Count #{ count } is"\
        " greater than the limit of #{ limit } set in #{ resource_name }. Please"\
        " re-run this task with the --no-limit flag if you are sure this is"\
        " the correct set of resources to delete."
      end
    end
  end
end
