# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Broadcast Message Dismissals', feature_category: :notifications do
  let_it_be(:user) { create(:user) }
  let_it_be(:broadcast_message) { create(:broadcast_message) }

  before do
    sign_in(user)
  end

  describe 'POST /-/users/broadcast_message_dismissals' do
    let(:params) { { broadcast_message_id: broadcast_message.id, expires_at: 1.day.from_now } }

    subject(:request) do
      post broadcast_message_dismissals_path, params: params, headers: { 'ACCEPT' => 'application/json' }
    end

    context 'with valid broadcast message id' do
      context 'when dismissal entry does not exist' do
        it 'creates a dismissal entry' do
          expect { request }.to change { Users::BroadcastMessageDismissal.count }.by(1)
        end

        it 'returns success' do
          request

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when dismissal entry already exists' do
        let!(:broadcast_message_dismissal) do
          create(:broadcast_message_dismissal, user: user, broadcast_message: broadcast_message)
        end

        it 'returns success', :aggregate_failures do
          expect { request }.not_to change { Users::BroadcastMessageDismissal.count }
          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'with invalid broadcast message id' do
      let(:params) { { broadcast_message_id: 'wrong', expires_at: 1.day.from_now } }

      it 'returns bad request' do
        request

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end
end
