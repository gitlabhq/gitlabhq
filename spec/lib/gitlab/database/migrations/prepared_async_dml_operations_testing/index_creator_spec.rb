# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::PreparedAsyncDmlOperationsTesting::IndexCreator, feature_category: :database do
  include ExclusiveLeaseHelpers

  describe '#perform' do
    let(:async_index) { create(:postgres_async_index) }
    let(:connection_name) { Gitlab::Database::PRIMARY_DATABASE_NAME }
    let(:model) { Gitlab::Database.database_base_models[connection_name] }
    let(:connection) { model.connection }
    let(:lease_key) { "gitlab/database/asyncddl/actions/#{connection_name}" }
    let(:lease_timeout) { 3.minutes }

    let!(:lease) { stub_exclusive_lease(lease_key, :uuid, timeout: lease_timeout) }

    subject(:index_creator) { described_class.new(async_index) }

    around do |example|
      Gitlab::Database::SharedModel.using_connection(connection) do
        example.run
      end
    end

    shared_examples 'handling an error' do
      it 'logs the error and destroys the record' do
        allow(connection).to receive(:transaction).and_yield
        allow(connection).to receive(:execute).with("SET statement_timeout TO '180s'")
        allow(connection).to receive(:execute).with(async_index.definition).and_raise(error)
        allow(connection).to receive(:execute).with('RESET statement_timeout')

        expect(Gitlab::AppLogger).to receive(:info).with(message: error, index: async_index.name)

        expect(async_index).to receive(:destroy!).and_call_original

        expect { index_creator.perform }.not_to raise_error
      end
    end

    context 'when index creation succeeds' do
      it 'executes the index definition within a transaction' do
        allow(connection).to receive(:execute)
        expect(connection).to receive(:execute).with("SET statement_timeout TO '180s'").ordered.and_call_original
        expect(connection).to receive(:execute).with(async_index.definition).ordered.and_call_original
        expect(connection).to receive(:execute).with('RESET statement_timeout').ordered.and_call_original

        expect { index_creator.perform }.to change { Gitlab::Database::AsyncIndexes::PostgresAsyncIndex.count }.by(-1)
      end
    end

    context 'when statement timeout occurs' do
      let(:error) { ActiveRecord::StatementTimeout.new('statement timeout') }

      it_behaves_like 'handling an error'
    end

    context 'when query is canceled' do
      let(:error) { ActiveRecord::QueryCanceled.new('query canceled') }

      it_behaves_like 'handling an error'
    end

    context 'when adapter timeout occurs' do
      let(:error) { ActiveRecord::AdapterTimeout.new('adapter timeout') }

      it_behaves_like 'handling an error'
    end

    context 'when lock wait timeout occurs' do
      let(:error) { ActiveRecord::LockWaitTimeout.new('lock wait timeout') }

      it_behaves_like 'handling an error'
    end

    context 'when a invalid statement error occurs' do
      let(:async_index) { create(:postgres_async_index, definition: 'CREATE INDEX idx_t ON missing_table (id)') }

      it 'logs the error and destroys the record' do
        allow(connection).to receive(:transaction).and_yield
        allow(connection).to receive(:execute).with("SET statement_timeout TO '180s'")
        allow(connection).to receive(:execute).with(async_index.definition).and_call_original
        allow(connection).to receive(:execute).with('RESET statement_timeout')

        expect(async_index).to receive(:destroy!).and_call_original

        expect { index_creator.perform }.to raise_error(ActiveRecord::StatementInvalid)
      end
    end
  end
end
