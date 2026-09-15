# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Search::ScopeHandlers::Registry, feature_category: :global_search do
  let(:test_handler) { Class.new(Search::ScopeHandlers::Base) }

  around do |example|
    original_registry = described_class.instance_variable_get(:@registry)
    described_class.instance_variable_set(:@registry, nil)

    example.run

    described_class.instance_variable_set(:@registry, original_registry)
  end

  describe '.register' do
    it 'registers a handler for a scope' do
      described_class.register(:test_scope, test_handler)

      expect(described_class.for_scope(:test_scope)).to eq(test_handler)
    end

    it 'converts scope to string' do
      described_class.register(:test_scope, test_handler)

      expect(described_class.for_scope('test_scope')).to eq(test_handler)
    end
  end

  describe '.for_scope' do
    it 'returns nil for unregistered scope' do
      expect(described_class.for_scope(:nonexistent)).to be_nil
    end

    it 'returns handler for registered scope' do
      described_class.register(:test_scope, test_handler)

      expect(described_class.for_scope(:test_scope)).to eq(test_handler)
    end
  end

  describe '.registered?' do
    it 'returns false for unregistered scope' do
      expect(described_class.registered?(:nonexistent)).to be false
    end

    it 'returns true for registered scope' do
      described_class.register(:test_scope, test_handler)

      expect(described_class.registered?(:test_scope)).to be true
    end
  end

  describe '.registered_scopes' do
    it 'returns empty array when no scopes registered' do
      expect(described_class.registered_scopes).to eq([])
    end

    it 'returns list of registered scopes' do
      described_class.register(:scope1, test_handler)
      described_class.register(:scope2, test_handler)

      expect(described_class.registered_scopes).to match_array(%w[scope1 scope2])
    end
  end
end
