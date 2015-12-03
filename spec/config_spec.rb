require_relative './spec_helper'

RSpec.describe Builderator::Config, '#load' do
  it 'loads a DSL file' do
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
    Builderator::Config.recompile
    expect(Builderator::Config.compiled?).to be true

    ## Ensure that layer-order is respected
    expect(Builderator::Config.aws.region).to eq 'us-east-1'
    expect(Builderator::Config.build_name).to eq 'builderator'
  end
end
