# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SyntheticNote do
  describe '#to_ability_name' do
    subject { described_class.new.to_ability_name }

    it { is_expected.to eq('note') }
  end

  describe '#suggestions' do
    subject(:suggestions) { described_class.new.suggestions }

    it 'is empty without querying, as synthetic notes are never persisted' do
      expect { suggestions.load }.not_to make_queries

      expect(suggestions).to eq([])
    end
  end
end
