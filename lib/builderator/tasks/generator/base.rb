require 'thor/group'

require_relative '../../patch/thor-actions'
require_relative '../../util'

module Builderator
  module Tasks
    module Generator
      ##
      # Common steps for most projects
      ##
      class Base < Thor::Group
        include Thor::Actions

        def buildfile
          case context.buildfile.to_sym
          when :ignore then return
          when :rm then remove_file 'Buildfile'
          when :create
            template 'template/Buildfile.erb', 'Buildfile', :skip => true
          when :sync then template 'template/Buildfile.erb', 'Buildfile'
          end
        end

        def berksfile
          return unless context.berksfile.to_sym == :rm
          remove_file 'Berksfile'
        end

        def gemfile
          case context.gemfile.to_sym
          when :ignore then return
          when :rm then remove_file 'Gemfile'
          when :create
            template 'template/Gemfile.erb', 'Gemfile', :skip => true
          when :sync then template 'template/Gemfile.erb', 'Gemfile'
          end
        end

        def gitignore
          case context.gitignore.to_sym
          when :ignore then return
          when :rm then remove_file '.gitignore'
          when :create
            template 'template/gitignore.erb', '.gitignore', :skip => true
          when :sync then template 'template/gitignore.erb', '.gitignore'
          end
        end

        def packerfile
          case context.packerfile.to_sym
          when :ignore then return
          when :rm
            remove_file 'packer.json'
            remove_dir 'packer'
          end
        end

        def readme
          case context.readme.to_sym
          when :ignore then return
          when :rm then remove_file 'README.md'
          when :create
            template 'template/README.md.erb', 'README.md', :skip => true
          when :sync then template 'template/README.md.erb', 'README.md'
          end
        end

        def rubocop
          return if context.rubocop.nil?
          case context.rubocop.to_sym
          when :ignore then return
          when :rm
            remove_file '.rubocop.yml'
            remove_file '.rubocop_todo.yml'
          when :create
            template 'template/rubocop.erb', '.rubocop.yml', :skip => true
          when :sync then template 'template/rubocop.erb', '.rubocop.yml'
          end
        end

        def vagrantfile
          case context.vagrantfile.to_sym
          when :ignore then return
          when :rm then remove_file 'Vagrantfile'
          end
        end

        def thorfile
          case context.thorfile.to_sym
          when :ignore then return
          when :rm then remove_file 'Thorfile'
          end
        end
      end
    end
  end
end
