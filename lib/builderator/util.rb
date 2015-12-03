require 'pathname'

module Builderator
  ##
  # Shared helper methods
  ##
  module Util
    GEM_PATH = Pathname.new(__FILE__).join('../../..').expand_path
    WORKSPACE = '.builderator'.freeze

    class << self
      ##
      # Transform helpers
      ##
      def to_array(arg)
        arg.is_a?(Array) ? arg : [arg]
      end

      def from_tags(aws_tags)
        {}.tap { |tt| aws_tags.each { |t| tt[t.key.to_s] = t.value } }
      end

      ##
      # Relative path from working directory
      ##
      def relative_path(*relative)
        Pathname.pwd.join(*relative).expand_path
      end

      def workspace(*relative)
        relative_path.join(WORKSPACE).join(*relative)
      end

      def source_path(*relative)
        GEM_PATH.join(*relative).expand_path
      end

      ##
      # Set-filter helpers
      ##
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

      ##
      # AWS Clients
      ##
      def ec2
        @ec2 ||= Aws::EC2::Client.new(:region => Config.aws.region)
      end

      def asg
        @asg ||= Aws::AutoScaling::Client.new(:region => Config.aws.region)
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
