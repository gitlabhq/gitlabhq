# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::MigrateRecordsToGhostUserInBatchesService, feature_category: :user_management do
  describe '#execute' do
    let_it_be_with_reload(:human_migration) { create(:ghost_user_migration, user: create(:user)) }
    let_it_be_with_reload(:project_bot_migration) { create(:ghost_user_migration, user: create(:user, :project_bot)) }
    let_it_be_with_reload(:service_account_migration) do
      create(:ghost_user_migration, user: create(:user, :service_account))
    end

    context 'with user_types: [:human]' do
      let(:service) { described_class.new(user_types: [:human]) }

      it 'processes only human migrations' do
        expect(Users::MigrateRecordsToGhostUserService).to(
          receive(:new).with(human_migration.user, human_migration.initiator_user, any_args)
        ).and_call_original

        service.execute
      end

      it 'does not process non-human migrations' do
        expect(Users::MigrateRecordsToGhostUserService).not_to(
          receive(:new).with(project_bot_migration.user, anything, anything)
        )

        expect(Users::MigrateRecordsToGhostUserService).not_to(
          receive(:new).with(service_account_migration.user, anything, anything)
        )

        service.execute
      end

      it 'stops when execution time limit reached' do
        expect_next_instance_of(::Gitlab::Utils::ExecutionTracker) do |tracker|
          expect(tracker).to receive(:over_limit?).and_return(true)
        end

        expect(Users::MigrateRecordsToGhostUserService).not_to receive(:new)

        service.execute
      end

      it 'process jobs ordered by the consume_after timestamp' do
        older_human_migration = create(
          :ghost_user_migration,
          user: create(:user),
          consume_after: 5.minutes.ago
        )

        # setup execution tracker to only allow a single job to be processed
        allow_next_instance_of(::Gitlab::Utils::ExecutionTracker) do |tracker|
          allow(tracker).to receive(:over_limit?).and_return(false, true)
        end

        expect(Users::MigrateRecordsToGhostUserService).to(
          receive(:new).with(older_human_migration.user, older_human_migration.initiator_user, any_args)
        ).and_call_original

        service.execute
      end

      it 'reschedules job in case of an error', :freeze_time do
        expect_next_instance_of(Users::MigrateRecordsToGhostUserService) do |migrate_service|
          expect(migrate_service).to(receive(:execute)).and_raise(ActiveRecord::QueryCanceled)
        end
        expect(Gitlab::ErrorTracking).to receive(:track_exception)

        expect { service.execute }.to(
          change { human_migration.reload.consume_after }.to(30.minutes.from_now))
      end

      it 'defers job to the back of the queue when the execution time limit is reached', :freeze_time do
        human_migration.update!(consume_after: 1.hour.from_now)

        expect_next_instance_of(Users::MigrateRecordsToGhostUserService) do |migrate_service|
          expect(migrate_service).to(receive(:execute)).and_raise(::Gitlab::Utils::ExecutionTracker::ExecutionTimeOutError)
        end

        expect { service.execute }.to(
          change { human_migration.reload.consume_after }.to(1.hour.from_now + 30.seconds))
      end
    end

    context 'with user_types: [:project_bot, :service_account]' do
      let(:service) { described_class.new(user_types: [:project_bot, :service_account]) }

      it 'processes only project_bot and service_account migrations' do
        expect(Users::MigrateRecordsToGhostUserService).to(
          receive(:new).with(project_bot_migration.user, project_bot_migration.initiator_user, any_args)
        ).and_call_original

        expect(Users::MigrateRecordsToGhostUserService).to(
          receive(:new).with(service_account_migration.user, service_account_migration.initiator_user, any_args)
        ).and_call_original

        service.execute
      end

      it 'does not process human migrations' do
        expect(Users::MigrateRecordsToGhostUserService).not_to(
          receive(:new).with(human_migration.user, anything, anything)
        )

        service.execute
      end

      it 'stops when execution time limit reached' do
        expect_next_instance_of(::Gitlab::Utils::ExecutionTracker) do |tracker|
          expect(tracker).to receive(:over_limit?).and_return(true)
        end

        expect(Users::MigrateRecordsToGhostUserService).not_to receive(:new)

        service.execute
      end

      it 'process jobs ordered by the consume_after timestamp' do
        older_project_bot_migration = create(
          :ghost_user_migration,
          user: create(:user, :project_bot),
          consume_after: 5.minutes.ago
        )

        # setup execution tracker to only allow a single job to be processed
        allow_next_instance_of(::Gitlab::Utils::ExecutionTracker) do |tracker|
          allow(tracker).to receive(:over_limit?).and_return(false, true)
        end

        expect(Users::MigrateRecordsToGhostUserService).to(
          receive(:new).with(older_project_bot_migration.user, older_project_bot_migration.initiator_user, any_args)
        ).and_call_original

        service.execute
      end

      it 'reschedules job in case of an error', :freeze_time do
        expect_next_instance_of(Users::MigrateRecordsToGhostUserService) do |migrate_service|
          expect(migrate_service).to(receive(:execute)).and_raise(ActiveRecord::QueryCanceled)
        end
        expect(Gitlab::ErrorTracking).to receive(:track_exception)

        expect_next_instance_of(Users::MigrateRecordsToGhostUserService) do |migrate_service|
          expect(migrate_service).to(receive(:execute)).and_call_original
        end

        expect { service.execute }.to(
          change { project_bot_migration.reload.consume_after }.to(30.minutes.from_now))
      end

      it 'defers job to the back of the queue when the execution time limit is reached', :freeze_time do
        service_account_migration.update!(consume_after: 1.hour.from_now)

        # setup execution tracker to only allow a single job to be processed
        allow_next_instance_of(::Gitlab::Utils::ExecutionTracker) do |tracker|
          allow(tracker).to receive(:over_limit?).and_return(false, true)
        end
        expect_next_instance_of(Users::MigrateRecordsToGhostUserService) do |migrate_service|
          expect(migrate_service).to(receive(:execute)).and_raise(::Gitlab::Utils::ExecutionTracker::ExecutionTimeOutError)
        end

        expect { service.execute }.to(
          change { project_bot_migration.reload.consume_after }.to(1.hour.from_now + 30.seconds))
      end
    end
  end
end
