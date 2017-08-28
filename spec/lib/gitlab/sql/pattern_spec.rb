require 'spec_helper'

describe Gitlab::SQL::Pattern do
  describe '#to_pattern' do
    subject(:to_pattern) { User.to_pattern(query) }

    context 'when a query is shorter than 3 chars' do
      let(:query) { '12' }

      it 'returns exact matching pattern' do
        expect(to_pattern).to eq('12')
      end
    end

    context 'when a query with a escape character is shorter than 3 chars' do
      let(:query) { '_2' }

      it 'returns sanitized exact matching pattern' do
        expect(to_pattern).to eq('\_2')
      end
    end

    context 'when a query is equal to 3 chars' do
      let(:query) { '123' }

      it 'returns partial matching pattern' do
        expect(to_pattern).to eq('%123%')
      end
    end

    context 'when a query with a escape character is equal to 3 chars' do
      let(:query) { '_23' }

      it 'returns partial matching pattern' do
        expect(to_pattern).to eq('%\_23%')
      end
    end

    context 'when a query is longer than 3 chars' do
      let(:query) { '1234' }

      it 'returns partial matching pattern' do
        expect(to_pattern).to eq('%1234%')
      end
    end

    context 'when a query with a escape character is longer than 3 chars' do
      let(:query) { '_234' }

      it 'returns sanitized partial matching pattern' do
        expect(to_pattern).to eq('%\_234%')
      end
    end
  end
end
