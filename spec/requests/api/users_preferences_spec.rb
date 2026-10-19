# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Users, feature_category: :user_profile do
  let_it_be(:user) { create(:user) }

  describe 'GET /user/preferences' do
    it 'returns the preferences with the default emoji skin tone' do
      get api("/user/preferences", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['emoji_skin_tone']).to eq('default')
    end

    context "without a logged in user" do
      it 'returns an unauthorized status' do
        get api("/user/preferences")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /user/preferences/' do
    context "with correct attributes and a logged in user" do
      it 'returns a success status and the value has been changed' do
        put api("/user/preferences", user), params: {
          view_diffs_file_by_file: true,
          show_whitespace_in_diffs: true,
          pass_user_identities_to_ci_jwt: true
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['view_diffs_file_by_file']).to be(true)
        expect(json_response['show_whitespace_in_diffs']).to be(true)
        expect(json_response['pass_user_identities_to_ci_jwt']).to be(true)

        user.reload

        expect(user.view_diffs_file_by_file).to be_truthy
        expect(user.show_whitespace_in_diffs).to be_truthy
        expect(user.pass_user_identities_to_ci_jwt).to be_truthy
      end
    end

    context 'with an emoji skin tone' do
      where(:tone) { UserPreference.emoji_skin_tones.keys }

      with_them do
        it 'persists the tone and returns it' do
          put api("/user/preferences", user), params: { emoji_skin_tone: tone }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['emoji_skin_tone']).to eq(tone)
          expect(user.reload.emoji_skin_tone).to eq(tone)
        end
      end
    end

    context 'with an unknown emoji skin tone' do
      it 'returns a bad request naming the attribute' do
        put api("/user/preferences", user), params: { emoji_skin_tone: 'purple' }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('emoji_skin_tone does not have a valid value')
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
