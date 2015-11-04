require_relative '../model/cleaner'
require_relative '../util'

module Builderator
  module Control
    ##
    # Control logic for cleanup tasks
    ##
    module Cleaner
      class << self

        def options(arg = nil)
          return @options unless arg.is_a?(Hash)

          @options = arg.to_hash
          @commit = @options.delete('commit') { false }
          @limit = @options.delete('limit') { true }

          @options
        end

        def configs!
          resources = Model::Cleaner.launch_configs.unused(options)

          limit!(:launch_configs, 'Cleanup Launch Configurations', resources, &Proc.new)
          aborted!(&Proc.new)

          resources.each do |l, _|
            yield :remove, "Launch Configuration #{ l }", :red
            Model::Cleaner.launch_configs.resources.delete(l)

            next unless commit?
            Util.asg.delete_launch_configuration(:launch_configuration_name => l)
          end
        rescue Aws::AutoScaling::Errors::ServiceError => e
          exceptions << Util::AwsException.new('Cleanerup Launch Configurations', e)
          yield(*exceptions.last.status)
        end

        def images!
          resources = Model::Cleaner.images.unused(options)

          limit!(:images, 'Cleanup Images', resources, &Proc.new)
          aborted!(&Proc.new)

          resources.each do |i, image|
            yield :remove, "Image #{ i } (#{ image[:properties]['name'] })", :red
            Model::Cleaner.images.resources.delete(i)

            next unless commit?
            Util.ec2.deregister_image(:image_id => i)
          end
        rescue Aws::EC2::Errors::ServiceError => e
          exceptions << Util::AwsException.new('Cleanerup Images', e)
          yield(*exceptions.last.status)
        end

        def snapshots!
          resources = Model::Cleaner.snapshots.unused

          limit!(:snapshots, 'Cleanup Snapshots', resources, &Proc.new)
          aborted!(&Proc.new)

          resources.each do |s, _|
            yield :remove, "Snapshot #{ s }", :red
            Model::Cleaner.snapshots.resources.delete(s)

            next unless commit?
            Util.ec2.delete_snapshot(:snapshot_id => s)
          end
        rescue Aws::EC2::Errors::ServiceError => e
          exceptions << Util::AwsException.new('Cleanerup Snapshots', e)
          yield(*exceptions.last.status)
        end

        def volumes!
          resources = Model::Cleaner.volumes.unused

          limit!(:volumes, 'Cleanup Volumes', resources, &Proc.new)
          aborted!(&Proc.new)

          resources.each do |v, _|
            yield :remove, "Volume #{ v }", :red
            Model::Cleaner.volumes.resources.delete(v)

            next unless commit?
            Util.ec2.delete_volume(:volume_id => v)
          end
        rescue Aws::EC2::Errors::ServiceError => e
          exceptions << Util::AwsException.new('Cleanerup Volumes', e)
          yield(*exceptions.last.status)
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

        def limit!(resource_name, task, resources)
          return unless limit? && (resources.size >=
            Config[:cleaner][:limits].fetch(resource_name, Util::LimitException::DEFAULT_LIMIT))

          exceptions << Util::LimitException.new(resource_name, task, resources)
          @abort = true

          yield(*exceptions.last.status)
        end
      end
    end
  end
end
