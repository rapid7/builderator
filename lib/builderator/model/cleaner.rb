module Builderator
  module Model
    module Cleaner
      ##
      # Shared model interface
      ##
      class Base
        attr_reader :resources

        def initialize(*args)
          fetch(*args)
        end

        def fetch
          @resources = {}
        end

        def find(filters = {})
          Util.filter(resources, filters)
        end

        def select(set = [])
          resources.select { |k, _| set.include?(k) }
        end

        def in_use
          find(Config.cleaner.filters)
        end

        def in_use?(key)
          @in_use ||= in_use

          @in_use.include?(key)
        end

        def unused
          resources.reject { |k, _| in_use?(k) }
        end
      end
    end
  end
end

require_relative './cleaner/images'
require_relative './cleaner/instances'
require_relative './cleaner/launch_configs'
require_relative './cleaner/scaling_groups'
require_relative './cleaner/snapshots'
require_relative './cleaner/volumes'
