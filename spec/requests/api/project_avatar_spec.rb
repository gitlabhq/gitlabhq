# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectAvatar, feature_category: :groups_and_projects do
  def avatar_path(project)
    "/projects/#{ERB::Util.url_encode(project.full_path)}/avatar"
  end

  describe 'GET /projects/:id/avatar' do
    context 'when the project is public' do
      let(:project) { create(:project, :public, :with_avatar) }

      it 'retrieves the avatar successfully' do
        get api(avatar_path(project))

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers['Content-Disposition'])
          .to eq(%(attachment; filename="dk.png"; filename*=UTF-8''dk.png))
      end

      context 'when the avatar is in object storage' do
        before do
          stub_uploads_object_storage(AvatarUploader)

          project.avatar.migrate!(ObjectStorage::Store::REMOTE)
        end

        it 'redirects to the file in object storage' do
          get api(avatar_path(project))

          expect(response).to have_gitlab_http_status(:found)
          expect(response.headers['Content-Disposition'])
            .to eq(%(attachment; filename="dk.png"; filename*=UTF-8''dk.png))
        end
      end

      context 'when the project does not have an avatar' do
        let(:project) { create(:project, :public) }

        it 'returns :not_found' do
          get api(avatar_path(project))

          expect(response).to have_gitlab_http_status(:not_found)
          expect(response.body).to eq(%({"message":"404 Avatar Not Found"}))
        end
      end

      context 'when the project is in a group' do
        let(:project) { create(:project, :in_group, :public, :with_avatar) }

        it 'returns :ok' do
          get api(avatar_path(project))

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when the project is in a subgroup' do
        let(:project) { create(:project, :in_subgroup, :public, :with_avatar) }

        it 'returns :ok' do
          get api(avatar_path(project))

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'when the project is private' do
      let(:project) { create(:project, :private, :with_avatar) }

      context 'when the user is not authenticated' do
        it 'returns :not_found' do
          get api(avatar_path(project))

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when the project user is authenticated' do
        context 'and have access to the project' do
          let(:owner) { create(:user) }

          before do
            project.add_owner(owner)
          end

          it 'retrieves the avatar successfully' do
            get api(avatar_path(project), owner)

            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context 'and does not have access to the project' do
          it 'returns :not_found' do
            get api(avatar_path(project), create(:user))

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end
  end
end
