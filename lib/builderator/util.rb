module Builderator
  module Util
    class << self
      def to_array(arg)
        arg.is_a?(Array) ? arg : [arg]
      end

      def from_tags(aws_tags)
        {}.tap { |tt| aws_tags.each { |t| tt[t.key.to_s] = t.value } }
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
    end
  end
end
