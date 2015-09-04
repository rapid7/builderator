require 'chef/cookbook/metadata'
require 'ignorefile'

require_relative '../util'

module Builderator
  module Util
    module Cookbook
      DEFAULT_VENDOR = Util.working_dir('vendor/chef/cookbooks')

      ## Don't vendor VCS files.
      ## Reference GNU tar --exclude-vcs: https://www.gnu.org/software/tar/manual/html_section/tar_49.html
      ## Boosted from https://github.com/berkshelf/berkshelf/blob/master/lib/berkshelf/berksfile.rb
      EXCLUDED_VCS_FILES = [
        '.arch-ids', '{arch}', '.bzr', '.bzrignore', '.bzrtags',
        'CVS', '.cvsignore', '_darcs', '.git', '.hg', '.hgignore',
        '.hgrags', 'RCS', 'SCCS', '.svn', '**/.git', '.temp'].freeze

      class Metadata < Chef::Cookbook::Metadata
        def files
          return @files unless @files.nil?

          @files ||= Pathname.glob(Util::Cookbook.path.join('**/{*,.*}'))
          ignorefile.apply!(@files)

          @files
        end

        def archive
          Util.working_dir("#{ name }-#{ version }.tgz")
        end

        def chefignore
          Util::Cookbook.path.join('chefignore')
        end

        def gitignore
          Util.working_dir('.gitignore')
        end

        def ignorefile
          return @ignorefile unless @ignorefile.nil?

          ## Construct an ignorefile
          @ignorefile = IgnoreFile.new(Util::Cookbook::EXCLUDED_VCS_FILES)
          @ignorefile.load_file(chefignore)
          @ignorefile.load_file(gitignore)
        end
      end

      class << self
        def path(arg = nil)
          ## Set an explicit path to a cookbook
          return @path = Pathname.new(arg) unless arg.nil?
          return @path unless @path.nil?

          ## Check for an embedded cookbook? ('./cookbook')
          return @path = Util.working_dir('cookbook') if Util.working_dir('cookbook').exist?

          @path = Util.working_dir
        end

        def archive_path(metadata, file)
          Pathname.new(metadata.name).join(Pathname.new(file).relative_path_from(path))
        end

        def berksfile
          path.join('Berksfile')
        end

        def metadata
          Metadata.new.tap do |c|
            if path.join('metadata.rb').exist?
              c.from_file(path.join('metadata.rb').to_s)

            elsif path.join('metadata.json').exist?
              c.from_json(path.join('metadata.json').read)

            else
              fail IOError, 'Unable to read metadata.rb or metadata.json!'
            end
          end
        end
      end
    end
  end
end
