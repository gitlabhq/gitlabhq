require 'spec_helper'

describe 'instrument_classes' do
  let(:config) { double(:config) }

  let(:influx_sampler) { double(:influx_sampler) }

  before do
    allow(config).to receive(:instrument_method)
    allow(config).to receive(:instrument_methods)
    allow(config).to receive(:instrument_instance_method)
    allow(config).to receive(:instrument_instance_methods)
    allow(Gitlab::Metrics::Samplers::InfluxSampler).to receive(:initialize_instance).and_return(influx_sampler)
    allow(influx_sampler).to receive(:start)
    allow(Gitlab::Application).to receive(:configure)
  end

  it 'can autoload and instrument all files' do
    require_relative '../../config/initializers/8_metrics'
    expect { instrument_classes(config) }.not_to raise_error
  end
end
