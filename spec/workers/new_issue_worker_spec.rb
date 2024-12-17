# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NewIssueWorker, feature_category: :team_planning do
  include AfterNextHelpers

  describe '#perform' do
    let(:worker) { described_class.new }

    context 'when an issue not found' do
      it 'does not call Services' do
        expect(EventCreateService).not_to receive(:new)
        expect(NotificationService).not_to receive(:new)

        worker.perform(non_existing_record_id, create(:user).id)
      end

      it 'logs an error' do
        expect(Gitlab::AppLogger).to receive(:error).with("NewIssueWorker: couldn't find Issue with ID=#{non_existing_record_id}, skipping job")

        worker.perform(non_existing_record_id, create(:user).id)
      end
    end

    context 'when a user not found' do
      it 'does not call Services' do
        expect(EventCreateService).not_to receive(:new)
        expect(NotificationService).not_to receive(:new)

        worker.perform(create(:issue).id, non_existing_record_id)
      end

      it 'logs an error' do
        issue = create(:issue)

        expect(Gitlab::AppLogger).to receive(:error).with("NewIssueWorker: couldn't find User with ID=#{non_existing_record_id}, skipping job")

        worker.perform(issue.id, non_existing_record_id)
      end
    end

    context 'with a user' do
      let_it_be(:project) { create(:project, :public) }
      let_it_be(:mentioned) { create(:user) }
      let_it_be(:user) { nil }
      let_it_be(:issue) { create(:issue, project: project, description: "issue for #{mentioned.to_reference}") }

      shared_examples 'a new issue where the current_user cannot trigger notifications' do
        it 'does not create a notification for the mentioned user' do
          expect(Notify).not_to receive(:new_issue_email)
            .with(mentioned.id, issue.id, NotificationReason::MENTIONED)

          expect(Gitlab::AppLogger).to receive(:warn).with(message: 'Skipping sending notifications', user: user.id, klass: issue.class.to_s, object_id: issue.id)

          worker.perform(issue.id, user.id)
        end
      end

      context 'when the new issue author is blocked' do
        let_it_be(:user) { create_default(:user, :blocked) }

        it_behaves_like 'a new issue where the current_user cannot trigger notifications'
      end

      context 'when the new issue author is a ghost' do
        let_it_be(:user) { create_default(:user, :ghost) }

        it_behaves_like 'a new issue where the current_user cannot trigger notifications'
      end

      context 'when everything is ok' do
        let_it_be(:user) { create_default(:user) }

        it 'creates a new event record' do
          expect { worker.perform(issue.id, user.id) }.to change { Event.count }.from(0).to(1)

          expect(Event.last).to have_attributes(target_id: issue.id, target_type: 'Issue')
        end

        it 'creates a notification for the mentioned user' do
          expect(Notify).to receive(:new_issue_email).with(mentioned.id, issue.id, NotificationReason::MENTIONED)
            .and_return(double(deliver_later: true))

          worker.perform(issue.id, user.id)
        end

        it 'calls Issues::AfterCreateService' do
          expect_next(::Issues::AfterCreateService)
              .to receive(:execute)

          worker.perform(issue.id, user.id)
        end

        context 'when a class is set' do
          it 'creates event with the correct type' do
            expect { worker.perform(issue.id, user.id, 'WorkItem') }.to change { Event.count }.from(0).to(1)

            expect(Event.last).to have_attributes(target_id: issue.id, target_type: 'WorkItem')
          end
        end

        context 'when skip_notifications is true' do
          it 'does not call NotificationService' do
            expect(NotificationService).not_to receive(:new)

            worker.perform(issue.id, user.id, issue.class.name, true)
          end
        end

        context 'when issue has multiple assignees' do
          let_it_be(:users) do
            users = build_list(:user, 15)
            user_attributes = users.map { |user| user.attributes.except('id', 'otp_secret') }
            user_ids = User.insert_all(user_attributes, returning: :id).rows.flatten

            level = NotificationSetting.levels[::User::DEFAULT_NOTIFICATION_LEVEL]
            users_global_notifications = user_ids.map do |user_id|
              { user_id: user_id, source_id: nil, source_type: nil, level: level, created_at: Time.current }
            end
            NotificationSetting.insert_all(users_global_notifications)

            User.id_in(user_ids)
          end

          it 'avoids N+1 database queries' do
            new_users = create_list(:user, 2)
            issue.assignees = new_users
            expect(issue.reload.assignees.count).to eq(2)

            control = ActiveRecord::QueryRecorder.new { worker.perform(issue.id, user.id) }

            issue_assignees_attributes = users.map { |user| { user_id: user.id, issue_id: issue.id } }
            IssueAssignee.upsert_all(issue_assignees_attributes, unique_by: [:issue_id, :user_id])

            # UpdateTodoCountCacheService#QUERY_BATCH_SIZE == 10, which adds one additional query for our 15 assignees
            expect { worker.perform(issue.id, user.id) }.not_to exceed_query_limit(control).with_threshold(1)
          end
        end
      end
    end
  end
end
