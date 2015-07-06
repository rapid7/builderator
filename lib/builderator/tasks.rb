require 'thor'
require_relative './tasks/ami'
require_relative './tasks/packer'

module Builderator
  module Tasks
    class CLI < Thor
      desc 'ami SUBCOMMAND', 'Search for AMI IDs'
      subcommand 'ami', Builderator::Tasks::AMI

      desc 'packer SUBCOMMAND', 'Run packer builds'
      subcommand 'packer', Builderator::Tasks::Packer

      desc 'version', 'Print gem version'
      def version
        puts Builderator::VERSION
      end
    end
  end
end
