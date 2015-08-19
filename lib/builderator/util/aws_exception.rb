require 'json'
require_relative './task_exception'

module Builderator
  module Util
    ##
    # Exception raised if a safety limit is exceeded
    ##
    class AwsException < TaskException
      attr_reader :exception

      def initialize(task, exception)
        super(:fail, task, :red)
        @exception = exception
      end

      def operation
        @exception.context.operation_name
      end

      def parameters
        @exception.context.params
      end

      def message
        "An error occured executing performing task #{ task }. #{ operation }"\
          "(#{ JSON.generate(parameters) }): #{ exception.message }"
      end
    end
  end
end
