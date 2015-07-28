require_relative '../model'
require_relative '../util'

module Builderator
  module Control
    ##
    # Control logic for cleanup tasks
    ##
    module Clean
      class << self

        def options(arg = nil)
          return @options unless arg.is_a?(Hash)

          @options = arg.clone

          Util.region(@options.delete('region'))
          @commit = @options.delete('commit') { false }
          @limit = @options.delete('limit') { true }

          @options
        end

        def configs!
          resources = Model.launch_configs.unused(options)

          limit!(Model::LaunchConfigs, 'Cleanup Launch Configurations', resources, &Proc.new)
          aborted!(&Proc.new)

          resources.each do |l, _|
            yield :remove, "Launch Configuration #{ l }", :red
            Model.launch_configs.resources.delete(l)

            next unless commit?
            # Util.asg.delete_launch_configuration(:launch_configuration_name => l)
          end
        end

        def images!
          resources = Model.images.unused(options)

          limit!(Model::Images, 'Cleanup Images', resources, &Proc.new)
          aborted!(&Proc.new)

          resources.each do |i, image|
            yield :remove, "Image #{ i } (#{ image[:properties]['name'] })", :red
            Model.images.resources.delete(i)

            next unless commit?
            # Util.ec2.deregister_image(:image_id => i)
          end
        end

        def snapshots!
          resources = Model.snapshots.unused

          limit!(Model::Snapshots, 'Cleanup Snapshots', resources, &Proc.new)
          aborted!(&Proc.new)

          resources.each do |s, _|
            yield :remove, "Snapshot #{ s }", :red
            Model.snapshots.resources.delete(s)

            next unless commit?
            # Util.ec2.delete_snapshot(:snapshot_id => s)
          end
        end

        def volumes!
          resources = Model.volumes.unused

          limit!(Model::Volumes, 'Cleanup Volumes', resources, &Proc.new)
          aborted!(&Proc.new)

          resources.each do |v, _|
            yield :remove, "Volume #{ v }", :red
            Model.volumes.resources.delete(v)

            next unless commit?
            # Util.ec2.delete_volume(:volume_id => v)
          end
        end

        def commit?
          @commit && !@abort
        end

        def limit?
          @limit
        end

        def aborted?
          @commit && @abort
        end

        def exceptions
          @exceptions ||= []
        end

        private

        def aborted!
          yield :aborted, 'The following resources will NOT be removed because'\
            ' safty constraints have not been met!', :yellow if aborted?
        end

        def limit!(klass, task, resources)
          return unless limit? && (resources.size >= klass::LIMIT)

          exceptions << Util::LimitException.new(klass, task, resources)
          @abort = true

          yield(*exceptions.last.status)
        end
      end
    end
  end
end
