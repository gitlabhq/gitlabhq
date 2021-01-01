# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::APIAuthentication::SentThroughBuilder do
  describe '#sent_through' do
    let(:resolvers) { Array.new(3) { double } }
    let(:locators) { Array.new(3) { double } }

    it 'adds a strategy for each of locators x resolvers' do
      strategies = locators.to_h { |l| [l, []] }
      described_class.new(strategies, resolvers).sent_through(*locators)

      expect(strategies).to eq(locators.to_h { |l| [l, resolvers] })
    end
  end
end
