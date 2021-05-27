# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Users do
  let_it_be(:user) { create(:user) }

  describe 'PUT /user/preferences/' do
    context "with correct attributes and a logged in user" do
      it 'returns a success status and the value has been changed' do
        put api("/user/preferences", user), params: {
          view_diffs_file_by_file: true,
          show_whitespace_in_diffs: true
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['view_diffs_file_by_file']).to eq(true)
        expect(json_response['show_whitespace_in_diffs']).to eq(true)

        user.reload

        expect(user.view_diffs_file_by_file).to be_truthy
        expect(user.show_whitespace_in_diffs).to be_truthy
      end
    end

    context "missing a preference" do
      it 'returns a bad request status' do
        put api("/user/preferences", user), params: {}

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context "without a logged in user" do
      it 'returns an unauthorized status' do
        put api("/user/preferences"), params: { view_diffs_file_by_file: true }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context "with an unsupported preference" do
      it 'returns a bad parameter' do
        put api("/user/preferences", user), params: { jawn: true }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context "with an unsupported value" do
      it 'returns a bad parameter' do
        put api("/user/preferences", user), params: { view_diffs_file_by_file: 3 }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context "with an update service failure" do
      it 'returns a bad request' do
        bad_service = double("Failed Service", success?: false)

        allow_next_instance_of(::UserPreferences::UpdateService) do |instance|
          allow(instance).to receive(:execute).and_return(bad_service)
        end

        put api("/user/preferences", user), params: { view_diffs_file_by_file: true }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end
end
