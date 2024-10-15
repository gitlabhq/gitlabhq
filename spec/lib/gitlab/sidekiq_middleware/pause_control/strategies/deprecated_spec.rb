# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::PauseControl::Strategies::Deprecated, feature_category: :global_search do
  let(:strategy) { described_class.new }

  describe '#should_pause?' do
    it 'always returns false' do
      expect(strategy.should_pause?).to be false
    end
  end

  describe 'inheritance' do
    it 'inherits from Gitlab::SidekiqMiddleware::PauseControl::Strategies::Base' do
      expect(described_class.superclass).to eq(Gitlab::SidekiqMiddleware::PauseControl::Strategies::Base)
    end
  end

  describe '#override' do
    it 'overrides the should_pause? method' do
      expect(described_class.instance_method(:should_pause?).owner).to eq(described_class)
    end
  end
end
