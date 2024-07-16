# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::DismissBroadcastMessageService, feature_category: :notifications do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:broadcast_message) { create(:broadcast_message, :future) }

    let(:params) { { broadcast_message_id: broadcast_message.id, expires_at: 2.days.from_now } }

    subject(:execute) do
      described_class.new(
        current_user: user, params: params
      ).execute
    end

    it 'creates a new broadcast message dismissal' do
      expect { execute }.to change { Users::BroadcastMessageDismissal.count }.by(1)
    end

    it 'returns a service response' do
      expect(execute).to be_an_instance_of(ServiceResponse)
    end

    context 'when dismissal already exists', :freeze_time do
      let(:old_time) { 2.days.ago }
      let(:new_time) { 1.week.from_now }

      let(:existing_dismissal) do
        create(:broadcast_message_dismissal, broadcast_message: broadcast_message, user: user,
          expires_at: old_time)
      end

      let(:params) { { broadcast_message_id: broadcast_message.id, expires_at: new_time } }

      it 'updates existing dismissal expires_at time' do
        expect { execute }.to change { existing_dismissal.reload.expires_at }.from(old_time).to(new_time)
      end
    end

    it 'does not update an invalid record with expires_at time', :aggregate_failures do
      service_response = described_class.new(
        current_user: user, params: { broadcast_message_id: nil, expires_at: 2.days.from_now }
      ).execute

      expect(service_response).to be_error
    end
  end
end
