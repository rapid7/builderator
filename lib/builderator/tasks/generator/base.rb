require 'thor/group'

require_relative '../../patch/thor-actions'
require_relative '../../util'

module Builderator
  module Tasks
    module Generator
      ##
      # Create/update a Jetty project
      ##
      class Base < Thor::Group
        include Thor::Actions

        argument :context

        def buildfile
          case context.buildfile
          when :ignore then return
          when :rm then remove_file 'Buildfile'
          when :sync then template 'template/Buildfile.erb', 'Buildfile'
          end
        end

        def berksfile
          return unless context.berksfile == :rm
          remove_file 'Berksfile'
        end

        def gemfile
          case context.gemfile
          when :ignore then return
          when :rm then remove_file 'Gemfile'
          when :sync then template 'template/Gemfile.erb', 'Gemfile'
          end
        end

        def gitignore
          case context.gitignore
          when :ignore then return
          when :rm then remove_file '.gitignore'
          when :sync then template 'template/gitignore.erb', '.gitignore'
          end
        end

        def packerfile
          case context.packerfile
          when :ignore then return
          when :rm
            remove_file 'packer.json'
            remove_dir 'packer'
          end
        end

        def vagrantfile
          case context.vagrantfile
          when :ignore then return
          when :rm then remove_file 'Vagrantfile'
          end
        end

        def thorfile
          case context.thorfile
          when :ignore then return
          when :rm then remove_file 'Thorfile'
          end
        end
      end
    end
  end
end
