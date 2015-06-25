require 'thor'
require 'builderator/ami'

module Builderator
  class Tasks < Thor
    namespace :build

    desc 'ami SUBCOMMAND', 'Search for AMI IDs'
    subcommand 'ami', Builderator::AMI
  end
end
