require_relative './util'

# :nodoc:
module Builderator
  VERSION = Util.source_path('VERSION').read rescue '0.0.1'
  DESCRIPTION = Util.source_path('README.md').read rescue 'README.md not found!'
end
