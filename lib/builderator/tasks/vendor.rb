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

        remove_dir ::File.join(Config.local.vendor_path, name.to_s)
      end

      desc 'fatch NAME', 'Fetch vendor NAME from its source'
      def fetch(name = :default)
        empty_directory Config.local.vendor_path

        path = Pathname.new(Config.local.vendor_path).join(name.to_s)
        params = Config.vendor(name)

        if params.has?(:github)
          say_status :vendor, "#{ name } from GitHub repository #{ params[:github] }"
          _fetch_github(path, params)
        elsif params.has?(:git)
          say_status :vendor, "#{ name } from git repository #{ params[:git] }"
          _fetch_git(path, params)
        elsif params.has?(:path)
          say_status :vendor, "#{ name } from path #{ params[:path] }"
          _fetch_path(path, params)
        end
      end

      no_commands do
        def _fetch_git(path, params)
          empty_directory path

          inside path do
            ## Initialize new repository
            unless path.join('.git').exist?
              run 'git init'
              run "git remote add origin #{ params[:git] }"
            end

            run 'git fetch origin --tags --prune'

            ## Checkout reference
            if params.has?(:tag) then run "git checkout #{ params[:tag] }"
            elsif params.has?(:ref) then run "git checkout #{ params[:ref] }"
            else ## specified branch or master
              run "git checkout #{ params.fetch(:branch, 'master') }"

              ## Only pull if a tracking branch is checked out
              run 'git pull'
            end

            ## Apply relative subdirectory
            run "git filter-branch --subdirectory-filter \"#{ params[:rel] }\" --force" if params.has?(:rel)
          end
        end

        def _fetch_github(path, params)
          params[:git] = "git@github.com:#{ params[:github] }.git"
          _fetch_git(path, params)
        end

        def _fetch_path(path, params)
          return if path.exist?
          create_link path.to_s, Util.relative_path(params[:path])
        end
      end
    end
  end
end
