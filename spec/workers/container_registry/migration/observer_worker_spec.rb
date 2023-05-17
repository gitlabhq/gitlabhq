# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Migration::ObserverWorker, :aggregate_failures, feature_category: :container_registry do
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform }

    context 'when the migration feature flag is disabled' do
      before do
        stub_feature_flags(container_registry_migration_phase2_enabled: false)
      end

      it 'does nothing' do
        expect(worker).not_to receive(:log_extra_metadata_on_done)

        subject
      end
    end

    context 'when the migration is enabled' do
      before do
        create_list(:container_repository, 3)
        create(:container_repository, :pre_importing)
        create(:container_repository, :pre_import_done)
        create_list(:container_repository, 2, :importing)
        create(:container_repository, :import_aborted)
        # batch_count is not allowed within a transaction but
        # all rspec tests run inside of a transaction.
        # This mocks the false positive.
        allow(ActiveRecord::Base.connection).to receive(:transaction_open?).and_return(false) # rubocop:disable Database/MultipleDatabases
      end

      it 'logs all the counts' do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:default_count, 3)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:pre_importing_count, 1)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:pre_import_done_count, 1)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:importing_count, 2)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:import_done_count, 0)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:import_aborted_count, 1)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:import_skipped_count, 0)

        subject
      end

      context 'with load balancing enabled', :db_load_balancing do
        it 'uses the replica' do
          expect(Gitlab::Database::LoadBalancing::Session.current).to receive(:use_replicas_for_read_queries).and_call_original

          subject
        end
      end
    end
  end
end
