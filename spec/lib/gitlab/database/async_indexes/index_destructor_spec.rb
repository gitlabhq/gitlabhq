# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::AsyncIndexes::IndexDestructor do
  include ExclusiveLeaseHelpers

  describe '#perform' do
    subject { described_class.new(async_index) }

    let(:async_index) { create(:postgres_async_index, :with_drop) }

    let(:index_model) { Gitlab::Database::AsyncIndexes::PostgresAsyncIndex }

    let(:model) { Gitlab::Database.database_base_models[Gitlab::Database::PRIMARY_DATABASE_NAME] }
    let(:connection) { model.connection }

    let!(:lease) { stub_exclusive_lease(lease_key, :uuid, timeout: lease_timeout) }
    let(:lease_key) { "gitlab/database/indexing/actions/#{Gitlab::Database::PRIMARY_DATABASE_NAME}" }
    let(:lease_timeout) { described_class::TIMEOUT_PER_ACTION }

    before do
      connection.add_index(async_index.table_name, 'id', name: async_index.name)
    end

    around do |example|
      Gitlab::Database::SharedModel.using_connection(connection) do
        example.run
      end
    end

    context 'when the index does not exist' do
      before do
        connection.execute(async_index.definition)
      end

      it 'skips index destruction' do
        expect(connection).not_to receive(:execute).with(/DROP INDEX/)

        subject.perform
      end
    end

    it 'creates the index while controlling lock timeout' do
      allow(connection).to receive(:execute).and_call_original
      expect(connection).to receive(:execute).with("SET lock_timeout TO '60000ms'").and_call_original
      expect(connection).to receive(:execute).with(async_index.definition).and_call_original
      expect(connection).to receive(:execute)
        .with("RESET idle_in_transaction_session_timeout; RESET lock_timeout")
        .and_call_original

      subject.perform
    end

    it 'removes the index preparation record from postgres_async_indexes' do
      expect(async_index).to receive(:destroy).and_call_original

      expect { subject.perform }.to change { index_model.count }.by(-1)
    end

    it 'skips logic if not able to acquire exclusive lease' do
      expect(lease).to receive(:try_obtain).ordered.and_return(false)
      expect(connection).not_to receive(:execute).with(/DROP INDEX/)
      expect(async_index).not_to receive(:destroy)

      expect { subject.perform }.not_to change { index_model.count }
    end
  end
end
