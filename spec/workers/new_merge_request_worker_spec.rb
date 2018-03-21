require 'spec_helper'

describe NewMergeRequestWorker do
  describe '#perform' do
    let(:worker) { described_class.new }

    context 'when a merge request not found' do
      it 'does not call Services' do
        expect(EventCreateService).not_to receive(:new)
        expect(NotificationService).not_to receive(:new)

        worker.perform(99, create(:user).id)
      end

      it 'logs an error' do
        expect(Rails.logger).to receive(:error).with('NewMergeRequestWorker: couldn\'t find MergeRequest with ID=99, skipping job')

        worker.perform(99, create(:user).id)
      end
    end

    context 'when a user not found' do
      it 'does not call Services' do
        expect(EventCreateService).not_to receive(:new)
        expect(NotificationService).not_to receive(:new)

        worker.perform(create(:merge_request).id, 99)
      end

      it 'logs an error' do
        expect(Rails.logger).to receive(:error).with('NewMergeRequestWorker: couldn\'t find User with ID=99, skipping job')

        worker.perform(create(:merge_request).id, 99)
      end
    end

    context 'when everything is ok' do
      let(:project) { create(:project, :public) }
      let(:mentioned) { create(:user) }
      let(:user) { create(:user) }
      let(:merge_request) do
        create(:merge_request, source_project: project, description: "mr for #{mentioned.to_reference}")
      end

      it 'creates a new event record' do
        expect { worker.perform(merge_request.id, user.id) }.to change { Event.count }.from(0).to(1)
      end

      it 'creates a notification for the mentioned user' do
        expect(Notify).to receive(:new_merge_request_email)
                            .with(mentioned.id, merge_request.id, NotificationReason::MENTIONED)
                            .and_return(double(deliver_later: true))

        worker.perform(merge_request.id, user.id)
      end
    end
  end
end
