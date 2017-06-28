require 'spec_helper'

describe API::V3::BroadcastMessages do
  let(:user)  { create(:user) }
  let(:admin) { create(:admin) }

  describe 'DELETE /broadcast_messages/:id' do
    let!(:message) { create(:broadcast_message) }

    it 'returns a 401 for anonymous users' do
      delete v3_api("/broadcast_messages/#{message.id}"),
        attributes_for(:broadcast_message)

      expect(response).to have_http_status(401)
    end

    it 'returns a 403 for users' do
      delete v3_api("/broadcast_messages/#{message.id}", user),
        attributes_for(:broadcast_message)

      expect(response).to have_http_status(403)
    end

    it 'deletes the broadcast message for admins' do
      expect do
        delete v3_api("/broadcast_messages/#{message.id}", admin)

        expect(response).to have_http_status(200)
      end.to change { BroadcastMessage.count }.by(-1)
    end
  end
end
