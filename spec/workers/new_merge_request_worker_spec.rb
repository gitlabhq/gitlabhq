# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NewMergeRequestWorker do
  describe '#perform' do
    let(:worker) { described_class.new }

    context 'when a merge request not found' do
      it 'does not call Services' do
        expect(EventCreateService).not_to receive(:new)
        expect(NotificationService).not_to receive(:new)

        worker.perform(non_existing_record_id, create(:user).id)
      end

      it 'logs an error' do
        user = create(:user)

        expect(Gitlab::AppLogger).to receive(:error).with("NewMergeRequestWorker: couldn't find MergeRequest with ID=#{non_existing_record_id}, skipping job")

        worker.perform(non_existing_record_id, user.id)
      end
    end

    context 'when a user not found' do
      it 'does not call Services' do
        expect(EventCreateService).not_to receive(:new)
        expect(NotificationService).not_to receive(:new)

        worker.perform(create(:merge_request).id, non_existing_record_id)
      end

      it 'logs an error' do
        merge_request = create(:merge_request)

        expect(Gitlab::AppLogger).to receive(:error).with("NewMergeRequestWorker: couldn't find User with ID=#{non_existing_record_id}, skipping job")

        worker.perform(merge_request.id, non_existing_record_id)
      end
    end

    context 'with a user' do
      let(:project) { create(:project, :public) }
      let(:mentioned) { create(:user) }
      let(:user) { nil }
      let(:merge_request) do
        create(:merge_request, source_project: project, description: "mr for #{mentioned.to_reference}")
      end

      shared_examples 'a new merge request where the author cannot trigger notifications' do
        it 'does not create a notification for the mentioned user' do
          expect(Notify).not_to receive(:new_merge_request_email)
            .with(mentioned.id, merge_request.id, NotificationReason::MENTIONED)

          expect(Gitlab::AppLogger).to receive(:warn).with(message: 'Skipping sending notifications', user: user.id, klass: merge_request.class.to_s, object_id: merge_request.id)

          worker.perform(merge_request.id, user.id)
        end
      end

      context 'when the merge request author is blocked' do
        let(:user) { create(:user, :blocked) }

        it_behaves_like 'a new merge request where the author cannot trigger notifications'
      end

      context 'when the merge request author is a ghost' do
        let(:user) { create(:user, :ghost) }

        it_behaves_like 'a new merge request where the author cannot trigger notifications'
      end

      context 'when everything is ok' do
        let(:user) { create(:user) }

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
end
