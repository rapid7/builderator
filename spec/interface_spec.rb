require_relative './spec_helper'

require 'builderator/config'
require 'builderator/interface/berkshelf'
require 'builderator/interface/packer'
require 'builderator/interface/vagrant'

RSpec.describe Builderator::Interface do
  context 'Berksfile interface' do
    berkshelf = Builderator::Interface.berkshelf

    it 'loads from Config values' do
      expect(berkshelf.vendor).to eq Builderator::Config.local.cookbook_path
    end

    it 'generates the correct Berksfile' do
      expect(berkshelf.render).to eq IO.read(::File.expand_path('../data/Berksfile', __FILE__))
    end

  end

  context 'Vagrantfile interface' do
    vagrant = Builderator::Interface.vagrant(:default)

    it 'loads from Config values' do
      expect(vagrant.build_name).to eq Builderator::Config.build_name
    end

    it 'generates the correct Vagrantfile' do
      expect(vagrant.render).to eq IO.read(::File.expand_path('../data/Vagrantfile', __FILE__))
    end

  end
end
