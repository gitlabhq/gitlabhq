# frozen_string_literal: true

RSpec.shared_examples 'CTE with MATERIALIZED keyword examples' do
  describe 'adding MATERIALIZE to the CTE' do
    let(:options) { {} }

    before do
      # Clear the cached value before the test
      Gitlab::Database::AsWithMaterialized.clear_memoization(:materialized_supported)
    end

    context 'when PG version is <12' do
      it 'does not add MATERIALIZE keyword' do
        allow(Gitlab::Database.main).to receive(:version).and_return('11.1')

        expect(query).to include(expected_query_block_without_materialized)
      end
    end

    context 'when PG version is >=12' do
      it 'adds MATERIALIZE keyword' do
        allow(Gitlab::Database.main).to receive(:version).and_return('12.1')

        expect(query).to include(expected_query_block_with_materialized)
      end

      context 'when version is higher than 12' do
        it 'adds MATERIALIZE keyword' do
          allow(Gitlab::Database.main).to receive(:version).and_return('15.1')

          expect(query).to include(expected_query_block_with_materialized)
        end
      end

      context 'when materialized is disabled' do
        let(:options) { { materialized: false } }

        it 'does not add MATERIALIZE keyword' do
          expect(query).to include(expected_query_block_without_materialized)
        end
      end
    end
  end
end
