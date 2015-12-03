source 'https://rubygems.org'

# Specify your gem's dependencies in builderator.gemspec
gemspec

gem 'vagrant', :github => 'mitchellh/vagrant',
               :tag => 'v1.7.4',
               :group => :development

group :development, :plugins do
  gem 'vagrant-aws'
  gem 'vagrant-omnibus'
end
