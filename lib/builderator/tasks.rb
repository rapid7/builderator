require 'thor'
require_relative './tasks/ami'
require_relative './tasks/berks'
require_relative './tasks/clean'
require_relative './tasks/cookbook'
require_relative './tasks/packer'
require_relative './tasks/vagrant'

module Builderator
  module Tasks
    class CLI < Thor
      desc 'ami SUBCOMMAND', 'Search for AMI IDs'
      subcommand 'ami', Builderator::Tasks::AMI

      desc 'berks SUBCOMMAND', 'Berkshelf helpers'
      subcommand 'berks', Builderator::Tasks::Berks

      desc 'clean SUBCOMMAND', 'Clean up things'
      subcommand 'clean', Builderator::Tasks::Clean

      desc 'cookbook SUBCOMMAND', 'Cookbook tasks'
      subcommand 'cookbook', Builderator::Tasks::Cookbook


      desc 'packer SUBCOMMAND', 'Run Packer tasks'
      subcommand 'packer', Builderator::Tasks::Packer

      desc 'vagrant SUBCOMMAND', 'Run Vagrant tasks'
      subcommand 'vagrant', Builderator::Tasks::Vagrant

      desc 'version', 'Print gem version'
      def version
        puts Builderator::VERSION
      end
    end
  end
end
