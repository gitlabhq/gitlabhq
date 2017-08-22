require 'spec_helper'

describe Gitlab::SQL::Pattern do
  describe '#to_sql' do
    subject(:to_sql) { described_class.new(query).to_sql }

    context 'when a query is shorter than 3 chars' do
      let(:query) { '12' }

      it 'returns exact matching pattern' do
        expect(to_sql).to eq('12')
      end
    end

    context 'when a query is equal to 3 chars' do
      let(:query) { '123' }

      it 'returns partial matching pattern' do
        expect(to_sql).to eq('%123%')
      end
    end

    context 'when a query is longer than 3 chars' do
      let(:query) { '1234' }

      it 'returns partial matching pattern' do
        expect(to_sql).to eq('%1234%')
      end
    end
  end
end
