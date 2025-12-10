# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::RunnerControllerTokens, feature_category: :continuous_integration do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:non_admin_user) { create(:user) }
  let_it_be(:runner_controller) { create(:ci_runner_controller) }
  let_it_be(:path) { "/runner_controllers/#{runner_controller.id}/tokens" }
  let_it_be(:token) { create(:ci_runner_controller_token, runner_controller: runner_controller) }

  shared_examples 'returns status 403 (forbidden)' do
    specify do
      call_endpoint

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  shared_examples 'returns status 404 (not found)' do
    specify do
      call_endpoint

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET /runner_controllers/:runner_controller_id/tokens' do
    context 'when user is admin' do
      it 'returns a list of runner controller tokens' do
        create_list(:ci_runner_controller_token, 2, runner_controller: runner_controller)

        get api(path, admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.size).to eq(3)
      end
    end

    context 'when runner controller does not exist' do
      subject(:call_endpoint) do
        get api("/runner_controllers/#{non_existing_record_id}/tokens", admin, admin_mode: true)
      end

      it_behaves_like 'returns status 404 (not found)'
    end

    context 'when user is not admin' do
      subject(:call_endpoint) { get api(path, non_admin_user) }

      it_behaves_like 'returns status 403 (forbidden)'
    end
  end

  describe 'GET /runner_controllers/:runner_controller_id/tokens/:id' do
    context 'when user is admin' do
      it 'returns a single runner controller token' do
        get api("#{path}/#{token.id}", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(token.id)
        expect(json_response['runner_controller_id']).to eq(runner_controller.id)
      end

      context 'when runner controller token does not exist' do
        subject(:call_endpoint) { get api("#{path}/#{non_existing_record_id}", admin, admin_mode: true) }

        it_behaves_like 'returns status 404 (not found)'
      end
    end

    context 'when user is not admin' do
      it 'returns status 403 (forbidden)' do
        get api("#{path}/#{token.id}", non_admin_user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when runner controller does not exist' do
      subject(:call_endpoint) do
        get api("/runner_controllers/#{non_existing_record_id}/tokens/1", admin, admin_mode: true)
      end

      it_behaves_like 'returns status 404 (not found)'
    end
  end

  describe 'POST /runner_controllers/:runner_controller_id/tokens' do
    let(:params) { { description: 'New Token' } }

    context 'when user is admin' do
      it 'creates a new runner controller token' do
        post api(path, admin, admin_mode: true), params: params

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['id']).to be_present
        expect(json_response['runner_controller_id']).to eq(runner_controller.id)
        expect(json_response['token']).to start_with('glrct-')
        expect(json_response['description']).to eq('New Token')
      end

      context 'when token save fails' do
        before do
          allow_next_instance_of(Ci::RunnerControllerToken) do |instance|
            allow(instance).to receive(:save).and_return(false)
            allow(instance).to receive_message_chain(:errors, :full_messages).and_return(['Validation failed'])
          end
        end

        it 'returns 400 with error message' do
          post api(path, admin, admin_mode: true), params: params

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq('400 Bad request - Validation failed')
        end
      end

      context 'when runner controller does not exist' do
        subject(:call_endpoint) do
          post api("/runner_controllers/#{non_existing_record_id}/tokens", admin, admin_mode: true), params: params
        end

        it_behaves_like 'returns status 404 (not found)'
      end
    end

    context 'when user is not admin' do
      it 'returns status 403 (forbidden)' do
        post api(path, non_admin_user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
