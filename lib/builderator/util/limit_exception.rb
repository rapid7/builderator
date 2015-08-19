require_relative './task_exception'

module Builderator
  module Util
    ##
    # Exception raised if a safety limit is exceeded
    ##
    class LimitException < TaskException
      attr_reader :resources

      def initialize(klass, task, resources)
        super(:limit, task, :yellow)

        @klass = klass
        @resources = resources
      end

      def count
        @resources.size
      end

      def limit
        @klass::LIMIT
      end

      def resource
        @klass.name
      end

      def message
        "Safety limit exceeded for task `#{ task }`: Count #{ count } is"\
        " greater than the limit of #{ limit } set in #{ resource }. Please"\
        " re-run this task with the --no-limit flag if you are sure this is"\
        " the correct set of resources to delete."
      end
    end
  end
end
