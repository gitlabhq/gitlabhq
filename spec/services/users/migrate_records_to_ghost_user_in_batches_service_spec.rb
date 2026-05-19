# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::MigrateRecordsToGhostUserInBatchesService, feature_category: :user_management do
  let(:service) { described_class.new }

  describe '#execute' do
    context "when there is a ghost_user migration" do
      let_it_be_with_reload(:ghost_user_migration) { create(:ghost_user_migration) }

      it 'stops when execution time limit reached' do
        expect_next_instance_of(::Gitlab::Utils::ExecutionTracker) do |tracker|
          expect(tracker).to receive(:over_limit?).and_return(true)
        end

        expect(Users::MigrateRecordsToGhostUserService).not_to receive(:new)

        service.execute
      end

      it 'calls Users::MigrateRecordsToGhostUserService' do
        expect_next_instance_of(Users::MigrateRecordsToGhostUserService) do |service|
          expect(service).to(
            receive(:execute)
              .with(hard_delete: ghost_user_migration.hard_delete))
        end

        service.execute
      end

      it 'process jobs ordered by the consume_after timestamp' do
        older_ghost_user_migration = create(
          :ghost_user_migration,
          user: create(:user),
          consume_after: 5.minutes.ago
        )

        # setup execution tracker to only allow a single job to be processed
        allow_next_instance_of(::Gitlab::Utils::ExecutionTracker) do |tracker|
          allow(tracker).to receive(:over_limit?).and_return(false, true)
        end

        expect(Users::MigrateRecordsToGhostUserService).to(
          receive(:new).with(
            older_ghost_user_migration.user,
            older_ghost_user_migration.initiator_user,
            any_args
          )
        ).and_call_original

        service.execute
      end

      it 'reschedules job in case of an error', :freeze_time do
        expect_next_instance_of(Users::MigrateRecordsToGhostUserService) do |service|
          expect(service).to(receive(:execute)).and_raise(ActiveRecord::QueryCanceled)
        end
        expect(Gitlab::ErrorTracking).to receive(:track_exception)

        expect { service.execute }.to(
          change { ghost_user_migration.reload.consume_after }
            .to(30.minutes.from_now))
      end

      it 'defers job to the back of the queue when the execution time limit is reached', :freeze_time do
        consume_after_timestamp = ghost_user_migration.consume_after

        expect_next_instance_of(Users::MigrateRecordsToGhostUserService) do |migrate_service|
          expect(migrate_service).to(receive(:execute)).and_raise(::Gitlab::Utils::ExecutionTracker::ExecutionTimeOutError)
        end

        expect { service.execute }.to(
          change { ghost_user_migration.reload.consume_after }
            .to(consume_after_timestamp + 30.seconds))
      end
    end

    context 'when there is no ghost_user migration' do
      it 'does not call Users::MigrateRecordsToGhostUserService' do
        expect(Users::MigrateRecordsToGhostUserService).not_to receive(:new)

        service.execute
      end
    end
  end
end
