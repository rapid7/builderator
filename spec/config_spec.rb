require_relative './spec_helper'

# :nodoc:
module Builderator
  RSpec.describe Config, '#load' do
    before(:example) do
      Config.reset!
      Config.load(::File.expand_path('../resource/Buildfile', __FILE__))
    end

    it 'loads a DSL file' do
      expect(Config.layers.length).to eq 1
    end

    it 'compiles loaded DSL' do
      layer = Config.layers.first
      layer.compile.seal

      expect(layer.build_name).to eq 'builderator'
      expect(layer.autoversion.create_tags).to be false

      ## Collection `depends` in Namespace `cookbook`
      expect(layer.cookbook.depends['apt']).to be_kind_of(Config::Attributes::Namespace)
      expect(layer.cookbook.depends['etcd-v2']).to be_kind_of(Config::Attributes::Namespace)
    end

    it 'compiles configuration layers' do
      skip
      Config.compile

      ## Ensure that layer-order is respected
      expect(Config.aws.region).to eq 'us-east-1'
      expect(Config.build_name).to eq 'builderator'
    end
  end

  RSpec.describe Config, '#compile' do
    before(:example) do
      Config.reset!
    end

    10.times do |itr|
      it "#{itr}: compiles vendored policy" do
        Builderator::Config.load(::File.expand_path('../resource/Buildfile-vendored-policy1', __FILE__))
        expect { Config.compile }.not_to raise_error
      end
    end

    10.times do |itr|
      it "#{itr}: compiles local vendored polices" do
        Builderator::Config.load(::File.expand_path('../resource/Buildfile-local-overrides', __FILE__))
        Builderator::Config.load(::File.expand_path('../resource/Buildfile-local-vendored-policy1', __FILE__))
        expect { Config.compile }.not_to raise_error
      end
    end

    10.times do |itr|
      it "#{itr}: compiles product polices" do
        Builderator::Config.load(::File.expand_path('../resource/Buildfile-local-overrides', __FILE__))
        Builderator::Config.load(::File.expand_path('../resource/Buildfile-overrides-in-product', __FILE__))
        expect { Config.compile }.not_to raise_error
      end
    end
  end
end
