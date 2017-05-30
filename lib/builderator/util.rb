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

      def ecr(region = Config.aws.region)
        clients["ecr-#{region}"] ||= Aws::ECR::Client.new(:region => region)
      end

      def asg(region = Config.aws.region)
        clients["asg-#{region}"] ||= Aws::AutoScaling::Client.new(:region => region)
      end

      def remove_security_group(region = Config.aws.region, group_id = nil)
        ec2 = ec2(region)
        resp = ec2.delete_security_group(group_id: group_id)
        puts "  Deleted SecurityGroup #{group_id}"
      end

      def get_security_group_id(region = Config.aws.region, vpc_id = nil)
        ec2 = ec2(region)
        group = nil
        group_id = nil
        require 'open-uri'
        external_ip = open('http://checkip.amazonaws.com').read.strip
        cidr_ip = external_ip + '/32'

        # Create a security group
        resp = ec2.create_security_group(group_name: "BuilderatorSecurityGroupSSHOnly-#{Time.now.to_i}",
                                         description: "Created by Builderator at #{Time.now}",
                                         vpc_id: vpc_id)
        group_id = resp[:group_id]

        resp = ec2.describe_security_groups(group_ids: [group_id])
        groups = resp[:security_groups]
        group = groups.first

        # Ensure the group_id has the right permissions
        resp = ec2.authorize_security_group_ingress(group_id: group_id,
                                                    ip_protocol: 'tcp',
                                                    from_port: 22,
                                                    to_port: 22,
                                                    cidr_ip: cidr_ip)
        puts "  Created SecurityGroup #{group_id}"
        group_id
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
