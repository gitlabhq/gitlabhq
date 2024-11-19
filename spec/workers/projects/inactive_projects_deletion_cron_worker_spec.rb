# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::InactiveProjectsDeletionCronWorker, feature_category: :groups_and_projects do
  include ProjectHelpers

  shared_examples 'worker is running for more than 4 minutes' do
    before do
      subject.instance_variable_set(:@start_time, ::Gitlab::Metrics::System.monotonic_time - 5.minutes)
    end

    it 'stores the last processed inactive project_id in redis cache' do
      Gitlab::Redis::Cache.with do |redis|
        expect { worker.perform }
          .to change { redis.get('last_processed_inactive_project_id') }.to(inactive_large_project.id.to_s)
      end
    end
  end

  shared_examples 'worker finishes processing in less than 4 minutes' do
    before do
      Gitlab::Redis::Cache.with do |redis|
        redis.set('last_processed_inactive_project_id', inactive_large_project.id)
      end
    end

    it 'clears the last processed inactive project_id from redis cache' do
      Gitlab::Redis::Cache.with do |redis|
        expect { worker.perform }
          .to change { redis.get('last_processed_inactive_project_id') }.to(nil)
      end
    end
  end

  describe "#perform" do
    subject(:worker) { described_class.new }

    let_it_be(:admin_bot) { ::Users::Internal.admin_bot }
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
        expect(::Projects::InactiveProjectsDeletionNotificationWorker).not_to receive(:perform_async)
        expect(::Projects::DestroyService).not_to receive(:new)

        worker.perform
      end

      it 'does not delete the inactive projects' do
        worker.perform

        expect(inactive_large_project.reload.pending_delete).to eq(false)
      end
    end

    context 'when delete inactive projects feature is enabled', :clean_gitlab_redis_shared_state, :sidekiq_inline do
      before do
        stub_application_setting(delete_inactive_projects: true)
      end

      it 'invokes Projects::InactiveProjectsDeletionNotificationWorker for inactive projects' do
        Gitlab::Redis::SharedState.with do |redis|
          expect(redis).to receive(:hset).with(
            'inactive_projects_deletion_warning_email_notified',
            "project:#{inactive_large_project.id}",
            Date.current.to_s
          )
        end
        expect(::Projects::InactiveProjectsDeletionNotificationWorker).to receive(:perform_async).with(
          inactive_large_project.id, deletion_date).and_call_original
        expect(::Projects::DestroyService).not_to receive(:new)

        worker.perform
      end

      it 'does not invoke InactiveProjectsDeletionNotificationWorker for already notified inactive projects' do
        Gitlab::Redis::SharedState.with do |redis|
          redis.hset(
            'inactive_projects_deletion_warning_email_notified',
            "project:#{inactive_large_project.id}",
            Date.current.to_s
          )
        end

        expect(::Projects::InactiveProjectsDeletionNotificationWorker).not_to receive(:perform_async)
        expect(::Projects::DestroyService).not_to receive(:new)

        worker.perform
      end

      it 'invokes Projects::DestroyService for projects that are inactive even after being notified',
        :enable_admin_mode do
        Gitlab::Redis::SharedState.with do |redis|
          redis.hset(
            'inactive_projects_deletion_warning_email_notified',
            "project:#{inactive_large_project.id}",
            15.months.ago.to_date.to_s
          )
        end

        expect(::Projects::InactiveProjectsDeletionNotificationWorker).not_to receive(:perform_async)
        expect(::Projects::DestroyService).to receive(:new).with(inactive_large_project, admin_bot, {})
                                                           .at_least(:once).and_call_original

        worker.perform

        expect(Project.exists?(inactive_large_project.id)).to be(false)

        Gitlab::Redis::SharedState.with do |redis|
          expect(
            redis.hget('inactive_projects_deletion_warning_email_notified', "project:#{inactive_large_project.id}")
          ).to be_nil
        end
      end

      it_behaves_like 'worker is running for more than 4 minutes'
      it_behaves_like 'worker finishes processing in less than 4 minutes'

      it_behaves_like 'an idempotent worker'
    end
  end
end
