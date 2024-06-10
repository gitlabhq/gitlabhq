# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokens::ExpiringWorker, type: :worker, feature_category: :system_access do
  subject(:worker) { described_class.new }

  shared_examples 'sends notification about expiry of bot user tokens' do
    it 'uses notification service to send the email' do
      expect_next_instance_of(NotificationService) do |notification_service|
        expect(notification_service).to receive(:bot_resource_access_token_about_to_expire)
                                          .with(project_bot, expiring_token.name)
      end

      worker.perform
    end

    it 'marks the notification as delivered' do
      expect { worker.perform }.to change { expiring_token.reload.expire_notification_delivered }.from(false).to(true)
    end
  end

  describe '#perform' do
    context 'when a token needs to be notified' do
      let_it_be(:user) { create(:user) }
      let_it_be(:expiring_token) { create(:personal_access_token, user: user, expires_at: 5.days.from_now) }
      let_it_be(:expiring_token2) { create(:personal_access_token, user: user, expires_at: 3.days.from_now) }
      let_it_be(:notified_token) { create(:personal_access_token, user: user, expires_at: 5.days.from_now, expire_notification_delivered: true) }
      let_it_be(:not_expiring_token) { create(:personal_access_token, user: user, expires_at: 1.month.from_now) }
      let_it_be(:impersonation_token) { create(:personal_access_token, user: user, expires_at: 5.days.from_now, impersonation: true) }

      it 'uses notification service to send the email' do
        expect_next_instance_of(NotificationService) do |notification_service|
          expect(notification_service).to receive(:access_token_about_to_expire).with(user, match_array([expiring_token.name, expiring_token2.name]))
        end

        worker.perform
      end

      it 'marks the notification as delivered' do
        expect { worker.perform }.to change { expiring_token.reload.expire_notification_delivered }.from(false).to(true)
      end

      it 'avoids N+1 queries', :use_sql_query_cache do
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { worker.perform }

        user1 = create(:user)
        create(:personal_access_token, user: user1, expires_at: 5.days.from_now)

        user2 = create(:user)
        create(:personal_access_token, user: user2, expires_at: 5.days.from_now)

        # Query count increased for the user look up
        # there are still two N+1 queries one for token name look up and another for token update.
        expect { worker.perform }.not_to exceed_all_query_limit(control).with_threshold(2)
      end

      it 'does not execute webhook' do
        expect(::Projects::TriggeredHooks).not_to receive(:execute)

        worker.perform
      end
    end

    context 'when no tokens need to be notified' do
      let_it_be(:pat) { create(:personal_access_token, expires_at: 5.days.from_now, expire_notification_delivered: true) }

      it "doesn't call notification services" do
        expect(worker).not_to receive(:notification_service)

        worker.perform
      end

      it "doesn't change the notification delivered of the token" do
        expect { worker.perform }.not_to change { pat.reload.expire_notification_delivered }
      end
    end

    context 'when a token is an impersonation token' do
      let_it_be(:pat) { create(:personal_access_token, :impersonation, expires_at: 5.days.from_now) }

      it "doesn't use notification service to send the email" do
        expect(worker).not_to receive(:notification_service)

        worker.perform
      end

      it "doesn't change the notification delivered of the token" do
        expect { worker.perform }.not_to change { pat.reload.expire_notification_delivered }
      end
    end

    context 'when a token is owned by a project bot' do
      let_it_be(:project_bot) { create(:user, :project_bot) }
      let_it_be(:project) { create(:project) }
      let_it_be(:expiring_token) { create(:personal_access_token, user: project_bot, expires_at: 5.days.from_now) }
      let(:fake_wh_service) { double }

      before_all do
        project.add_developer(project_bot)
      end

      it_behaves_like 'sends notification about expiry of bot user tokens'

      it 'executes access token webhook' do
        hook_data = {}
        project_hook = create(:project_hook, project: project, resource_access_token_events: true)

        expect(Gitlab::DataBuilder::ResourceAccessToken).to receive(:build).and_return(hook_data)
        expect(fake_wh_service).to receive(:async_execute).once

        expect(WebHookService)
        .to receive(:new).with(project_hook, {}, 'resource_access_token_hooks') { fake_wh_service }

        worker.perform
      end

      it 'avoids N+1 queries', :use_sql_query_cache do
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { worker.perform }

        user1 = create(:user, :project_bot, developer_of: project)
        create(:personal_access_token, user: user1, expires_at: 5.days.from_now)

        user2 = create(:user, :project_bot, developer_of: project)
        create(:personal_access_token, user: user2, expires_at: 5.days.from_now)

        expect { worker.perform }.not_to exceed_all_query_limit(control)
      end
    end

    context 'when a token is owned by a group bot' do
      let_it_be(:project_bot) { create(:user, :project_bot) }
      let_it_be(:expiring_token) { create(:personal_access_token, user: project_bot, expires_at: 5.days.from_now) }

      context 'when the group of the resource bot exists' do
        let_it_be(:group) { create(:group) }

        before_all do
          group.add_maintainer(project_bot)
        end

        it_behaves_like 'sends notification about expiry of bot user tokens'

        it 'updates expire notification delivered attribute of the token' do
          expect { worker.perform }.to change { expiring_token.reload.expire_notification_delivered }.from(false).to(true)
        end

        context 'when exception is raised during processing' do
          context 'with a single resource access token' do
            before do
              allow_next_instance_of(NotificationService) do |service|
                allow(service).to(
                  receive(:bot_resource_access_token_about_to_expire)
                    .with(project_bot, expiring_token.name)
                    .and_raise('boom!')
                )
              end
            end

            it 'logs error' do
              expect(Gitlab::AppLogger).to(
                receive(:error)
                  .with({ message: 'Failed to send notification about expiring resource access tokens',
                          class: described_class,
                          "exception.class": "RuntimeError",
                          "exception.message": "boom!",
                          user_id: project_bot.id })
              )

              worker.perform
            end

            it 'does not update token with failed delivery' do
              expect { worker.perform }.not_to change { expiring_token.reload.expire_notification_delivered }
            end
          end

          context 'with multiple resource access tokens' do
            let_it_be(:another_project_bot) { create(:user, :project_bot) }
            let_it_be(:another_expiring_token) { create(:personal_access_token, user: another_project_bot, expires_at: 5.days.from_now) }

            before_all do
              group.add_maintainer(another_project_bot)
            end

            it 'continues sending email' do
              expect_next_instance_of(NotificationService) do |service|
                expect(service).to(
                  receive(:bot_resource_access_token_about_to_expire)
                    .with(project_bot, expiring_token.name)
                    .and_raise('boom!')
                )
                expect(service).to(
                  receive(:bot_resource_access_token_about_to_expire)
                    .with(another_project_bot, another_expiring_token.name)
                    .and_call_original
                )
              end

              worker.perform
            end
          end
        end
      end

      context 'when the group of the resource bot has been deleted' do
        it 'does not update token with no delivery' do
          expect(Group).to be_none
          expect(Project).to be_none

          expect { worker.perform }.not_to change { expiring_token.reload.expire_notification_delivered }
        end
      end
    end
  end
end
