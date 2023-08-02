# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::PauseControl, feature_category: :global_search do
  describe '.for' do
    it 'returns the right class for `zoekt`' do
      expect(described_class.for(:zoekt)).to eq(::Gitlab::SidekiqMiddleware::PauseControl::Strategies::Zoekt)
    end

    it 'returns the right class for `none`' do
      expect(described_class.for(:none)).to eq(::Gitlab::SidekiqMiddleware::PauseControl::Strategies::None)
    end

    it 'returns nil when passing an unknown key' do
      expect(described_class.for(:unknown)).to eq(::Gitlab::SidekiqMiddleware::PauseControl::Strategies::None)
    end
  end
end
