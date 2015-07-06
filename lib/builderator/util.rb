module Builderator
  module Util
    class << self
      def to_array(arg)
        arg.is_a?(Array) ? arg : [arg]
      end
    end
  end
end
