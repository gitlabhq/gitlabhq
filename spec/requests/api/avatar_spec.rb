# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Avatar, feature_category: :user_profile do
  let(:gravatar_service) { double('GravatarService') }

  describe 'GET /avatar' do
    context 'avatar uploaded to GitLab' do
      context 'user with matching public email address' do
        let(:user) { create(:user, :with_avatar, email: 'public@example.com', public_email: 'public@example.com') }

        before do
          user
        end

        it 'returns the avatar url' do
          get api('/avatar'), params: { email: 'public@example.com' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['avatar_url']).to eql("#{::Settings.gitlab.base_url}#{user.avatar.local_url}")
          is_expected.to have_request_urgency(:medium)
        end
      end

      context 'no user with matching public email address' do
        before do
          expect(GravatarService).to receive(:new).and_return(gravatar_service)
          expect(gravatar_service).to(
            receive(:execute)
              .with('private@example.com', nil, 2, { username: nil })
              .and_return('https://gravatar'))
        end

        it 'returns the avatar url from Gravatar' do
          get api('/avatar'), params: { email: 'private@example.com' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['avatar_url']).to eq('https://gravatar')
        end
      end
    end

    context 'avatar uploaded to Gravatar' do
      context 'user with matching public email address' do
        let(:user) { create(:user, email: 'public@example.com', public_email: 'public@example.com') }

        before do
          user

          expect(GravatarService).to receive(:new).and_return(gravatar_service)
          expect(gravatar_service).to(
            receive(:execute)
              .with('public@example.com', nil, 2, { username: user.username })
              .and_return('https://gravatar'))
        end

        it 'returns the avatar url from Gravatar' do
          get api('/avatar'), params: { email: 'public@example.com' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['avatar_url']).to eq('https://gravatar')
        end
      end

      context 'no user with matching public email address' do
        before do
          expect(GravatarService).to receive(:new).and_return(gravatar_service)
          expect(gravatar_service).to(
            receive(:execute)
              .with('private@example.com', nil, 2, { username: nil })
              .and_return('https://gravatar'))
        end

        it 'returns the avatar url from Gravatar' do
          get api('/avatar'), params: { email: 'private@example.com' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['avatar_url']).to eq('https://gravatar')
        end
      end

      context 'public visibility level restricted' do
        let(:user) { create(:user, :with_avatar, email: 'public@example.com', public_email: 'public@example.com') }

        before do
          user

          stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
        end

        context 'when authenticated' do
          it 'returns the avatar url' do
            get api('/avatar', user), params: { email: 'public@example.com' }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['avatar_url']).to eql("#{::Settings.gitlab.base_url}#{user.avatar.local_url}")
          end
        end

        context 'when unauthenticated' do
          it_behaves_like '403 response' do
            let(:request) { get api('/avatar'), params: { email: 'public@example.com' } }
          end
        end
      end
    end
  end
end
