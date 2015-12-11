require 'thor'

require_relative './generator/base'
require_relative './generator/jetty'

module Builderator
  module Tasks
    module Generator
      ##
      # CLI Subcommand for generator groups
      ##
      class Types < Thor
        register Tasks::Generator::Base, 'base', 'base', 'Base components for most projects'
        register Tasks::Generator::Jetty, 'jetty', 'jetty', 'Create or update a Jetty project'
      end
    end
  end
end
