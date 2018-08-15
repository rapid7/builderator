require_relative './spec_helper'

require 'builderator/config'
require 'builderator/interface/berkshelf'
require 'builderator/interface/packer'
require 'builderator/interface/vagrant'

# :nodoc:
module Builderator
  RSpec.describe Interface do
    context 'Berksfile' do
      berkshelf = Interface.berkshelf

      it 'loads from Config values' do
        expect(berkshelf.vendor).to eq Config.local.cookbook_path
      end

      it 'generates the correct Berksfile' do
        skip
        expect(berkshelf.render).to eq IO.read(::File.expand_path('../data/Berksfile', __FILE__))
      end
    end

    context 'Vagrantfile' do
    #  vagrant = Interface.vagrant(:default)

      it 'loads from Config values' do
        skip
        expect(vagrant.build_name).to eq Config.build_name
      end

      it 'generates the correct Vagrantfile' do
        skip
        pending "test doesn't work with absolute paths"
        expect(vagrant.render).to eq IO.read(::File.expand_path('../data/Vagrantfile', __FILE__))
      end
    end

    context 'Packer post-processors' do
      before(:example) do
        Config.reset!
        Config.load(::File.expand_path('../resource/Buildfile-with-post-processors', __FILE__))
        Config.compile
      end

      it 'generates a single post-processor' do
        Config.profile.use('single')
        packer = Interface::Packer.new
        expect(packer.packerfile['post-processors']).to eq ['docker-push']
      end

      it 'generates a complex post-processor' do
        Config.profile.use('complex')
        packer = Interface::Packer.new
        expect(packer.packerfile['post-processors']).to eq [{
          :type => 'docker-tag',
          :repository => 'rapid7/builderator',
          :tag => 'latest'
        }]
      end

      it 'generates a sequence of post-processors' do
        Config.profile.use('sequence')
        packer = Interface::Packer.new
        expect(packer.packerfile['post-processors']).to eq [
          [
            {
              :type => 'docker-tag',
              :repository => 'rapid7/builderator',
              :tag => 'latest'
            },
            'docker-push'
          ]
        ]
      end

      it 'generates multiple sequences of post-processors' do
        Config.profile.use('multiple_sequences')
        packer = Interface::Packer.new
        expect(packer.packerfile['post-processors']).to eq [
          [
            {
              :type => 'docker-tag',
              :repository => 'rapid7/builderator',
              :tag => '1.2.2'
            },
            'docker-push'
          ],
          [
            {
              :type => 'docker-tag',
              :repository => 'rapid7/builderator',
              :tag => 'latest'
            },
            'docker-push'
          ]
        ]
      end
    end

    context 'Packer block-device-mappings' do
      before(:example) do
        Config.reset!
        Config.load(::File.expand_path('../resource/Buildfile-with-block-device-mappings', __FILE__))
        Config.compile
      end

      it 'generates an AMI block device mapping' do
        Config.profile.use('ami_mappings')
        packer = Interface::Packer.new
        mappings = packer.packerfile[:builders].first[:ami_block_device_mappings]
        expect(mappings).to eq [{
          'device_name' => '/dev/sda',
          'no_device' => true,
        }]
      end

      it 'generates a Packer launch block device mapping' do
        Config.profile.use('launch_mappings')
        packer = Interface::Packer.new
        mappings = packer.packerfile[:builders].first[:launch_block_device_mappings]
        expect(mappings).to eq [{
          'device_name' => '/dev/sda',
          'no_device' => true,
        }]
      end
    end
  end
end
