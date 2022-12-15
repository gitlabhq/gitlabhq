# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::APIAuthentication::SentThroughBuilder do
  describe '#sent_through' do
    let(:resolvers) { Array.new(3) { double } }
    let(:locators) { Array.new(3) { double } }

    it 'adds a strategy for each of locators x resolvers' do
      strategies = locators.index_with { [] }
      described_class.new(strategies, resolvers).sent_through(*locators)

      expect(strategies).to eq(locators.index_with { resolvers })
    end
  end
end
