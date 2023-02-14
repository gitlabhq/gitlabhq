# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Reindexing::Coordinator, feature_category: :database do
  include Database::DatabaseHelpers
  include ExclusiveLeaseHelpers

  let(:index) { create(:postgres_index) }
  let(:connection) { index.connection }
  let(:notifier) do
    instance_double(Gitlab::Database::Reindexing::GrafanaNotifier, notify_start: nil, notify_end: nil)
  end

  let!(:lease) { stub_exclusive_lease(lease_key, uuid, timeout: lease_timeout) }
  let(:lease_key) { "gitlab/database/asyncddl/actions/#{Gitlab::Database::PRIMARY_DATABASE_NAME}" }
  let(:lease_timeout) { 1.day }
  let(:uuid) { 'uuid' }

  around do |example|
    model = Gitlab::Database.database_base_models[Gitlab::Database::PRIMARY_DATABASE_NAME]

    Gitlab::Database::SharedModel.using_connection(model.connection) do
      swapout_view_for_table(:postgres_indexes, connection: model.connection)
      example.run
    end
  end

  describe '#perform' do
    subject { described_class.new(index, notifier).perform }

    let(:reindexer) { instance_double(Gitlab::Database::Reindexing::ReindexConcurrently, perform: nil) }
    let(:action) { create(:reindex_action, index: index) }

    context 'when executed during the weekend', time_travel_to: '2023-01-07T09:44:07Z' do
      before do
        allow(Gitlab::Database::Reindexing::ReindexConcurrently).to receive(:new).with(index).and_return(reindexer)
        allow(Gitlab::Database::Reindexing::ReindexAction).to receive(:create_for).with(index).and_return(action)
      end

      context 'locking' do
        it 'acquires a lock while reindexing' do
          expect(lease).to receive(:try_obtain).ordered.and_return(uuid)

          expect(reindexer).to receive(:perform).ordered

          expect(Gitlab::ExclusiveLease).to receive(:cancel).ordered.with(lease_key, uuid)

          subject
        end

        it 'does not perform reindexing actions if lease is not granted' do
          expect(lease).to receive(:try_obtain).ordered.and_return(false)
          expect(Gitlab::Database::Reindexing::ReindexConcurrently).not_to receive(:new)

          subject
        end
      end

      context 'notifications' do
        it 'sends #notify_start before reindexing' do
          expect(notifier).to receive(:notify_start).with(action).ordered
          expect(reindexer).to receive(:perform).ordered

          subject
        end

        it 'sends #notify_end after reindexing and updating the action is done' do
          expect(action).to receive(:finish).ordered
          expect(notifier).to receive(:notify_end).with(action).ordered

          subject
        end
      end

      context 'action tracking' do
        it 'calls #finish on the action' do
          expect(reindexer).to receive(:perform).ordered
          expect(action).to receive(:finish).ordered

          subject
        end

        it 'upon error, it still calls finish and raises the error' do
          expect(reindexer).to receive(:perform).ordered.and_raise('something went wrong')
          expect(action).to receive(:finish).ordered

          expect { subject }.to raise_error(/something went wrong/)

          expect(action).to be_failed
        end
      end
    end

    context 'when executed during the week', time_travel_to: '2023-01-09T09:44:07Z' do
      it 'does not start reindexing' do
        expect(lease).not_to receive(:try_obtain)
        expect(Gitlab::Database::Reindexing::ReindexConcurrently).not_to receive(:new)

        expect(subject).to be_nil
      end
    end
  end

  describe '#drop' do
    let(:connection) { index.connection }

    subject(:drop) { described_class.new(index, notifier).drop }

    context 'when executed during the weekend', time_travel_to: '2023-01-07T09:44:07Z' do
      context 'when exclusive lease is granted' do
        it 'drops the index with lock retries' do
          expect(lease).to receive(:try_obtain).ordered.and_return(uuid)

          expect_query("SET lock_timeout TO '60000ms'")
          expect_query("DROP INDEX CONCURRENTLY IF EXISTS \"public\".\"#{index.name}\"")
          expect_query("RESET idle_in_transaction_session_timeout; RESET lock_timeout")

          expect(Gitlab::ExclusiveLease).to receive(:cancel).ordered.with(lease_key, uuid)

          drop
        end

        def expect_query(sql)
          expect(connection).to receive(:execute).ordered.with(sql).and_wrap_original do |method, sql|
            method.call(sql.sub(/CONCURRENTLY/, ''))
          end
        end
      end

      context 'when exclusive lease is not granted' do
        it 'does not drop the index' do
          expect(lease).to receive(:try_obtain).ordered.and_return(false)
          expect(Gitlab::Database::WithLockRetriesOutsideTransaction).not_to receive(:new)
          expect(connection).not_to receive(:execute)

          drop
        end
      end
    end

    context 'when executed during the week', time_travel_to: '2023-01-09T09:44:07Z' do
      it 'does not start reindexing' do
        expect(lease).not_to receive(:try_obtain)
        expect(Gitlab::Database::WithLockRetriesOutsideTransaction).not_to receive(:new)
        expect(connection).not_to receive(:execute)

        expect(drop).to be_nil
      end
    end
  end
end
