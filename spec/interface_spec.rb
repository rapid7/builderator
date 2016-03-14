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
  end
end
