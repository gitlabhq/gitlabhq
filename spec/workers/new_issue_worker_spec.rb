require 'spec_helper'

describe NewIssueWorker do
  describe '#perform' do
    let(:worker) { described_class.new }

    context 'when an issue not found' do
      it 'does not call Services' do
        expect(EventCreateService).not_to receive(:new)
        expect(NotificationService).not_to receive(:new)

        worker.perform(99, create(:user).id)
      end

      it 'logs an error' do
        expect(Rails.logger).to receive(:error).with('NewIssueWorker: couldn\'t find Issue with ID=99, skipping job')

        worker.perform(99, create(:user).id)
      end
    end

    context 'when a user not found' do
      it 'does not call Services' do
        expect(EventCreateService).not_to receive(:new)
        expect(NotificationService).not_to receive(:new)

        worker.perform(create(:issue).id, 99)
      end

      it 'logs an error' do
        expect(Rails.logger).to receive(:error).with('NewIssueWorker: couldn\'t find User with ID=99, skipping job')

        worker.perform(create(:issue).id, 99)
      end
    end

    context 'when everything is ok' do
      let(:project) { create(:project, :public) }
      let(:mentioned) { create(:user) }
      let(:user) { create(:user) }
      let(:issue) { create(:issue, project: project, description: "issue for #{mentioned.to_reference}") }

      it 'creates a new event record' do
        expect { worker.perform(issue.id, user.id) }.to change { Event.count }.from(0).to(1)
      end

      it 'creates a notification for the mentioned user' do
        expect(Notify).to receive(:new_issue_email).with(mentioned.id, issue.id, NotificationReason::MENTIONED)
                            .and_return(double(deliver_later: true))

        worker.perform(issue.id, user.id)
      end
    end
  end
end
