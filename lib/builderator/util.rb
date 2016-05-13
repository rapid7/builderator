require 'pathname'

module Builderator
  ##
  # Shared helper methods
  ##
  module Util
    GEM_PATH = Pathname.new(__FILE__).join('../../..').expand_path
    WORKSPACE = '.builderator'.freeze
    VENDOR = 'vendor'.freeze

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
        Pathname.pwd.join(*(relative.flatten.map(&:to_s))).expand_path
      end

      def workspace(*relative)
        relative_path(WORKSPACE, relative)
      end

      def vendor(*relative)
        workspace(VENDOR, relative)
      end

      def source_path(*relative)
        GEM_PATH.join(*(relative.flatten.map(&:to_s))).expand_path
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
      def ec2(region = Config.aws.region, credentials=nil)
        options = { :region => region }

        # Don't memoize if supplying explicit credentials as it could be an assumed role for a remote account
        if credentials.nil?
          clients["ec2-#{region}"] ||= Aws::EC2::Client.new(options)
        else
          Aws::EC2::Client.new options.merge(credentials)
        end
      end

      def asg(region = Config.aws.region)
        clients["asg-#{region}"] ||= Aws::AutoScaling::Client.new(:region => region)
      end

      private

      def clients
        @clients ||= {}
      end

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
