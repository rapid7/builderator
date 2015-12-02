require_relative './spec_helper'
require 'builderator/config'

RSpec.describe Builderator::Config, '#load' do
  it 'loads a DSL file' do
    Builderator::Config.load(::File.expand_path('../resource/Buildfile', __FILE__))

    expect(Builderator::Config.layers.length).to eq 1
  end

  it 'compiles loaded DSL' do
    layer = Builderator::Config.layers.first
    layer.compile.seal

    expect(layer.build_name).to eq 'builderator'
    expect(layer.autoversion.create_tags).to be false

    ## Collection `depends` in Namespace `cookbook`
    expect(layer.cookbook.depends['apt']).to be_kind_of(Builderator::Config::Attributes::Namespace)
    expect(layer.cookbook.depends['etcd-v2']).to be_kind_of(Builderator::Config::Attributes::Namespace)
  end

  it 'compiles configuration layers' do
    expect(Builderator::Config.compiled?).to be false
    Builderator::Config.recompile

    expect(Builderator::Config.compiled?).to be true

    ## Ensure that layer-order is respected
    expect(Builderator::Config.aws.region).to eq 'us-east-1'
    expect(Builderator::Config.build_name).to eq 'builderator'
  end
end
