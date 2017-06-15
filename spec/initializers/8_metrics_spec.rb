require 'spec_helper'
require_relative '../../config/initializers/8_metrics'

describe 'instrument_classes', lib: true do
  let(:config) { double(:config) }

  before do
    allow(config).to receive(:instrument_method)
    allow(config).to receive(:instrument_methods)
    allow(config).to receive(:instrument_instance_method)
    allow(config).to receive(:instrument_instance_methods)
  end

  it 'can autoload and instrument all files' do
    expect { instrument_classes(config) }.not_to raise_error
  end
end
