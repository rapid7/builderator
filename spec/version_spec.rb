require_relative './spec_helper'

require 'json'
require 'builderator/control/version'

# rubocop:disable Metrics/ClassLength

module Builderator
  module Control
    # :nodoc:
    class Version
      ## Test stub to load from an included JSON document
      module Test
        extend SCM

        def self.supported?
          true
        end

        def self._history
          JSON.parse(
            IO.read(::File.expand_path('../data/history.json', __FILE__)),
            :symbolize_names => true)
        end
      end

      ## Test stub with no history
      module NoHistory
        extend SCM

        def self.supported?
          true
        end

        def self._history
          []
        end
      end

      ## Disable the Git provider
      module Git
        extend SCM

        def self.supported?
          false
        end
      end

      RSpec.describe Builderator::Control::Version do
        before(:context) do
          SCM.unregister(Test)
          SCM.register(NoHistory)
        end

        after(:context) do
          SCM.unregister(NoHistory)
          SCM.register(Test)
        end

        context 'current' do
          around(:example) do |example|
            if example.metadata[:version_file]
              Util.relative_path('VERSION').write('1.2.3')
            end
            example.run
            if example.metadata[:version_file]
              Util.relative_path('VERSION').delete
            end
          end

          it 'falls back to VERSION file if no tags are found', :version_file => true do
            expect(Version.current).to be == Version.from_string('1.2.3')
          end
        end
      end

      SCM.register(Test)

      RSpec.describe Builderator::Control::Version do
        context 'loading, parsing, and ordering of commits and tags' do
          it 'loads history from a provider' do
            expect(SCM.history).to be_a Array
            expect(SCM.history).to_not be_empty
            expect(SCM.history).to all be_a SCM::Commit
          end

          context 'parses semver strings correctly' do
            it 'parses a.b.c versions correctly' do
              version = Version.from_string('1.2.3')

              expect(version.major).to be == 1
              expect(version.minor).to be == 2
              expect(version.patch).to be == 3

              expect(version.is_prerelease).to be false
              expect(version.prerelease_name).to be_nil
              expect(version.prerelease_iteration).to be_nil
              expect(version.build).to be_nil
            end

            it 'parses pre-release versions correctly' do
              version = Version.from_string('1.2.3-pre.42')

              expect(version.major).to be == 1
              expect(version.minor).to be == 2
              expect(version.patch).to be == 3
              expect(version.is_prerelease).to be true
              expect(version.prerelease_name).to be == 'pre'
              expect(version.prerelease_iteration).to be == 42
              expect(version.build).to be_nil
            end

            it 'parses build versions correctly' do
              version = Version.from_string('1.2.3+build.9')

              expect(version.major).to be == 1
              expect(version.minor).to be == 2
              expect(version.patch).to be == 3
              expect(version.is_prerelease).to be false
              expect(version.prerelease_name).to be_nil
              expect(version.prerelease_iteration).to be_nil
              expect(version.build).to be == 9
            end

            it 'parses the complete spec' do
              version = Version.from_string('1.2.3-yolo.42+build.9')

              expect(version.major).to be == 1
              expect(version.minor).to be == 2
              expect(version.patch).to be == 3
              expect(version.is_prerelease).to be true
              expect(version.prerelease_name).to be == 'yolo'
              expect(version.prerelease_iteration).to be == 42
              expect(version.build).to be == 9
            end

            it 'does not fail on invalid specs' do
              expect(Version.from_string('1.2.lizard-alpha.42+build.9')).to be_nil
              expect(Version.from_string('1.2.3-alpha.42+taco.9')).to be_nil
              expect(Version.from_string('1.2.3-alpha.guacamole+build.9')).to be_nil
              expect(Version.from_string('1.2.3-alpha.42+build.beef')).to be_nil
              expect(Version.from_string('1.2.dog')).to be_nil
              expect(Version.from_string('1.cat.3')).to be_nil
              expect(Version.from_string('cow.2.3')).to be_nil
            end
          end

          it 'generates Version objects from commits' do
            expect(SCM.tags).to be_a Array
            expect(SCM.tags).to_not be_empty
            expect(SCM.tags).to all be_a Version
          end

          it 'finds the current version of the module' do
            expect(SCM.tags).to all be <= Version.current
          end
        end

        context 'bumping versions' do
          it 'attaches the correct SCM ref to new versions' do
            previous = Version.current

            Version.bump(:major)
            expect(Version.current.ref).to eq SCM.history.first.id
            expect(Version.current).to_not equal(previous)
          end

          it 'fails when an invalid step is passed to #bump' do
            expect { Version.bump(:lizard) }.to raise_error RuntimeError
          end

          context 'bump build' do
            it 'adds, increments, and resets build numbers' do
              expect(Version.current.build).to be_nil
              previous = Version.current

              Version.bump(:build)
              expect(Version.current).to_not equal(previous)
              expect(Version.current.build).to be == 0

              Version.bump(:build)
              expect(Version.current.build).to be == 1

              Version.bump(:patch)
              expect(Version.current.build).to be_nil
            end
          end

          context 'bump prerelease and release' do
            it 'creates and increments pre-releases from previous releases' do
              expect(Version.current.is_prerelease).to be false
              previous = Version.current

              Version.bump(:prerelease)
              expect(Version.current.patch).to be == (previous.patch + 1)
              expect(Version.current.is_prerelease).to be true
              expect(Version.current.prerelease_name).to be == 'alpha'
              expect(Version.current.prerelease_iteration).to be == 0

              Version.bump(:prerelease)
              expect(Version.current.prerelease_name).to be == 'alpha'
              expect(Version.current.prerelease_iteration).to be == 1
            end

            it 'creates and increments pre-releases with a specified name' do
              expect(Version.current.is_prerelease).to be true

              Version.bump(:prerelease, 'beta')
              expect(Version.current.prerelease_name).to be == 'beta'
              expect(Version.current.prerelease_iteration).to be == 0

              Version.bump(:prerelease)
              expect(Version.current.prerelease_name).to be == 'beta'
              expect(Version.current.prerelease_iteration).to be == 1

              Version.bump(:prerelease, 'beta')
              expect(Version.current.prerelease_name).to be == 'beta'
              expect(Version.current.prerelease_iteration).to be == 2
            end

            it 'removes pre-release parameters for a release' do
              expect(Version.current.is_prerelease).to be true
              previous = Version.current

              Version.bump(:release)
              expect(Version.current.patch).to be == previous.patch
              expect(Version.current.is_prerelease).to be false
              expect(Version.current.prerelease_name).to be_nil
              expect(Version.current.prerelease_iteration).to be_nil
            end
          end

          context 'bump major, minor, and patch-prerelease' do
            it 'creates a new patch version for a patch-prerelease' do
              Version.bump(:prerelease)
              previous = Version.current
              expect(Version.current.is_prerelease).to be true

              Version.bump('patch-prerelease')
              expect(Version.current.is_prerelease).to be true
              expect(Version.current.patch).to be == (previous.patch + 1)
            end

            it 'creates a new minor version for a minor-prerelease' do
              previous = Version.current
              expect(Version.current.is_prerelease).to be true

              Version.bump('minor-prerelease')
              expect(Version.current.is_prerelease).to be true
              expect(Version.current.patch).to be == 0
              expect(Version.current.minor).to be == (previous.minor + 1)
            end

            it 'creates a new major version for a major-prerelease' do
              previous = Version.current
              expect(Version.current.is_prerelease).to be true

              Version.bump('major-prerelease')
              expect(Version.current.is_prerelease).to be true
              expect(Version.current.patch).to be == 0
              expect(Version.current.minor).to be == 0
              expect(Version.current.major).to be == (previous.major + 1)
            end
          end

          context 'bump major, minor, and patch' do
            it 'creates a new patch version and resets build and prerelease parameters' do
              Version.bump(:prerelease)
              Version.bump(:build)
              previous = Version.current

              expect(Version.current.is_prerelease).to be true
              expect(Version.current.build).to_not be_nil

              Version.bump(:patch)

              expect(Version.current.is_prerelease).to be false
              expect(Version.current.build).to be_nil
              expect(Version.current.patch).to be == (previous.patch + 1)
            end

            it 'creates a new minor version and resets lower-precedence parameters' do
              Version.bump(:prerelease)
              Version.bump(:build)
              previous = Version.current

              expect(Version.current.is_prerelease).to be true
              expect(Version.current.build).to_not be_nil
              expect(Version.current.patch).to_not be == 0

              Version.bump(:minor)

              expect(Version.current.is_prerelease).to be false
              expect(Version.current.build).to be_nil
              expect(Version.current.patch).to be == 0
              expect(Version.current.minor).to be == (previous.minor + 1)
            end

            it 'creates a new major version and resets lower-precedence parameters' do
              Version.bump(:prerelease)
              Version.bump(:build)
              previous = Version.current

              expect(Version.current.is_prerelease).to be true
              expect(Version.current.build).to_not be_nil
              expect(Version.current.patch).to_not be == 0
              expect(Version.current.minor).to_not be == 0

              Version.bump(:major)

              expect(Version.current.is_prerelease).to be false
              expect(Version.current.build).to be_nil
              expect(Version.current.patch).to be == 0
              expect(Version.current.minor).to be == 0
              expect(Version.current.major).to be == (previous.major + 1)
            end
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
