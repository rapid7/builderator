require_relative '../model/cleaner'
require_relative '../util'

module Builderator
  module Control
    ##
    # Control logic for cleanup tasks
    ##
    module Cleaner
      class << self
        def configs!
          resources = Model::Cleaner.launch_configs.unused

          yield :launch_configs, "Found #{resources.length} Launch Configurations to remove"
          verify!(:launch_configs, 'Cleanup Launch Configurations', resources, &Proc.new)
          aborted!(&Proc.new)

          resources.keys.sort.each do |id|
            yield :remove, "Launch Configuration #{id}", :red
            Model::Cleaner.launch_configs.resources.delete(id)

            next unless commit?
            Util.asg.delete_launch_configuration(:launch_configuration_name => id)
          end
        rescue Aws::AutoScaling::Errors::ServiceError => e
          exceptions << Util::AwsException.new('Cleanerup Launch Configurations', e)
          yield(*exceptions.last.status)
        end

        def images!
          resources = Model::Cleaner.images.unused

          yield :images, "Found #{resources.length} Images to remove"
          yield :grouping, "Groupd images by #{Config.cleaner.group_by}" if Config.cleaner.group_by
          yield :keep, "Keeping #{Config.cleaner.keep} images in each group"
          verify!(:images, 'Cleanup Images', resources, &Proc.new)
          aborted!(&Proc.new)

          resources.values
            .sort { |a, b| a[:properties]['name'] <=> b[:properties]['name'] }
            .each do |image|
              yield :remove, "Image #{image[:id]} (#{image[:properties]['name']})", :red
              Model::Cleaner.images.resources.delete(image[:id])

              next unless commit?
              Util.ec2.deregister_image(:image_id => image[:id])
            end

        rescue Aws::EC2::Errors::ServiceError => e
          exceptions << Util::AwsException.new('Cleanerup Images', e)
          yield(*exceptions.last.status)
        end

        def snapshots!
          resources = Model::Cleaner.snapshots.unused

          yield :snapshots, "Found #{resources.length} Snapshots to remove"
          verify!(:snapshots, 'Cleanup Snapshots', resources, &Proc.new)
          aborted!(&Proc.new)

          resources.keys.sort.each do |id|
            yield :remove, "Snapshot #{id}", :red
            Model::Cleaner.snapshots.resources.delete(id)

            next unless commit?
            Util.ec2.delete_snapshot(:snapshot_id => id)
          end
        rescue Aws::EC2::Errors::ServiceError => e
          exceptions << Util::AwsException.new('Cleanerup Snapshots', e)
          yield(*exceptions.last.status)
        end

        def volumes!
          resources = Model::Cleaner.volumes.unused

          yield :volumes, "Found #{resources.length} Volumes to remove"
          verify!(:volumes, 'Cleanup Volumes', resources, &Proc.new)
          aborted!(&Proc.new)

          resources.keys.sort.each do |id|
            yield :remove, "Volume #{id}", :red
            Model::Cleaner.volumes.resources.delete(id)

            next unless commit?
            Util.ec2.delete_volume(:volume_id => id)
          end
        rescue Aws::EC2::Errors::ServiceError => e
          exceptions << Util::AwsException.new('Cleanerup Volumes', e)
          yield(*exceptions.last.status)
        end

        def commit?
          @commit && !@abort
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

        def verify!(resource_name, task, resources)
          if Config.cleaner.commit
            yield :commit, 'This is not a dry-run. Press CTL-C to stop! '\
                           '(continuing in 5 seconds)', :red

            sleep(5) ## Give $USER a few seconds to stop
          end

          return unless resources.size >= Config.cleaner.limits[resource_name]

          ex = Util::LimitException.new(resource_name, task, resources)
          yield(*ex.status)

          if Config.cleaner.force
            yield :force, 'Limits will be ignored. Press CTL-C to stop! '\
                          '(continuing in 5 seconds)', :red
            sleep(5) ## Give $USER a few seconds to stop

            return
          end

          exceptions << ex
          @abort = true
        end
      end
    end
  end
end
