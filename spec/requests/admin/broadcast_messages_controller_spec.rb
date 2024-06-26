# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::BroadcastMessagesController, :enable_admin_mode, feature_category: :notifications do
  let(:broadcast_message) { build(:broadcast_message) }
  let(:broadcast_message_params) { broadcast_message.as_json(root: true, only: [:message, :starts_at, :ends_at]) }

  let_it_be(:invalid_broadcast_message) { { broadcast_message: { message: '' } } }
  let_it_be(:test_message) { 'you owe me a new acorn' }
  let_it_be(:test_preview) { '<p>Hello, world!</p>' }

  before do
    sign_in(create(:admin))
  end

  describe 'GET #index' do
    it 'renders index template' do
      get admin_broadcast_messages_path

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to render_template(:index)
    end
  end

  describe 'POST /preview' do
    it 'renders preview html' do
      post preview_admin_broadcast_messages_path, params: { broadcast_message: { message: "Hello, world!" } }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to eq(test_preview)
    end
  end

  describe 'POST #create' do
    context 'when format json' do
      it 'persists the message and returns ok on success' do
        post admin_broadcast_messages_path(format: :json), params: broadcast_message_params
        expect(response).to have_gitlab_http_status(:ok)
        expect(Gitlab::Json.parse(response.body)['message']).to eq(broadcast_message.message)
      end

      it 'does not persist the message on failure' do
        post admin_broadcast_messages_path(format: :json), params: invalid_broadcast_message
        expect(response).to have_gitlab_http_status(:bad_request)
        expect(Gitlab::Json.parse(response.body)['errors']).to be_present
      end
    end

    context 'when format html' do
      it 'persists the message and redirects to broadcast_messages on success' do
        post admin_broadcast_messages_path(format: :html), params: broadcast_message_params
        expect(response).to redirect_to(admin_broadcast_messages_path)
      end

      it 'does not persist and renders the index page on failure' do
        post admin_broadcast_messages_path(format: :html), params: invalid_broadcast_message
        expect(response.body).to render_template(:index)
      end
    end
  end

  describe 'PATCH #update' do
    context 'when format json' do
      it 'persists the message and returns ok on success' do
        broadcast_message.save!
        patch admin_broadcast_message_path(format: :json, id: broadcast_message.id), params: {
          broadcast_message: { message: test_message }
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(Gitlab::Json.parse(response.body)['message']).to eq(test_message)
      end

      it 'does not persist the message on failure' do
        broadcast_message.message = test_message
        broadcast_message.save!
        patch admin_broadcast_message_path(format: :json, id: broadcast_message.id), params: {
          broadcast_message: { message: '' }
        }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(Gitlab::Json.parse(response.body)['errors']).to be_present
      end
    end

    context 'when format html' do
      it 'persists the message and redirects to broadcast_messages on success' do
        broadcast_message.save!
        patch admin_broadcast_message_path(id: broadcast_message.id), params: {
          broadcast_message: { message: test_message }
        }

        expect(response).to redirect_to(admin_broadcast_messages_path)
      end

      it 'does not persist and renders the edit page on failure' do
        broadcast_message.message = test_message
        broadcast_message.save!
        patch admin_broadcast_message_path(id: broadcast_message.id), params: {
          **invalid_broadcast_message
        }

        expect(response.body).to render_template(:edit)
      end
    end
  end
end
