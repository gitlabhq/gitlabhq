# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProtectedBranches, feature_category: :source_code_management do
  let_it_be_with_reload(:project) { create(:project, :repository) }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:guest) { create(:user, guest_of: project) }

  let(:protected_name) { 'feature' }
  let(:branch_name) { protected_name }

  let!(:protected_branch) do
    create(:protected_branch, project: project, name: protected_name)
  end

  describe "GET /projects/:id/protected_branches" do
    let(:params) { {} }
    let(:route) { "/projects/#{project.id}/protected_branches" }
    let(:expected_branch_names) { project.protected_branches.map { |x| x['name'] } }

    shared_examples_for 'protected branches' do
      it 'returns the protected branches' do
        get api(route, user), params: params.merge(per_page: 100)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(response).to match_response_schema('protected_branches')
        protected_branch_names = json_response.map { |x| x['name'] }
        expect(protected_branch_names).to match_array(expected_branch_names)
      end
    end

    context 'when authenticated as a maintainer' do
      let(:user) { maintainer }

      context 'when search param is not present' do
        it_behaves_like 'protected branches'
      end

      context 'when search param is present' do
        it_behaves_like 'protected branches' do
          let(:another_protected_branch) { create(:protected_branch, project: project, name: 'stable') }
          let(:params) { { search: another_protected_branch.name } }
          let(:expected_branch_names) { [another_protected_branch.name] }
        end
      end
    end

    context 'when authenticated as a developer' do
      let(:user) { developer }

      it_behaves_like 'protected branches'
    end

    context 'when authenticated as a guest' do
      let(:user) { guest }

      it_behaves_like '403 response' do
        let(:request) { get api(route, user) }
      end
    end
  end

  describe "GET /projects/:id/protected_branches/:branch" do
    let(:route) { "/projects/#{project.id}/protected_branches/#{branch_name}" }

    shared_examples_for 'protected branch' do
      it 'returns the protected branch' do
        get api(route, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('protected_branch')
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['allow_force_push']).to eq(false)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(::Gitlab::Access::MAINTAINER)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(::Gitlab::Access::MAINTAINER)
      end

      context 'when protected branch does not exist' do
        let(:branch_name) { 'unknown' }

        it_behaves_like '404 response' do
          let(:request) { get api(route, user) }
          let(:message) { '404 Not found' }
        end
      end
    end

    context 'when authenticated as a maintainer' do
      let(:user) { maintainer }

      it_behaves_like 'protected branch'

      context 'when protected branch contains a wildcard' do
        let(:protected_name) { 'feature*' }

        it_behaves_like 'protected branch'
      end

      context 'when protected branch contains a period' do
        let(:protected_name) { 'my.feature' }

        it_behaves_like 'protected branch'
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
          create(:protected_branch_push_access_level, protected_branch: protected_branch, deploy_key: deploy_key)
          get api(route, user)

          expect(json_response['push_access_levels']).to include(
            a_hash_including('access_level_description' => deploy_key.title, 'deploy_key_id' => deploy_key.id)
          )
        end
      end

      context 'when a deploy key is not present' do
        it 'returns null deploy key field' do
          create(:protected_branch_push_access_level, protected_branch: protected_branch)
          get api(route, user)

          expect(json_response['push_access_levels']).to include(
            a_hash_including('deploy_key_id' => nil)
          )
        end
      end
    end

    context 'when authenticated as a developer' do
      let(:user) { developer }

      it_behaves_like 'protected branch'
    end

    context 'when authenticated as a guest' do
      let(:user) { guest }

      it_behaves_like '403 response' do
        let(:request) { get api(route, user) }
      end
    end
  end

  describe 'POST /projects/:id/protected_branches' do
    let(:branch_name) { 'new_branch' }
    let(:post_endpoint) { api("/projects/#{project.id}/protected_branches", user) }

    def expect_protection_to_be_successful
      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['name']).to eq(branch_name)
    end

    context 'when authenticated as a maintainer' do
      let(:user) { maintainer }

      it 'protects a single branch' do
        post post_endpoint, params: { name: branch_name }

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('protected_branch')
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['allow_force_push']).to eq(false)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::MAINTAINER)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::MAINTAINER)
      end

      it 'protects a single branch and developers can push' do
        post post_endpoint, params: { name: branch_name, push_access_level: 30 }

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('protected_branch')
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['allow_force_push']).to eq(false)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::DEVELOPER)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::MAINTAINER)
      end

      it 'protects a single branch and developers can merge' do
        post post_endpoint, params: { name: branch_name, merge_access_level: 30 }

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('protected_branch')
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['allow_force_push']).to eq(false)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::MAINTAINER)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::DEVELOPER)
      end

      it 'protects a single branch and developers can push and merge' do
        post post_endpoint, params: { name: branch_name, push_access_level: 30, merge_access_level: 30 }

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('protected_branch')
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['allow_force_push']).to eq(false)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::DEVELOPER)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::DEVELOPER)
      end

      it 'protects a single branch and no one can push' do
        post post_endpoint, params: { name: branch_name, push_access_level: 0 }

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('protected_branch')
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['allow_force_push']).to eq(false)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::NO_ACCESS)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::MAINTAINER)
      end

      it 'protects a single branch and no one can merge' do
        post post_endpoint, params: { name: branch_name, merge_access_level: 0 }

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('protected_branch')
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['allow_force_push']).to eq(false)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::MAINTAINER)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::NO_ACCESS)
      end

      it 'protects a single branch and no one can push or merge' do
        post post_endpoint, params: { name: branch_name, push_access_level: 0, merge_access_level: 0 }

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('protected_branch')
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['allow_force_push']).to eq(false)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::NO_ACCESS)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::NO_ACCESS)
      end

      it 'protects a single branch and allows force pushes' do
        post post_endpoint, params: { name: branch_name, allow_force_push: true }

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('protected_branch')
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['allow_force_push']).to eq(true)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::MAINTAINER)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::MAINTAINER)
      end

      it 'returns a 409 error if the same branch is protected twice' do
        post post_endpoint, params: { name: protected_name }

        expect(response).to have_gitlab_http_status(:conflict)
      end

      context 'when branch has a wildcard in its name' do
        let(:branch_name) { 'feature/*' }

        it "protects multiple branches with a wildcard in the name" do
          post post_endpoint, params: { name: branch_name }

          expect_protection_to_be_successful
          expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::MAINTAINER)
          expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::MAINTAINER)
        end
      end

      context 'when a policy restricts rule creation' do
        it "prevents creations of the protected branch rule" do
          disallow(:create_protected_branch, an_instance_of(ProtectedBranch))

          post post_endpoint, params: { name: branch_name }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when authenticated as a developer' do
      let(:user) { developer }

      it "returns a 403 error" do
        post post_endpoint, params: { name: branch_name }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated as a guest' do
      let(:user) { guest }

      it "returns a 403 error" do
        post post_endpoint, params: { name: branch_name }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'PATCH /projects/:id/protected_branches/:name' do
    let(:route) { "/projects/#{project.id}/protected_branches/#{branch_name}" }

    context 'when authenticated as a maintainer' do
      let(:user) { maintainer }

      it "updates a single branch" do
        expect do
          patch api(route, user), params: { allow_force_push: true }
        end.to change { protected_branch.reload.allow_force_push }.from(false).to(true)
        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'when allow_force_push is not set' do
        it 'responds with a bad request error' do
          patch api(route, user), params: { allow_force_push: nil }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to eq 'allow_force_push is empty'
        end
      end
    end

    context 'when returned protected branch is invalid' do
      let(:user) { maintainer }

      before do
        allow_next_found_instance_of(ProtectedBranch) do |instance|
          allow(instance).to receive(:valid?).and_return(false)
        end
      end

      it "returns a 422" do
        expect do
          patch api(route, user), params: { allow_force_push: true }
        end.not_to change { protected_branch.reload.allow_force_push }

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    context 'when authenticated as a developer' do
      let(:user) { developer }

      it "returns a 403 error" do
        patch api(route, user), params: { allow_force_push: true }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated as a guest' do
      let(:user) { guest }

      it "returns a 403 error" do
        patch api(route, user), params: { allow_force_push: true }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe "DELETE /projects/:id/protected_branches/unprotect/:branch" do
    let(:delete_endpoint) { api("/projects/#{project.id}/protected_branches/#{branch_name}", user) }

    context "when authenticated as a maintainer" do
      let(:user) { maintainer }

      it "unprotects a single branch" do
        delete delete_endpoint

        expect(response).to have_gitlab_http_status(:no_content)
      end

      it_behaves_like '412 response' do
        let(:request) { delete_endpoint }
      end

      it "returns 404 if branch does not exist" do
        delete api("/projects/#{project.id}/protected_branches/barfoo", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when a policy restricts rule deletion' do
        it "prevents deletion of the protected branch rule" do
          disallow(:destroy_protected_branch, protected_branch)

          delete delete_endpoint

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when branch has a wildcard in its name' do
        let(:protected_name) { 'feature*' }

        it "unprotects a wildcard branch" do
          delete delete_endpoint

          expect(response).to have_gitlab_http_status(:no_content)
        end
      end
    end

    context 'when authenticated as a developer' do
      let(:user) { developer }

      it "returns a 403 error" do
        delete delete_endpoint

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated as a guest' do
      let(:user) { guest }

      it "returns a 403 error" do
        delete delete_endpoint

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  def disallow(ability, protected_branch)
    allow(Ability).to receive(:allowed?).and_call_original
    allow(Ability).to receive(:allowed?).with(user, ability, protected_branch).and_return(false)
  end
end
