# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::PreparedAsyncDmlOperationsTesting::AsyncOperationsRunner, feature_category: :database do
  describe '.install!' do
    it 'prepends AsyncIndexMixin to MigrationHelpers' do
      expect(Gitlab::Database::AsyncIndexes::MigrationHelpers).to(
        receive(:prepend).with(Gitlab::Database::Migrations::PreparedAsyncDmlOperationsTesting::AsyncIndexMixin)
      )

      described_class.install!
    end
  end

  describe '.execute!' do
    context 'when async indexes are tagged to be executed' do
      let(:async_index_1) { create(:postgres_async_index, name: 'test_index_1') }
      let(:async_index_2) { create(:postgres_async_index, name: 'test_index_2') }

      let(:index_creator_1) do
        instance_double(Gitlab::Database::Migrations::PreparedAsyncDmlOperationsTesting::IndexCreator)
      end

      let(:index_creator2) do
        instance_double(Gitlab::Database::Migrations::PreparedAsyncDmlOperationsTesting::IndexCreator)
      end

      before do
        async_index_1.update!(definition: "#{async_index_1.definition} /* SYNC_TESTING_EXECUTION */")
        async_index_2.update!(definition: "#{async_index_1.definition} /* SYNC_TESTING_EXECUTION */")
      end

      it 'creates IndexCreator instances for each async_index and calls perform' do
        expect(Gitlab::Database::Migrations::PreparedAsyncDmlOperationsTesting::IndexCreator).to(
          receive(:new).with(async_index_1).and_return(index_creator_1)
        )

        expect(Gitlab::Database::Migrations::PreparedAsyncDmlOperationsTesting::IndexCreator).to(
          receive(:new).with(async_index_2).and_return(index_creator2)
        )

        expect(index_creator_1).to receive(:perform)
        expect(index_creator2).to receive(:perform)

        described_class.execute!
      end
    end

    context 'when async indexes are not tagged to be executed' do
      let!(:async_index_1) { create(:postgres_async_index, name: 'test_index_1') }
      let!(:async_index_2) { create(:postgres_async_index, name: 'test_index_2') }

      it 'does not calls IndexCreator' do
        expect(Gitlab::Database::Migrations::PreparedAsyncDmlOperationsTesting::IndexCreator).not_to receive(:new)

        described_class.execute!
      end
    end
  end
end
