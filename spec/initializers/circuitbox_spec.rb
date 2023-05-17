# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'circuitbox', feature_category: :shared do
  it 'does not configure Circuitbox', unless: Gitlab.ee? do
    expect(Circuitbox.default_circuit_store).to be_a(Circuitbox::MemoryStore)
    expect(Circuitbox.default_notifier).to be_a(Circuitbox::Notifier::ActiveSupport)
  end

  it 'configures Circuitbox', if: Gitlab.ee? do
    expect(Circuitbox.default_circuit_store).to be_a(Gitlab::CircuitBreaker::Store)
    expect(Circuitbox.default_notifier).to be_a(Gitlab::CircuitBreaker::Notifier)
  end
end
