# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NewIssueWorker do
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
      end
    end
  end
end
