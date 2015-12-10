require 'thor/group'

require_relative './base'
require_relative '../../patch/thor-actions'

module Builderator
  module Tasks
    module Generator
      ##
      # Create/update a Jetty project
      ##
      class Jetty < Generator::Base
        def cookbook
          case context.cookbook.to_sym
          when :ignore then return
          when :rm then remove_dir 'cookbook'
          end
        end

        no_commands do
          def context
            Config.generator.project(:jetty)
          end
        end
      end
    end
  end
end
