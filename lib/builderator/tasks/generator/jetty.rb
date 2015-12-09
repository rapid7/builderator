require 'thor/group'

require_relative '../../patch/thor-actions'

module Builderator
  module Tasks
    module Generator
      ##
      # Create/update a Jetty project
      ##
      class Jetty < Thor::Group
        include Thor::Actions

        def base
          invoke Generator::Types, :base, [Config.generator.project(:jetty)], options
        end

        def cookbook
          case Config.generator.project(:jetty).cookbook
          when :ignore then return
          when :rm then remove_dir 'cookbook'
          end
        end
      end
    end
  end
end
