# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::InternalEvents::EventDefinitions, feature_category: :product_analytics do
  around do |example|
    described_class.instance_variable_set(:@events, nil)
    example.run
    described_class.instance_variable_set(:@events, nil)
  end

  context 'when using actual metric definitions' do
    it 'they can load' do
      expect { described_class.load_configurations }.not_to raise_error
    end
  end

  describe '.load_configurations' do
    it 'raises no errors' do
      expect { described_class.load_configurations }.not_to raise_error
    end
  end
end
