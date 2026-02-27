# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeployTokens::ExpiringWorker, feature_category: :continuous_delivery do
  subject(:worker) { described_class.new }

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:owner) { create(:user) }

  before_all do
    project.add_maintainer(maintainer)
    project.add_owner(owner)
  end

  describe '#perform' do
    subject(:perform) { worker.perform }

    context 'when feature flag is disabled' do
      let!(:expiring_token) do
        create(:deploy_token, :project_type, projects: [project], expires_at: 15.days.from_now.iso8601)
      end

      before do
        stub_feature_flags(project_deploy_token_expiring_notifications: false)
      end

      it 'does not send any notifications' do
        expect(NotificationService).not_to receive(:new)
        perform
      end

      it 'does not execute webhook' do
        expect(::Projects::TriggeredHooks).not_to receive(:execute)
        perform
      end
    end

    context 'when feature flag is enabled' do
      context 'when expiring deploy tokens have already been notified' do
        let_it_be(:already_notified_deploy_token_1) do
          create(
            :deploy_token,
            :project_type,
            projects: [project],
            expires_at: 5.days.from_now.iso8601,
            seven_days_notification_sent_at: 2.days.ago.iso8601
          )
        end

        let_it_be(:already_notified_deploy_token_2) do
          create(
            :deploy_token,
            :project_type,
            projects: [project],
            expires_at: 4.days.from_now.iso8601,
            seven_days_notification_sent_at: 3.days.ago.iso8601
          )
        end

        it 'does not send any notifications' do
          expect(NotificationService).not_to receive(:new)
          perform
        end

        it "doesn't update notification sent timestamps of deploy tokens" do
          expect { perform }.not_to change {
            [
              already_notified_deploy_token_1.reload.seven_days_notification_sent_at,
              already_notified_deploy_token_2.reload.seven_days_notification_sent_at
            ]
          }
        end

        it 'does not execute webhook' do
          expect(::Projects::TriggeredHooks).not_to receive(:execute)
          perform
        end
      end

      context 'when timestamp update fails' do
        let!(:expiring_token_1) do
          create(:deploy_token, :project_type, projects: [project], expires_at: 25.days.from_now.iso8601)
        end

        let!(:expiring_token_2) do
          create(:deploy_token, :project_type, projects: [project], expires_at: 28.days.from_now.iso8601)
        end

        before do
          allow(worker).to receive(:over_time?).and_return(false)
          allow(DeployToken).to receive(:update_notification_timestamps)
            .with([expiring_token_1.id, expiring_token_2.id], :thirty_days)
            .and_raise(ActiveRecord::ActiveRecordError.new('database error'))
        end

        it 'tracks the timestamp update exception' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception)
            .with(
              an_instance_of(ActiveRecord::ActiveRecordError),
              hash_including(
                message: "Failed to update deploy token notification timestamps",
                token_ids: match_array([expiring_token_1.id, expiring_token_2.id]),
                interval: :thirty_days
              )
            )

          worker.send(:process_deploy_tokens, :thirty_days)
        end
      end

      context 'when tokens expire within 30 days' do
        let!(:expiring_token) do
          create(:deploy_token, :project_type, projects: [project], expires_at: 15.days.from_now.iso8601)
        end

        let!(:expiring_token2) do
          create(:deploy_token, :project_type, projects: [project], expires_at: 20.days.from_now.iso8601)
        end

        let!(:notified_token) do
          create(:deploy_token, :project_type, projects: [project], expires_at: 25.days.from_now.iso8601,
            thirty_days_notification_sent_at: Time.current)
        end

        let!(:not_expiring_token) do
          create(:deploy_token, :project_type, projects: [project], expires_at: 6.months.from_now.iso8601)
        end

        let!(:revoked_token) do
          create(:deploy_token, :project_type, :revoked, projects: [project], expires_at: 28.days.from_now.iso8601)
        end

        it 'uses notification service to send emails to all users for each token' do
          expect_next_instance_of(NotificationService) do |notification_service|
            project.owners_and_maintainers.each do |user|
              expect(notification_service).to receive(:deploy_token_about_to_expire)
                .with(user, expiring_token.name, project, hash_including(days_to_expire: 30))
              expect(notification_service).to receive(:deploy_token_about_to_expire)
                .with(user, expiring_token2.name, project, hash_including(days_to_expire: 30))
              expect(notification_service).not_to receive(:deploy_token_about_to_expire)
                .with(user, not_expiring_token.name, project, hash_including(days_to_expire: 30))
              expect(notification_service).not_to receive(:deploy_token_about_to_expire)
                .with(user, notified_token.name, project, hash_including(days_to_expire: 30))
              expect(notification_service).not_to receive(:deploy_token_about_to_expire)
                .with(user, revoked_token.name, project, hash_including(days_to_expire: 30))
            end
          end

          perform
        end

        it 'marks the notification as delivered', :freeze_time do
          expect(expiring_token.thirty_days_notification_sent_at).to be_nil
          expect(expiring_token2.thirty_days_notification_sent_at).to be_nil
          expect(not_expiring_token.thirty_days_notification_sent_at).to be_nil
          expect(notified_token.thirty_days_notification_sent_at).to eq(Time.current)

          perform

          expect(expiring_token.reload.thirty_days_notification_sent_at).to eq(Time.current)
          expect(expiring_token2.reload.thirty_days_notification_sent_at).to eq(Time.current)
          expect(not_expiring_token.reload.thirty_days_notification_sent_at).to be_nil
          expect(notified_token.reload.thirty_days_notification_sent_at).to eq(Time.current)
        end
      end

      context 'when tokens expire within 60 days' do
        let!(:expiring_token) do
          create(:deploy_token, :project_type, projects: [project], expires_at: 36.days.from_now.iso8601)
        end

        let!(:expiring_token2) do
          create(:deploy_token, :project_type, projects: [project], expires_at: 47.days.from_now.iso8601)
        end

        let!(:notified_token) do
          create(:deploy_token, :project_type, projects: [project], expires_at: 55.days.from_now.iso8601,
            sixty_days_notification_sent_at: Time.current)
        end

        let!(:not_expiring_token) do
          create(:deploy_token, :project_type, projects: [project], expires_at: 6.months.from_now.iso8601)
        end

        let!(:revoked_token) do
          create(:deploy_token, :project_type, :revoked, projects: [project], expires_at: 58.days.from_now.iso8601)
        end

        it 'uses notification service to send emails to all users for each token' do
          expect_next_instance_of(NotificationService) do |notification_service|
            project.owners_and_maintainers.each do |user|
              expect(notification_service).to receive(:deploy_token_about_to_expire)
                .with(user, expiring_token.name, project, hash_including(days_to_expire: 60))
              expect(notification_service).to receive(:deploy_token_about_to_expire)
                .with(user, expiring_token2.name, project, hash_including(days_to_expire: 60))
              expect(notification_service).not_to receive(:deploy_token_about_to_expire)
                .with(user, not_expiring_token.name, project, hash_including(days_to_expire: 60))
              expect(notification_service).not_to receive(:deploy_token_about_to_expire)
                .with(user, notified_token.name, project, hash_including(days_to_expire: 60))
              expect(notification_service).not_to receive(:deploy_token_about_to_expire)
                .with(user, revoked_token.name, project, hash_including(days_to_expire: 60))
            end
          end

          perform
        end

        it 'marks the notification as delivered', :freeze_time do
          expect(expiring_token.sixty_days_notification_sent_at).to be_nil
          expect(expiring_token2.sixty_days_notification_sent_at).to be_nil
          expect(not_expiring_token.sixty_days_notification_sent_at).to be_nil
          expect(notified_token.sixty_days_notification_sent_at).to eq(Time.current)

          perform

          expect(expiring_token.reload.sixty_days_notification_sent_at).to eq(Time.current)
          expect(expiring_token2.reload.sixty_days_notification_sent_at).to eq(Time.current)
          expect(not_expiring_token.reload.sixty_days_notification_sent_at).to be_nil
          expect(notified_token.reload.sixty_days_notification_sent_at).to eq(Time.current)
        end
      end

      context 'when notification service fails for a deploy token' do
        let_it_be(:user_test) { create(:user) }

        context 'when exception is raised during processing' do
          let_it_be(:project_test) { create(:project) }

          before_all do
            project_test.project_members.delete_all
            project_test.add_maintainer(user_test)
          end

          context 'with a single resource deploy token' do
            let!(:expiring_token) do
              create(:deploy_token, :project_type, projects: [project_test], expires_at: 5.days.from_now.iso8601)
            end

            before do
              allow_next_instance_of(NotificationService) do |service|
                allow(service).to(
                  receive(:deploy_token_about_to_expire)
                    .with(an_instance_of(User), expiring_token.name, project_test, hash_including(days_to_expire: 7))
                    .and_raise(StandardError.new('boom!'))
                )
              end
            end

            it 'tracks the exception' do
              expect(Gitlab::ErrorTracking).to(
                receive(:track_exception)
                  .with(
                    an_instance_of(StandardError),
                    hash_including(
                      message: 'Failed to send notification about expiring project deploy tokens',
                      exception_message: 'boom!',
                      deploy_token_id: expiring_token.id,
                      project_id: project_test.id
                    )
                  )
              )
              perform
            end

            it 'does not update token with failed delivery' do
              expect(expiring_token.seven_days_notification_sent_at).to be_nil
              perform
              expect(expiring_token.reload.seven_days_notification_sent_at).to be_nil
            end
          end

          context 'with multiple project deploy tokens' do
            let_it_be(:user) { create(:user) }
            let_it_be(:project) { create(:project) }
            let_it_be(:failing_token) do
              create(:deploy_token, :project_type, projects: [project], expires_at: 5.days.from_now.iso8601)
            end

            let_it_be(:successful_token) do
              create(:deploy_token, :project_type, projects: [project], expires_at: 5.days.from_now.iso8601)
            end

            before_all do
              project.project_members.delete_all
              project.add_maintainer(user)
            end

            before do
              allow_next_instance_of(NotificationService) do |service|
                allow(service).to receive(:deploy_token_about_to_expire)
                  .with(user, failing_token.name, project, hash_including(days_to_expire: 7))
                  .and_raise(StandardError.new('boom!'))

                allow(service).to receive(:deploy_token_about_to_expire)
                  .with(user, successful_token.name, project, hash_including(days_to_expire: 7))
                  .and_call_original
              end
            end

            it 'continues processing other tokens when one fails' do
              perform

              expect(failing_token.reload.seven_days_notification_sent_at).to be_nil
              expect(successful_token.reload.seven_days_notification_sent_at).not_to be_nil
            end
          end
        end
      end

      context 'when no deploy tokens are within notification window' do
        let_it_be(:deploy_token_1) { create(:deploy_token, :project_type, expires_at: 75.days.from_now.iso8601) }
        let_it_be(:deploy_token_2) { create(:deploy_token, :project_type, expires_at: 64.days.from_now.iso8601) }

        it 'does not send any notifications' do
          expect(NotificationService).not_to receive(:new)
          perform
        end

        it 'does not execute webhook' do
          expect(::Projects::TriggeredHooks).not_to receive(:execute)
          perform
        end

        it "doesn't update notification sent timestamps of deploy tokens" do
          expect { perform }.not_to change {
            [
              deploy_token_1.reload.seven_days_notification_sent_at,
              deploy_token_2.reload.seven_days_notification_sent_at
            ]
          }
        end
      end

      context 'when deploy tokens have already expired' do
        let_it_be(:expired_deploy_token_1) do
          create(:deploy_token, :project_type, projects: [project], expires_at: 5.days.ago.iso8601)
        end

        let_it_be(:expired_deploy_token_2) do
          create(:deploy_token, :project_type, projects: [project], expires_at: 10.days.ago.iso8601)
        end

        it 'does not send any notifications' do
          expect(NotificationService).not_to receive(:new)
          perform
        end

        it "doesn't update notification sent timestamps of deploy tokens" do
          expect { perform }.not_to change {
            [
              expired_deploy_token_1.reload.seven_days_notification_sent_at,
              expired_deploy_token_2.reload.seven_days_notification_sent_at
            ]
          }
        end
      end

      context 'when deploy tokens are revoked' do
        let_it_be(:revoked_deploy_token_1) do
          create(
            :deploy_token,
            :project_type, :revoked,
            expires_at: 5.days.ago.iso8601,
            projects: [project]
          )
        end

        it 'does not send notifications for revoked tokens' do
          expect(NotificationService).not_to receive(:new)
          perform
        end

        it 'does not execute webhook' do
          expect(::Projects::TriggeredHooks).not_to receive(:execute)
          perform
        end
      end

      context 'when project has no owners or maintainers' do
        let_it_be(:project_without_members) { create(:project) }

        let_it_be(:token_without_members) do
          create(:deploy_token, :project_type, expires_at: 5.days.from_now.iso8601, projects: [project_without_members])
        end

        before do
          project_without_members.project_members.delete_all
        end

        it 'does not send notifications' do
          notification_service = instance_double(NotificationService)
          allow(NotificationService).to receive(:new).and_return(notification_service)

          expect(notification_service).not_to receive(:deploy_token_about_to_expire)

          perform
        end
      end

      context 'when there are expiring deploy tokens' do
        let!(:expiring_seven_day_token) do
          create(:deploy_token, :project_type, projects: [project], expires_at: 6.days.from_now.iso8601)
        end

        let!(:expiring_thirty_day_token) do
          create(:deploy_token, :project_type, projects: [project], expires_at: 15.days.from_now.iso8601)
        end

        let!(:expiring_sixty_day_token) do
          create(:deploy_token, :project_type, projects: [project], expires_at: 45.days.from_now.iso8601)
        end

        let!(:revoked_token) do
          create(:deploy_token, :revoked, :project_type, projects: [project], expires_at: 5.days.from_now.iso8601)
        end

        let!(:not_expiring_token) do
          create(:deploy_token, :project_type, projects: [project], expires_at: 6.months.from_now.iso8601)
        end

        let!(:notified_token) do
          create(
            :deploy_token,
            :project_type,
            projects: [project],
            expires_at: 4.days.from_now.iso8601,
            seven_days_notification_sent_at: 2.days.ago.iso8601
          )
        end

        it 'processes all notification intervals' do
          expect(worker).to receive(:process_deploy_tokens).with(:seven_days)
          expect(worker).to receive(:process_deploy_tokens).with(:thirty_days)
          expect(worker).to receive(:process_deploy_tokens).with(:sixty_days)

          perform
        end

        it 'uses notification service to send emails to all users for each token' do
          expect_next_instance_of(NotificationService) do |notification_service|
            project.owners_and_maintainers.each do |user|
              expect(notification_service).to receive(:deploy_token_about_to_expire)
                .with(user, expiring_seven_day_token.name, project, hash_including(days_to_expire: 7))
              expect(notification_service).to receive(:deploy_token_about_to_expire)
                .with(user, expiring_thirty_day_token.name, project, hash_including(days_to_expire: 30))
              expect(notification_service).to receive(:deploy_token_about_to_expire)
                .with(user, expiring_sixty_day_token.name, project, hash_including(days_to_expire: 60))
            end
          end

          perform
        end

        it 'updates notification sent timestamps', :freeze_time do
          expect { perform }.to change {
            [
              expiring_seven_day_token.reload.seven_days_notification_sent_at,
              expiring_thirty_day_token.reload.thirty_days_notification_sent_at,
              expiring_sixty_day_token.reload.sixty_days_notification_sent_at
            ]
          }.from([nil, nil, nil]).to([Time.current, Time.current, Time.current])
        end

        it 'does not send duplicate notifications' do
          perform

          notification_service = instance_double(NotificationService)
          allow(NotificationService).to receive(:new).and_return(notification_service)

          expect(notification_service).not_to receive(:deploy_token_about_to_expire)
          perform
        end

        it 'avoids N+1 queries', :use_sql_query_cache do
          project1 = create(:project)
          user1 = create(:user)
          project1.add_maintainer(user1)
          create(:deploy_token, :project_type, projects: [project1], expires_at: 5.days.from_now.iso8601)

          control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
            worker.perform
          end

          project2 = create(:project)
          user2 = create(:user)
          project2.add_maintainer(user2)
          create(:deploy_token, :project_type, projects: [project2], expires_at: 5.days.from_now.iso8601)

          expect { worker.perform }.not_to exceed_all_query_limit(control).with_threshold(2)
        end
      end

      context 'when testing project webhook execution with deploy token' do
        let!(:project_expiring_token) do
          create(:deploy_token, :project_type, projects: [project], expires_at: 6.days.from_now.iso8601)
        end

        let(:mock_wh_service) { double }

        it 'executes project deploy token webhook' do
          hook_data = {
            object_kind: 'deploy_token',
            event_name: 'expiring_deploy_token',
            interval: 'seven_days'
          }

          project_hook = create(:project_hook, project: project, resource_deploy_token_events: true)

          expect(Gitlab::DataBuilder::ResourceDeployTokenPayload).to receive(:build).and_return(hook_data)
          expect(mock_wh_service).to receive(:async_execute).once

          expect(WebHookService)
            .to receive(:new)
            .with(
              project_hook,
              hook_data,
              'resource_deploy_token_hooks',
              idempotency_key: anything
            ) { mock_wh_service }

          perform
        end
      end

      context 'when webhook execution fails for a project deploy token' do
        let!(:expiring_token) do
          create(:deploy_token, :project_type, projects: [project], expires_at: 5.days.from_now.iso8601)
        end

        before do
          allow(worker).to receive(:execute_resource_deploy_token_web_hooks)
            .and_raise(StandardError.new('webhook failed'))
        end

        it 'logs the error and marks the result as failed' do
          expect(worker).to receive(:log_error).with(
            an_instance_of(StandardError),
            'Failed to execute webhooks for expiring project deploy token',
            expiring_token,
            project
          )

          result = worker.send(:notify_users_of_deploy_token, expiring_token, :seven_days)

          expect(result).to be false
        end

        it 'still sends notifications to users' do
          notification_service = instance_double(NotificationService)
          allow(NotificationService).to receive(:new).and_return(notification_service)

          project_users = project.owners_and_maintainers

          project_users.each do |project_user|
            expect(notification_service).to receive(:deploy_token_about_to_expire)
              .with(project_user, expiring_token.name, project, days_to_expire: 7)
          end

          result = worker.send(:notify_users_of_deploy_token, expiring_token, :seven_days)
          expect(result).to be false
        end
      end

      context 'with multiple batches of tokens' do
        let_it_be(:expiring_deploy_tokens) do
          create_list(:deploy_token, 4, :project_type, expires_at: 6.days.from_now.iso8601, projects: [project])
        end

        before do
          stub_const("#{described_class}::BATCH_SIZE", 2)
          allow(worker).to receive(:notification_intervals).and_return([:seven_days])
        end

        it 'processes tokens using keyset pagination' do
          expect(Gitlab::Pagination::Keyset::Iterator).to receive(:new).and_call_original

          perform

          expiring_deploy_tokens.each do |token|
            token.reload
            expect(token.seven_days_notification_sent_at).not_to be_nil
          end
        end

        it 'processes all tokens across multiple batches' do
          perform

          expiring_deploy_tokens.each do |token|
            token.reload
            expect(token.seven_days_notification_sent_at).not_to be_nil
          end
        end

        context 'when iteration runs over time limit' do
          before do
            allow(worker).to receive(:over_time?).and_return(false, true)
          end

          it 'processes partial batches and requeues the job' do
            expect(described_class).to receive(:perform_in).with(described_class::REQUEUE_DELAY)

            worker.perform

            processed_count = expiring_deploy_tokens.count do |token|
              token.reload.seven_days_notification_sent_at.present?
            end

            expect(processed_count).to be >= 0
            expect(processed_count).to be <= expiring_deploy_tokens.count
          end
        end
      end
    end
  end

  describe '#execute_resource_deploy_token_web_hooks' do
    subject(:execute_webhooks) do
      worker.send(:execute_resource_deploy_token_web_hooks, deploy_token, :seven_days)
    end

    let(:worker) { described_class.new }

    context 'when deploy token is project type and hooks are active' do
      let_it_be(:deploy_token) { create(:deploy_token, :project, projects: [project]) }

      before do
        allow(project).to receive(:has_active_hooks?)
          .with(:resource_deploy_token_hooks)
          .and_return(true)

        allow(Gitlab::DataBuilder::ResourceDeployTokenPayload)
          .to receive(:build)
          .and_return({ event_name: 'expiring_deploy_token' })

        allow(project).to receive(:execute_hooks)
      end

      it 'executes project deploy token hooks' do
        expect(project).to receive(:execute_hooks)
          .with({ event_name: 'expiring_deploy_token' }, :resource_deploy_token_hooks)

        execute_webhooks
      end
    end

    context 'when deploy token is group type' do
      let_it_be(:group) { create(:group) }
      let_it_be(:deploy_token) { create(:deploy_token, :group) }

      before do
        create(:group_deploy_token, group: group, deploy_token: deploy_token)

        allow(group).to receive(:has_active_hooks?)
          .with(:resource_deploy_token_hooks)
          .and_return(true)

        allow(group).to receive(:execute_hooks)
      end

      it 'does not execute webhooks for group deploy tokens' do
        execute_webhooks

        expect(group).not_to have_received(:execute_hooks)
      end
    end

    context 'when resource has no active hooks' do
      let_it_be(:project) { create(:project) }
      let_it_be(:deploy_token) { create(:deploy_token, :project) }

      before do
        allow(project).to receive(:has_active_hooks?)
          .with(:resource_deploy_token_hooks)
          .and_return(false)
      end

      it 'does not execute hooks' do
        expect(project).not_to receive(:execute_hooks)
        execute_webhooks
      end
    end
  end
end
