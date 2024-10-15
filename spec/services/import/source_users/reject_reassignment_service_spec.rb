# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::SourceUsers::RejectReassignmentService, feature_category: :importers do
  let(:import_source_user) { create(:import_source_user, :awaiting_approval) }
  let(:reassignment_token) { import_source_user.reassignment_token }
  let(:current_user) { import_source_user.reassign_to_user }
  let(:service) do
    described_class.new(import_source_user, current_user: current_user, reassignment_token: reassignment_token)
  end

  describe '#execute' do
    let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }

    before do
      allow(message_delivery).to receive(:deliver_now)
      allow(Notify).to receive(:import_source_user_rejected).and_return(message_delivery)
    end

    it 'returns success' do
      expect(Notify).to receive_message_chain(:import_source_user_rejected, :deliver_now)
      expect(service.execute).to be_success
    end

    it 'sets the source user to rejected' do
      service.execute
      expect(import_source_user.reload).to be_rejected
    end

    shared_examples 'current user does not have permission to reject reassignment' do
      it 'returns error no permissions' do
        result = service.execute

        expect(Notify).not_to receive(:import_source_user_rejected)

        expect(result).to be_error
        expect(result.message).to eq('You have insufficient permissions to update the import source user')
      end
    end

    context 'when passing the wrong reassignment_token' do
      let(:reassignment_token) { '1234567890abcdef' }

      it_behaves_like 'current user does not have permission to reject reassignment'
    end

    context 'when not passing a reassignment_token' do
      let(:reassignment_token) { nil }

      it_behaves_like 'current user does not have permission to reject reassignment'
    end

    context 'when current user is not the assigned user' do
      let(:current_user) { create(:user) }

      it_behaves_like 'current user does not have permission to reject reassignment'
    end

    context 'when import source user does not have a rejectable status' do
      let(:import_source_user) { create(:import_source_user, :reassignment_in_progress) }

      it 'returns error invalid status' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq("Import source user has an invalid status for this operation")
      end
    end

    context 'when an error occurs' do
      before do
        allow(import_source_user).to receive(:reject).and_return(false)
        allow(import_source_user).to receive(:errors).and_return(instance_double(ActiveModel::Errors,
          full_messages: ['Error']))
      end

      it 'returns an error' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq(['Error'])
      end
    end
  end
end
