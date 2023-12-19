# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'circuitbox', feature_category: :shared do
  it 'configures Circuitbox' do
    expect(Circuitbox.default_circuit_store).to be_a(Gitlab::CircuitBreaker::Store)
    expect(Circuitbox.default_notifier).to be_a(Gitlab::CircuitBreaker::Notifier)
  end
end
