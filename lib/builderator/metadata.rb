module Builderator
  PATH = File.expand_path('../../..', __FILE__)
  VERSION = IO.read(File.join(PATH, 'VERSION')) rescue '0.0.1'
  DESCRIPTION = IO.read(File.join(PATH, 'README.md')) rescue 'README.md not found!'
end
