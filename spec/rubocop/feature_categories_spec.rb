# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../rubocop/feature_categories'

RSpec.describe RuboCop::FeatureCategories, feature_category: :tooling do
  subject(:feature_categories) { described_class.new(categories) }

  let(:categories) { ['valid_category'] }

  describe '.available' do
    it 'returns a list of available feature categories in a set of strings' do
      expect(described_class.available).to be_a(Set)
      expect(described_class.available).to all(be_a(String))
    end
  end

  describe '.available_with_custom' do
    it 'returns a list of available feature categories' do
      expect(described_class.available_with_custom).to include(described_class.available)
    end

    it 'returns a list containing the custom feature categories' do
      expect(described_class.available_with_custom).to include(described_class::CUSTOM_CATEGORIES)
    end
  end

  describe '.config_checksum' do
    it 'returns a SHA256 digest used by RuboCop to invalid cache' do
      expect(described_class.config_checksum).to match(/^\h{64}$/)
    end
  end

  describe '#check' do
    let(:value_node) { instance_double(RuboCop::AST::SymbolNode, sym_type?: true) }
    let(:document_link) { 'https://example.com' }

    def check
      expect do |block|
        feature_categories.check(
          value_node: value_node,
          document_link: document_link,
          &block)
      end
    end

    context 'when value_node is nil' do
      let(:value_node) { nil }

      it 'yields a message asking for a feature category with document link only' do
        check.to yield_with_args(<<~MARKDOWN.chomp)
          Please use a valid feature category. See https://example.com
        MARKDOWN
      end
    end

    context 'when value_node is not a symbol node' do
      before do
        allow(value_node).to receive(:sym_type?).and_return(false)
      end

      it 'yields a message asking for a symbol value' do
        check.to yield_with_args(described_class::MSG_SYMBOL)
      end
    end

    context 'when category is found' do
      before do
        allow(value_node).to receive(:value).and_return(categories.first)
      end

      it 'returns nil without yielding anything' do
        check.not_to yield_with_args
      end
    end

    context 'when a similar category is found' do
      before do
        allow(value_node).to receive(:value).and_return('invalid_category')
      end

      it 'yields a message asking for a feature category with suggestion and document link' do
        check.to yield_with_args(<<~MARKDOWN.chomp)
          Please use a valid feature category. Did you mean `:valid_category`? See https://example.com
        MARKDOWN
      end
    end

    context 'when no similar category is found' do
      before do
        allow(value_node).to receive(:value).and_return('something_completely_different')
      end

      it 'yields a message asking for a feature category with document link only' do
        check.to yield_with_args(<<~MARKDOWN.chomp)
          Please use a valid feature category. See https://example.com
        MARKDOWN
      end
    end
  end
end
