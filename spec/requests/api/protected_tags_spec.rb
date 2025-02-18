# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProtectedTags, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:project2) { create(:project, path: 'project2', namespace: user.namespace) }

  let(:protected_name) { 'feature' }
  let(:tag_name) { protected_name }
  let!(:protected_tag) do
    create(:protected_tag, project: project, name: protected_name)
  end

  describe 'GET /projects/:id/protected_tags' do
    let(:route) { "/projects/#{project.id}/protected_tags" }

    shared_examples_for 'protected tags' do
      it 'returns the Protected Tags' do
        get api(route, user), params: { per_page: 100 }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(response).to match_response_schema('protected_tags')

        protected_tag_names = json_response.map { |x| x['name'] }
        expected_tags_names = project.protected_tags.map { |x| x['name'] }
        expect(protected_tag_names).to match_array(expected_tags_names)
      end
    end

    context 'when authenticated as a maintainer' do
      before do
        project.add_maintainer(user)
      end

      it_behaves_like 'protected tags'
    end

    context 'when authenticated as a guest' do
      before do
        project.add_guest(user)
      end

      it_behaves_like '403 response' do
        let(:request) { get api(route, user) }
      end
    end
  end

  describe 'GET /projects/:id/protected_tags/:tag' do
    let(:route) { "/projects/#{project.id}/protected_tags/#{tag_name}" }

    shared_examples_for 'protected tag' do
      it 'returns the Protected Tag' do
        get api(route, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('protected_tag')
        expect(json_response['name']).to eq(tag_name)
        expect(json_response['create_access_levels'][0]['access_level']).to eq(::Gitlab::Access::MAINTAINER)
      end

      context 'when the Protected Tag does not exist' do
        let(:tag_name) { 'unknown' }

        it_behaves_like '404 response' do
          let(:request) { get api(route, user) }
          let(:message) { '404 Not found' }
        end
      end
    end

    context 'when authenticated as a maintainer' do
      before do
        project.add_maintainer(user)
      end

      it_behaves_like 'protected tag'

      context 'when the Protected Tag contains a wildcard' do
        let(:protected_name) { 'feature*' }

        it_behaves_like 'protected tag'
      end

      context 'when a deploy key is present' do
        let(:deploy_key) do
          create(
            :deploy_keys_project,
            :write_access,
            project: project,
            deploy_key: create(:deploy_key, user: user)
          ).deploy_key
        end

        it 'returns deploy key information' do
          create(:protected_tag_create_access_level, protected_tag: protected_tag, deploy_key: deploy_key)
          get api(route, user)

          expect(json_response['create_access_levels']).to include(
            a_hash_including('access_level_description' => deploy_key.title, 'deploy_key_id' => deploy_key.id)
          )
        end
      end

      context 'when a deploy key is not present' do
        it 'returns null deploy key field' do
          create(:protected_tag_create_access_level, protected_tag: protected_tag)
          get api(route, user)

          expect(json_response['create_access_levels']).to include(
            a_hash_including('deploy_key_id' => nil)
          )
        end
      end
    end

    context 'when authenticated as a guest' do
      before do
        project.add_guest(user)
      end

      it_behaves_like '403 response' do
        let(:request) { get api(route, user) }
      end
    end
  end

  describe 'POST /projects/:id/protected_tags' do
    let(:tag_name) { 'new_tag' }

    context 'when authenticated as a maintainer' do
      before do
        project.add_maintainer(user)
      end

      it 'protects a single tag with maintainers can create tags' do
        post api("/projects/#{project.id}/protected_tags", user), params: { name: tag_name }

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('protected_tag')
        expect(json_response['name']).to eq(tag_name)
        expect(json_response['create_access_levels'][0]['access_level']).to eq(Gitlab::Access::MAINTAINER)
      end

      it 'protects a single tag with developers can create tags' do
        post api("/projects/#{project.id}/protected_tags", user),
          params: { name: tag_name, create_access_level: 30 }

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('protected_tag')
        expect(json_response['name']).to eq(tag_name)
        expect(json_response['create_access_levels'][0]['access_level']).to eq(Gitlab::Access::DEVELOPER)
      end

      it 'protects a single tag with no one can create tags' do
        post api("/projects/#{project.id}/protected_tags", user),
          params: { name: tag_name, create_access_level: 0 }

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('protected_tag')
        expect(json_response['name']).to eq(tag_name)
        expect(json_response['create_access_levels'][0]['access_level']).to eq(Gitlab::Access::NO_ACCESS)
      end

      it 'returns a 422 error if the same tag is protected twice' do
        post api("/projects/#{project.id}/protected_tags", user), params: { name: protected_name }

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response['message'][0]).to eq('Name has already been taken')
      end

      it 'returns 201 if the same tag is proteted on different projects' do
        post api("/projects/#{project.id}/protected_tags", user), params: { name: protected_name }
        post api("/projects/#{project2.id}/protected_tags", user), params: { name: protected_name }

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('protected_tag')
        expect(json_response['name']).to eq(protected_name)
      end

      context 'when the Protected Tag has a wildcard in its name' do
        let(:tag_name) { 'feature/*' }

        it 'protects multiple tags with a wildcard in the name' do
          post api("/projects/#{project.id}/protected_tags", user), params: { name: tag_name }

          expect(response).to have_gitlab_http_status(:created)
          expect(response).to match_response_schema('protected_tag')
          expect(json_response['name']).to eq(tag_name)
          expect(json_response['create_access_levels'][0]['access_level']).to eq(Gitlab::Access::MAINTAINER)
        end
      end
    end

    context 'when authenticated as a guest' do
      before do
        project.add_guest(user)
      end

      it 'returns a 403 error if guest' do
        post api("/projects/#{project.id}/protected_tags/", user), params: { name: tag_name }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE /projects/:id/protected_tags/unprotect/:tag' do
    context 'when the user is not a project member' do
      it 'hides the existence of the Protected Tag' do
        delete api("/projects/#{project.id}/protected_tags/#{tag_name}", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the user is a developer' do
      before do
        project.add_developer(user)
      end

      it 'forbids deletion of the Protected Tag' do
        delete api("/projects/#{project.id}/protected_tags/#{tag_name}", user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when the user is a maintainer' do
      before do
        project.add_maintainer(user)
      end

      it 'unprotects a single Protected Tag' do
        delete api("/projects/#{project.id}/protected_tags/#{tag_name}", user)

        expect(response).to have_gitlab_http_status(:no_content)
      end

      it_behaves_like '412 response' do
        let(:request) { api("/projects/#{project.id}/protected_tags/#{tag_name}", user) }
      end

      it "returns 404 if Protected Tag does not exist" do
        delete api("/projects/#{project.id}/protected_tags/barfoo", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when Protected Tag has a wildcard in its name' do
        let(:protected_name) { 'feature*' }

        it 'unprotects a wildcard tag' do
          delete api("/projects/#{project.id}/protected_tags/#{tag_name}", user)

          expect(response).to have_gitlab_http_status(:no_content)
        end
      end
    end
  end
end
