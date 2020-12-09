# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::BroadcastMessages do
  let_it_be(:user)  { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:message) { create(:broadcast_message) }

  describe 'GET /broadcast_messages' do
    it 'returns an Array of BroadcastMessages' do
      create(:broadcast_message)

      get api('/broadcast_messages')

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_kind_of(Array)
      expect(json_response.first.keys)
        .to match_array(%w(id message starts_at ends_at color font active target_path broadcast_type dismissable))
    end
  end

  describe 'GET /broadcast_messages/:id' do
    it 'returns the specified message' do
      get api("/broadcast_messages/#{message.id}")

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['id']).to eq message.id
      expect(json_response.keys)
        .to match_array(%w(id message starts_at ends_at color font active target_path broadcast_type dismissable))
    end
  end

  describe 'POST /broadcast_messages' do
    it 'returns a 401 for anonymous users' do
      post api('/broadcast_messages'), params: attributes_for(:broadcast_message)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns a 403 for users' do
      post api('/broadcast_messages', user), params: attributes_for(:broadcast_message)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    context 'as an admin' do
      it 'requires the `message` parameter' do
        attrs = attributes_for(:broadcast_message)
        attrs.delete(:message)

        post api('/broadcast_messages', admin), params: attrs

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq 'message is missing'
      end

      it 'defines sane default start and end times' do
        time = Time.zone.parse('2016-07-02 10:11:12')
        travel_to(time) do
          post api('/broadcast_messages', admin), params: { message: 'Test message' }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['starts_at']).to eq '2016-07-02T10:11:12.000Z'
          expect(json_response['ends_at']).to   eq '2016-07-02T11:11:12.000Z'
        end
      end

      it 'accepts a custom background and foreground color' do
        attrs = attributes_for(:broadcast_message, color: '#000000', font: '#cecece')

        post api('/broadcast_messages', admin), params: attrs

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['color']).to eq attrs[:color]
        expect(json_response['font']).to eq attrs[:font]
      end

      it 'accepts a target path' do
        attrs = attributes_for(:broadcast_message, target_path: "*/welcome")

        post api('/broadcast_messages', admin), params: attrs

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['target_path']).to eq attrs[:target_path]
      end

      it 'accepts a broadcast type' do
        attrs = attributes_for(:broadcast_message, broadcast_type: 'notification')

        post api('/broadcast_messages', admin), params: attrs

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['broadcast_type']).to eq attrs[:broadcast_type]
      end

      it 'uses default broadcast type' do
        attrs = attributes_for(:broadcast_message)

        post api('/broadcast_messages', admin), params: attrs

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['broadcast_type']).to eq 'banner'
      end

      it 'errors for invalid broadcast type' do
        attrs = attributes_for(:broadcast_message, broadcast_type: 'invalid-type')

        post api('/broadcast_messages', admin), params: attrs

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'accepts an active dismissable value' do
        attrs = { message: 'new message', dismissable: true }

        post api('/broadcast_messages', admin), params: attrs

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['dismissable']).to eq true
      end
    end
  end

  describe 'PUT /broadcast_messages/:id' do
    it 'returns a 401 for anonymous users' do
      put api("/broadcast_messages/#{message.id}"),
        params: attributes_for(:broadcast_message)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns a 403 for users' do
      put api("/broadcast_messages/#{message.id}", user),
        params: attributes_for(:broadcast_message)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    context 'as an admin' do
      it 'accepts new background and foreground colors' do
        attrs = { color: '#000000', font: '#cecece' }

        put api("/broadcast_messages/#{message.id}", admin), params: attrs

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['color']).to eq attrs[:color]
        expect(json_response['font']).to eq attrs[:font]
      end

      it 'accepts new start and end times' do
        time = Time.zone.parse('2016-07-02 10:11:12')
        travel_to(time) do
          attrs = { starts_at: Time.zone.now, ends_at: 3.hours.from_now }

          put api("/broadcast_messages/#{message.id}", admin), params: attrs

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['starts_at']).to eq '2016-07-02T10:11:12.000Z'
          expect(json_response['ends_at']).to   eq '2016-07-02T13:11:12.000Z'
        end
      end

      it 'accepts a new message' do
        attrs = { message: 'new message' }

        put api("/broadcast_messages/#{message.id}", admin), params: attrs

        expect(response).to have_gitlab_http_status(:ok)
        expect { message.reload }.to change { message.message }.to('new message')
      end

      it 'accepts a new target_path' do
        attrs = { target_path: '*/welcome' }

        put api("/broadcast_messages/#{message.id}", admin), params: attrs

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['target_path']).to eq attrs[:target_path]
      end

      it 'accepts a new broadcast_type' do
        attrs = { broadcast_type: 'notification' }

        put api("/broadcast_messages/#{message.id}", admin), params: attrs

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['broadcast_type']).to eq attrs[:broadcast_type]
      end

      it 'errors for invalid broadcast type' do
        attrs = { broadcast_type: 'invalid-type' }

        put api("/broadcast_messages/#{message.id}", admin), params: attrs

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'accepts a new dismissable value' do
        attrs = { message: 'new message', dismissable: true }

        put api("/broadcast_messages/#{message.id}", admin), params: attrs

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['dismissable']).to eq true
      end
    end
  end

  describe 'DELETE /broadcast_messages/:id' do
    it 'returns a 401 for anonymous users' do
      delete api("/broadcast_messages/#{message.id}"),
        params: attributes_for(:broadcast_message)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns a 403 for users' do
      delete api("/broadcast_messages/#{message.id}", user),
        params: attributes_for(:broadcast_message)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it_behaves_like '412 response' do
      let(:request) { api("/broadcast_messages/#{message.id}", admin) }
    end

    it 'deletes the broadcast message for admins' do
      expect do
        delete api("/broadcast_messages/#{message.id}", admin)

        expect(response).to have_gitlab_http_status(:no_content)
      end.to change { BroadcastMessage.count }.by(-1)
    end
  end
end
