# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Memory::Watchdog::Handlers::NullHandler, feature_category: :application_performance do
  subject(:handler) { described_class.instance }

  describe '#call' do
    it 'does nothing' do
      expect(handler.call).to be(false)
    end
  end
end
