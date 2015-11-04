module Builderator
  module Config
    ##
    # A self-populating sparse Hash
    ##
    class Mash < Hash
      def initialize(hash = {})
        super() { |_, k| self[k] = self.class.new }
        merge(hash) ## Clone a Mash or coerce a Hash to a new Mash
      end

      alias_method :has?, :include?

      def merge(other)
        fail TypeError, 'Argument other of  `Mash.merge(other)` must be a Hash.'\
                        " Recieved #{other.class}" unless other.is_a?(Hash)

        other.each do |k, v|
          ## Overwrite non-Hash values
          next self[k] = v unless v.is_a?(Hash)

          ## Replace `self[k]` with a new Mash unless it already is one
          self[k] = self.class.new unless fetch(k, nil).is_a?(self.class)

          ## Merge recursivly coerces `v` to a Mash
          self[k].merge(v)
        end
      end

      ## These are the same for Mash
      alias_method :merge!, :merge

      def method_missing(k, *args)
        return self[k] if args.empty?
        self[k] = args.first
      end

      def set_unless_nil(k, value = nil)
        self[k] = value unless value.nil?
      end
    end
  end
end
