require 'pathname'

module Builderator
  module Util
    class << self
      def to_array(arg)
        arg.is_a?(Array) ? arg : [arg]
      end

      def from_tags(aws_tags)
        {}.tap { |tt| aws_tags.each { |t| tt[t.key.to_s] = t.value } }
      end

      def filter(resources, filters = {})
        resources.select do |_, r|
          _filter_reduce(r, filters)
        end
      end

      def filter!(resources, filters = {})
        resources.select! do |_, r|
          _filter_reduce(r, filters)
        end

        resources
      end

      def region(arg = nil)
        return @region || 'us-east-1' if arg.nil?
        @region = arg
      end

      def ec2
        @ec2 ||= Aws::EC2::Client.new(:region => region)
      end

      def asg
        @asg ||= Aws::AutoScaling::Client.new(:region => region)
      end

      def working_dir(relative = '.')
        Pathname.pwd.join(relative).expand_path
      end

      private

      def _filter_reduce(resource, filters)
        filters.reduce(true) do |memo, (k, v)|
          ## Allow for negation with a leading `~`
          if v[0] == '~'
            memo && (!resource[:properties].include?(k.to_s) || resource[:properties][k.to_s] != v[1..-1])
          else
            memo && resource[:properties].include?(k.to_s) && resource[:properties][k.to_s] == v
          end
        end
      end
    end
  end
end

require_relative './util/aws_exception'
require_relative './util/limit_exception'
