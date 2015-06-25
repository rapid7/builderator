# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'builderator/metadata'

Gem::Specification.new do |spec|
  spec.name          = 'builderator'
  spec.version       = Builderator::VERSION
  spec.authors       = ['John Manero']
  spec.email         = ['jmanero@rapid7.com']
  spec.summary       = 'Tools to make CI Packer builds awesome'
  spec.description   = Builderator::DESCRIPTION
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'thor-scmversion', '1.7.0'

  spec.add_dependency 'aws-sdk', '~> 2.0'
  spec.add_dependency 'thor', '~> 0.19.0'
end
