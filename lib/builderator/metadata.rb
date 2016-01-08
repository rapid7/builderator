require_relative './util'

# :nodoc:
module Builderator
  VERSION = Util.source_path('VERSION').read rescue '0.0.1'
  DESCRIPTION = 'Builderator automates many of the common steps required to build VMs '\
                'and images with Chef. It provides a common configuration layer for '\
                'Chef, Berkshelf, Vagrant, and Packer, and tasks to orchestrate the '\
                'usage of each. https://github.com/rapid7/builderator'
end
