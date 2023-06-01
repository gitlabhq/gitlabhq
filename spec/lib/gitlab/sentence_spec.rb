# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Sentence, feature_category: :shared do
  delegate :to_exclusive_sentence, to: :described_class

  describe '.to_exclusive_sentence' do
    it 'calls #to_sentence on the array' do
      array = double

      expect(array).to receive(:to_sentence)

      to_exclusive_sentence(array)
    end

    it 'joins arrays with two elements correctly' do
      array = %w[foo bar]

      expect(to_exclusive_sentence(array)).to eq('foo or bar')
    end

    it 'joins arrays with more than two elements correctly' do
      array = %w[foo bar baz]

      expect(to_exclusive_sentence(array)).to eq('foo, bar, or baz')
    end

    it 'localizes the connector words' do
      array = %w[foo bar baz]

      expect(described_class).to receive(:_).with(' or ').and_return(' <1> ')
      expect(described_class).to receive(:_).with(', or ').and_return(', <2> ')
      expect(to_exclusive_sentence(array)).to eq('foo, bar, <2> baz')
    end
  end
end
