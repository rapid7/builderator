require 'pathname'
require 'thor'

require_relative '../patch/thor-actions'
require_relative '../util'

module Builderator
  module Tasks
    ##
    # Tasks to fetch and clean up remote artifacts
    ##
    class Vendor < Thor
      include Thor::Actions

      def self.exit_on_failure?
        true
      end

      desc 'all', 'Fetch all vendor sources'
      def all
        Config.vendor.each { |name, _| fetch(name) }
      end

      desc 'clean [NAME]', 'Clean up vendor directories'
      def clean(name = nil)
        ## Clean up all vendors
        return Config.vendor.each { |n, _| clean(n) } if name.nil?

        remove_dir Util.vendor(name)
      end

      desc 'fetch NAME', 'Fetch vendor NAME from its source'
      def fetch(name = :default)
        empty_directory Util::VENDOR

        path = Util.vendor(name)
        params = Config.vendor(name)

        if params.has?(:github)
          say_status :vendor, "#{ name } from GitHub repository #{ params.github }"
          _fetch_github(path, params)
        elsif params.has?(:git)
          say_status :vendor, "#{ name } from git repository #{ params.git }"
          _fetch_git(path, params)
        elsif params.has?(:url)
          say_status :vendor, "#{ name } from remote url #{ params.url }"
          _fetch_url(path, params)
        elsif params.has?(:path)
          say_status :vendor, "#{ name } from path #{ params.path }"
          _fetch_path(path, params)
        end

        ## Include any policies embedded in this vendor
        Config.recompile
      end

      no_commands do
        def _fetch_git(path, params)
          ## Ensure that there isn't already something there
          unless path.join('.git').exist?
            remove_dir path
            empty_directory path
          end

          inside path do
            ## Initialize new repository
            unless path.join('.git').exist?
              run 'git init'
              run "git remote add #{ params.fetch(:remote, 'origin') } #{ params.git }"
            end

            run "git fetch #{ params.fetch(:remote, 'origin') } --tags --prune"

            ## Checkout reference
            if params.has?(:tag) then run "git checkout #{ params.tag }"
            elsif params.has?(:ref) then run "git checkout #{ params.ref }"
            else ## specified branch or master
              run "git checkout #{ params.fetch(:branch, 'master') }"

              ## Only pull if a tracking branch is checked out
              run "git pull #{ params.fetch(:remote, 'origin') } #{ params.fetch(:branch, 'master') }"
            end

            ## Apply relative subdirectory
            run "git filter-branch --subdirectory-filter \"#{ params.rel }\" --force" if params.has?(:rel)

            ## Update Submodules
            if path.join('.gitmodules').exist?
              run "git submodule update --init --recursive"
            end
          end
        end

        def _fetch_github(path, params)
          params.git = "git@github.com:#{ params.github }.git"
          _fetch_git(path, params)
        end

        def _fetch_path(path, params)
          remove_dir path.to_s if path.exist?
          create_link path.to_s, params.path.to_s
        end

        def _fetch_url(path, params)
          remove_file path.to_s if path.exist?
          get params.url, path.to_s
        end
      end
    end
  end
end
