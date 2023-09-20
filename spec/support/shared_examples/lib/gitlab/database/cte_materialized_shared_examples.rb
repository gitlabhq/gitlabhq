# frozen_string_literal: true

RSpec.shared_examples 'CTE with MATERIALIZED keyword examples' do
  describe 'adding MATERIALIZE to the CTE' do
    let(:options) { {} }

    it 'adds MATERIALIZE keyword' do
      allow(ApplicationRecord.database).to receive(:version).and_return('12.1')

      expect(query).to include(expected_query_block_with_materialized)
    end

    context 'when materialized is disabled' do
      let(:options) { { materialized: false } }

      it 'does not add MATERIALIZE keyword' do
        expect(query).to include(expected_query_block_without_materialized)
      end
    end
  end
end
