# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GroupAvatar do
  def avatar_path(group)
    "/groups/#{ERB::Util.url_encode(group.full_path)}/avatar"
  end

  describe 'GET /groups/:id/avatar' do
    context 'when the group is public' do
      let(:group) { create(:group, :public, :with_avatar) }

      it 'retrieves the avatar successfully' do
        get api(avatar_path(group))

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers['Content-Disposition'])
          .to eq(%(attachment; filename="dk.png"; filename*=UTF-8''dk.png))
      end

      context 'when the avatar is in the object storage' do
        before do
          stub_uploads_object_storage(AvatarUploader)

          group.avatar.migrate!(ObjectStorage::Store::REMOTE)
        end

        it 'redirects to the file in the object storage' do
          get api(avatar_path(group))

          expect(response).to have_gitlab_http_status(:found)
          expect(response.headers['Content-Disposition'])
            .to eq(%(attachment; filename="dk.png"; filename*=UTF-8''dk.png))
        end
      end

      context 'when the group does not have avatar' do
        it 'returns :not_found' do
          group = create(:group, :public)

          get api(avatar_path(group))

          expect(response).to have_gitlab_http_status(:not_found)
          expect(response.body)
            .to eq(%({"message":"404 Avatar Not Found"}))
        end
      end

      context 'when the group is a subgroup' do
        it 'returns :ok' do
          group = create(:group, :nested, :public, :with_avatar, name: 'g1.1')

          get api(avatar_path(group))

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'when the group is private' do
      let(:group) { create(:group, :private, :with_avatar) }

      context 'when the user is not authenticated' do
        it 'returns :not_found' do
          get api(avatar_path(group))

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when the the group user is authenticated' do
        context 'and have access to the group' do
          it 'retrieves the avatar successfully' do
            owner = create(:user)
            group.add_owner(owner)

            get api(avatar_path(group), owner)

            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context 'and does not have access to the group' do
          it 'returns :not_found' do
            get api(avatar_path(group), create(:user))

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end
  end
end
