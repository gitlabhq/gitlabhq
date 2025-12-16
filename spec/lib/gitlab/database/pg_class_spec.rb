# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PgClass, feature_category: :database do
  describe '#cardinality_estimate' do
    context 'when no information is available' do
      subject { described_class.new(reltuples: 0.0).cardinality_estimate }

      it 'returns nil for the estimate' do
        expect(subject).to be_nil
      end
    end

    context 'with reltuples available' do
      subject { described_class.new(reltuples: 42.0).cardinality_estimate }

      it 'returns the reltuples for the estimate' do
        expect(subject).to eq(42)
      end
    end
  end

  describe '.for_table' do
    let(:relname) { :projects }

    subject(:identifier) { described_class.for_table(relname) }

    it 'returns PgClass for this table' do
      expect(identifier).to be_a(described_class)
    end

    it 'matches the relname' do
      expect(identifier.relname).to eq(relname.to_s)
    end

    context 'when using schema prefix' do
      let(:relname) { 'public.projects' }

      it 'returns PgClass for this table' do
        expect(identifier).to be_a(described_class)
      end

      it 'matches the relname' do
        expect(identifier.relname).to eq('projects')
      end
    end
  end
end
