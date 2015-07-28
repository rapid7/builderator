module Builderator
  module Util
    ##
    # Exception raised if a safety limit is exceeded
    ##
    class LimitException < StandardError
      attr_reader :task
      attr_reader :resources

      def initialize(klass, task, resources)
        @klass = klass
        @task = task
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

      def status
        [:limit, message, :yellow]
      end
    end
  end
end
