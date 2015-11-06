require 'thor'
require_relative '../control/ami'

module Builderator
  module Tasks
    class AMI < Thor
      namespace :ami

      class_option :root_device_type,
                   :default => 'ebs',
                   :desc => 'The type of the root device volume (ebs | instance-store)'
      class_option :virtualization_type,
                   :default => 'hvm',
                   :desc => 'The virtualization type (paravirtual | hvm)'
      class_option :architecture,
                   :default => 'x86_64',
                   :desc => 'The image architecture (i386 | x86_64)'

      desc 'ubuntu SEARCH', 'Print the latest AMI ID for an Ubuntu image matching the SEARCH string'
      def ubuntu(search = '*/hvm-ssd/ubuntu-trusty-daily-amd64-server-20*')
        puts Control::AMI.latest(:owner => Builderator::Control::AMI::Owners::UBUNTU,
                                 'root-device-type' => options['root_device_type'],
                                 'virtualization-type' => options['virtualization_type'],
                                 'architecture' => options['architecture'],
                                 'name' => search).image_id
      end

      desc 'private [KEY VALUE ...]', 'Find the latest AMI ID with tags KEY=VALUE'
      def private(*args)
        puts Control::AMI.latest({ :owner => Builderator::Control::AMI::Owners::SELF,
                                   'root-device-type' => options['root_device_type'],
                                   'virtualization-type' => options['virtualization_type'],
                                   'architecture' => options['architecture'] }.merge(Hash[*args])).image_id
      end

      desc 'windows SEARCH', 'Print the latest AMI ID for a Windows image matching the SEARCH string'
      def windows(search = 'Windows_Server-2012-R2_RTM-English-64Bit-Base*')
        puts Control::AMI.latest(:owner => Builderator::Control::AMI::Owners::AMAZON,
                                 'root-device-type' => options['root_device_type'],
                                 'virtualization-type' => options['virtualization_type'],
                                 'architecture' => options['architecture'],
                                 'name' => search).image_id
      end

    end
  end
end
