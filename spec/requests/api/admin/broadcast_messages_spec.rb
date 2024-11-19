# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Admin::BroadcastMessages, :aggregate_failures, feature_category: :notifications do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:message) { create(:broadcast_message) }
  let_it_be(:path) { '/broadcast_messages' }

  describe 'GET /broadcast_messages' do
    it 'returns an Array of BroadcastMessages' do
      create(:broadcast_message)

      get api(path)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_kind_of(Array)
      expect(json_response.first.keys)
        .to match_array(%w[id message starts_at ends_at color font active target_access_levels target_path
          broadcast_type dismissable theme])
    end
  end

  describe 'GET /broadcast_messages/:id' do
    let_it_be(:path) { "#{path}/#{message.id}" }

    it 'returns the specified message' do
      get api(path)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['id']).to eq message.id
      expect(json_response.keys)
        .to match_array(%w[id message starts_at ends_at color font active target_access_levels target_path
          broadcast_type dismissable theme])
    end
  end

  describe 'POST /broadcast_messages' do
    it_behaves_like 'POST request permissions for admin mode' do
      let(:params) { { message: 'Test message' } }
    end

    it 'returns a 401 for anonymous users' do
      post api(path), params: attributes_for(:broadcast_message)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    context 'as an admin' do
      it 'requires the `message` parameter' do
        attrs = attributes_for(:broadcast_message)
        attrs.delete(:message)

        post api(path, admin, admin_mode: true), params: attrs

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq 'message is missing'
      end

      it 'defines sane default start and end times' do
        time = Time.zone.parse('2016-07-02 10:11:12')
        travel_to(time) do
          post api(path, admin, admin_mode: true), params: { message: 'Test message' }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['starts_at']).to eq '2016-07-02T10:11:12.000Z'
          expect(json_response['ends_at']).to   eq '2016-07-02T11:11:12.000Z'
        end
      end

      it 'accepts a custom background and foreground color' do
        attrs = attributes_for(:broadcast_message, color: '#000000', font: '#cecece')

        post api(path, admin, admin_mode: true), params: attrs

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['color']).to eq attrs[:color]
        expect(json_response['font']).to eq attrs[:font]
      end

      it 'accepts target access levels' do
        target_access_levels = [Gitlab::Access::GUEST, Gitlab::Access::DEVELOPER]
        attrs = attributes_for(:broadcast_message, target_access_levels: target_access_levels)

        post api(path, admin, admin_mode: true), params: attrs

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['target_access_levels']).to eq attrs[:target_access_levels]
      end

      it 'accepts a target path' do
        attrs = attributes_for(:broadcast_message, target_path: "*/welcome")

        post api(path, admin, admin_mode: true), params: attrs

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['target_path']).to eq attrs[:target_path]
      end

      it 'accepts a broadcast type' do
        attrs = attributes_for(:broadcast_message, broadcast_type: 'notification')

        post api(path, admin, admin_mode: true), params: attrs

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['broadcast_type']).to eq attrs[:broadcast_type]
      end

      it 'uses default broadcast type' do
        attrs = attributes_for(:broadcast_message)

        post api(path, admin, admin_mode: true), params: attrs

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['broadcast_type']).to eq 'banner'
      end

      it 'errors for invalid broadcast type' do
        attrs = attributes_for(:broadcast_message, broadcast_type: 'invalid-type')

        post api(path, admin, admin_mode: true), params: attrs

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'accepts an active dismissable value' do
        attrs = { message: 'new message', dismissable: true }

        post api(path, admin, admin_mode: true), params: attrs

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['dismissable']).to eq true
      end

      it 'accepts a theme' do
        attrs = { message: 'new message', theme: 'red' }

        post api(path, admin, admin_mode: true), params: attrs

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['theme']).to eq 'red'
      end

      it 'errors for an invalid theme' do
        attrs = attributes_for(:broadcast_message, theme: 'unicorn-rainbow')

        post api(path, admin, admin_mode: true), params: attrs

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      context 'when create does not persist record' do
        let_it_be(:message) { build(:broadcast_message) }.freeze
        let_it_be(:stubbed_errors) { ActiveModel::Errors.new(double).tap { |e| e.add(:base, 'error') } }.freeze

        before do
          allow(System::BroadcastMessage).to receive(:create).and_return(message)
          allow(message).to receive(:errors).and_return(stubbed_errors)
        end

        it 'calls render_validation_error!' do
          post api(path, admin, admin_mode: true), params: { message: 'message' }

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end
    end
  end

  describe 'PUT /broadcast_messages/:id' do
    let_it_be(:path) { "#{path}/#{message.id}" }

    it_behaves_like 'PUT request permissions for admin mode' do
      let(:params) { { message: 'Test message' } }
    end

    it 'returns a 401 for anonymous users' do
      put api(path),
        params: attributes_for(:broadcast_message)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    context 'as an admin' do
      it 'accepts new background and foreground colors' do
        attrs = { color: '#000000', font: '#cecece' }

        put api(path, admin, admin_mode: true), params: attrs

        expect(json_response['color']).to eq attrs[:color]
        expect(json_response['font']).to eq attrs[:font]
      end

      it 'accepts new start and end times' do
        time = Time.zone.parse('2016-07-02 10:11:12')
        travel_to(time) do
          attrs = { starts_at: Time.zone.now, ends_at: 3.hours.from_now }

          put api(path, admin, admin_mode: true), params: attrs

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['starts_at']).to eq '2016-07-02T10:11:12.000Z'
          expect(json_response['ends_at']).to   eq '2016-07-02T13:11:12.000Z'
        end
      end

      it 'accepts a new message' do
        attrs = { message: 'new message' }

        put api(path, admin, admin_mode: true), params: attrs

        expect(response).to have_gitlab_http_status(:ok)
        expect { message.reload }.to change { message.message }.to('new message')
      end

      it 'accepts a new target_access_levels' do
        attrs = { target_access_levels: [Gitlab::Access::MAINTAINER] }

        put api(path, admin, admin_mode: true), params: attrs

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['target_access_levels']).to eq attrs[:target_access_levels]
      end

      it 'accepts a new target_path' do
        attrs = { target_path: '*/welcome' }

        put api(path, admin, admin_mode: true), params: attrs

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['target_path']).to eq attrs[:target_path]
      end

      it 'accepts a new broadcast_type' do
        attrs = { broadcast_type: 'notification' }

        put api(path, admin, admin_mode: true), params: attrs

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['broadcast_type']).to eq attrs[:broadcast_type]
      end

      it 'errors for invalid broadcast type' do
        attrs = { broadcast_type: 'invalid-type' }

        put api(path, admin, admin_mode: true), params: attrs

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'accepts a new dismissable value' do
        attrs = { message: 'new message', dismissable: true }

        put api(path, admin, admin_mode: true), params: attrs

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['dismissable']).to eq true
      end

      it 'accepts a theme' do
        attrs = { message: 'new message', theme: 'red' }

        put api(path, admin, admin_mode: true), params: attrs

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['theme']).to eq 'red'
      end

      it 'errors for an invalid theme' do
        attrs = attributes_for(:broadcast_message, theme: 'unicorn-rainbow')

        put api(path, admin, admin_mode: true), params: attrs

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      context 'when update fails' do
        let_it_be(:message) { build(:broadcast_message) }.freeze
        let_it_be(:stubbed_errors) { ActiveModel::Errors.new(double).tap { |e| e.add(:base, 'error') } }.freeze

        before do
          allow(System::BroadcastMessage).to receive(:find).and_return(message)
          allow(message).to receive(:update).and_return(false)
          allow(message).to receive(:errors).and_return(stubbed_errors)
        end

        it 'calls render_validation_error!' do
          put api(path, admin, admin_mode: true), params: { message: 'message' }

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end
    end
  end

  describe 'DELETE /broadcast_messages/:id' do
    let_it_be(:path) { "#{path}/#{message.id}" }

    it_behaves_like 'DELETE request permissions for admin mode'

    it 'returns a 401 for anonymous users' do
      delete api(path),
        params: attributes_for(:broadcast_message)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it_behaves_like '412 response' do
      let(:request) { api("/broadcast_messages/#{message.id}", admin, admin_mode: true) }
    end

    it 'deletes the broadcast message for admins' do
      expect do
        delete api(path, admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:no_content)
      end.to change { System::BroadcastMessage.count }.by(-1)
    end
  end
end
