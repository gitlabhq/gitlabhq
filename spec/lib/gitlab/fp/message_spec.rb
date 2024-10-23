# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Fp::Message, feature_category: :shared do
  describe '#==' do
    it 'implements equality' do
      expect(described_class.new({ a: 1 })).to eq(described_class.new(a: 1)) # rubocop:disable RSpec/IdenticalEqualityAssertion -- We are testing equality
      expect(described_class.new({ a: 1 })).not_to eq(described_class.new(a: 2))
    end
  end

  describe 'validation' do
    it 'requires content to be a Hash' do
      # noinspection RubyMismatchedArgumentType - Intentionally passing wrong type to check runtime type validation
      expect { described_class.new(1) }.to raise_error(ArgumentError, "content must be a Hash")
    end
  end
end
