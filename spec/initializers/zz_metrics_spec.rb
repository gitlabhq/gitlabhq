# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'instrument_classes' do
  let(:config) { double(:config) }

  before do
    allow(config).to receive(:instrument_method)
    allow(config).to receive(:instrument_methods)
    allow(config).to receive(:instrument_instance_method)
    allow(config).to receive(:instrument_instance_methods)
    allow(Gitlab::Application).to receive(:configure)
  end

  it 'can autoload and instrument all files' do
    require_relative '../../config/initializers/zz_metrics'
    expect { instrument_classes(config) }.not_to raise_error
  end
end
