# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::InactiveProjectsDeletionCronWorker do
  include ProjectHelpers

  describe "#perform" do
    subject(:worker) { described_class.new }

    let_it_be(:admin_user) { create(:user, :admin) }
    let_it_be(:non_admin_user) { create(:user) }
    let_it_be(:new_blank_project) do
      create_project_with_statistics.tap do |project|
        project.update!(last_activity_at: Time.current)
      end
    end

    let_it_be(:inactive_blank_project) do
      create_project_with_statistics.tap do |project|
        project.update!(last_activity_at: 13.months.ago)
      end
    end

    let_it_be(:inactive_large_project) do
      create_project_with_statistics(with_data: true, size_multiplier: 2.gigabytes)
        .tap { |project| project.update!(last_activity_at: 2.years.ago) }
    end

    let_it_be(:active_large_project) do
      create_project_with_statistics(with_data: true, size_multiplier: 2.gigabytes)
        .tap { |project| project.update!(last_activity_at: 1.month.ago) }
    end

    before do
      stub_application_setting(inactive_projects_min_size_mb: 5)
      stub_application_setting(inactive_projects_send_warning_email_after_months: 12)
      stub_application_setting(inactive_projects_delete_after_months: 14)
    end

    context 'when delete inactive projects feature is disabled' do
      before do
        stub_application_setting(delete_inactive_projects: false)
      end

      it 'does not invoke Projects::InactiveProjectsDeletionNotificationWorker' do
        expect(::Projects::InactiveProjectsDeletionNotificationWorker).not_to receive(:perform_in)
        expect(::Projects::DestroyService).not_to receive(:new)

        worker.perform
      end

      it 'does not delete the inactive projects' do
        worker.perform

        expect(inactive_large_project.reload.pending_delete).to eq(false)
      end
    end

    context 'when delete inactive projects feature is enabled' do
      before do
        stub_application_setting(delete_inactive_projects: true)
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(inactive_projects_deletion: false)
        end

        it 'does not invoke Projects::InactiveProjectsDeletionNotificationWorker' do
          expect(::Projects::InactiveProjectsDeletionNotificationWorker).not_to receive(:perform_in)
          expect(::Projects::DestroyService).not_to receive(:new)

          worker.perform
        end

        it 'does not delete the inactive projects' do
          worker.perform

          expect(inactive_large_project.reload.pending_delete).to eq(false)
        end
      end

      context 'when feature flag is enabled', :clean_gitlab_redis_shared_state, :sidekiq_inline do
        let_it_be(:delay) { anything }

        before do
          stub_feature_flags(inactive_projects_deletion: true)
        end

        it 'invokes Projects::InactiveProjectsDeletionNotificationWorker for inactive projects' do
          Gitlab::Redis::SharedState.with do |redis|
            expect(redis).to receive(:hset).with('inactive_projects_deletion_warning_email_notified',
                                                 "project:#{inactive_large_project.id}", Date.current)
          end
          expect(::Projects::InactiveProjectsDeletionNotificationWorker).to receive(:perform_in).with(
            delay, inactive_large_project.id, deletion_date).and_call_original
          expect(::Projects::DestroyService).not_to receive(:new)

          worker.perform
        end

        it 'does not invoke InactiveProjectsDeletionNotificationWorker for already notified inactive projects' do
          Gitlab::Redis::SharedState.with do |redis|
            redis.hset('inactive_projects_deletion_warning_email_notified', "project:#{inactive_large_project.id}",
                       Date.current.to_s)
          end

          expect(::Projects::InactiveProjectsDeletionNotificationWorker).not_to receive(:perform_in)
          expect(::Projects::DestroyService).not_to receive(:new)

          worker.perform
        end

        it 'invokes Projects::DestroyService for projects that are inactive even after being notified' do
          Gitlab::Redis::SharedState.with do |redis|
            redis.hset('inactive_projects_deletion_warning_email_notified', "project:#{inactive_large_project.id}",
                       15.months.ago.to_date.to_s)
          end

          expect(::Projects::InactiveProjectsDeletionNotificationWorker).not_to receive(:perform_in)
          expect(::Projects::DestroyService).to receive(:new).with(inactive_large_project, admin_user, {})
                                                             .at_least(:once).and_call_original

          worker.perform

          expect(inactive_large_project.reload.pending_delete).to eq(true)

          Gitlab::Redis::SharedState.with do |redis|
            expect(redis.hget('inactive_projects_deletion_warning_email_notified',
                              "project:#{inactive_large_project.id}")).to be_nil
          end
        end
      end

      it_behaves_like 'an idempotent worker'
    end
  end
end
