module Builderator
  module Util
    ##
    # Generic wrapper for exceptions in Thor Tasks
    ##
    class TaskException < StandardError
      attr_reader :status
      attr_reader :task

      def initialize(status, task, color = :red)

        @status = status
        @task = task
        @color = color
      end

      def status
        [@status, message, @color]
      end
    end
  end
end
