module Builderator
  GEM_ROOT = File.expand_path('../../..', __FILE__)
  VERSION = IO.read(File.join(GEM_ROOT, 'VERSION')) rescue '0.0.1'
  DESCRIPTION = IO.read(File.join(GEM_ROOT, 'README.md')) rescue 'README.md not found!'
end
