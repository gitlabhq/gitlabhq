require 'spec_helper'

describe API::ProtectedBranches do
  let(:user) { create(:user) }
  let!(:project) { create(:project, :repository) }
  let(:protected_name) { 'feature' }
  let(:branch_name) { protected_name }
  let!(:protected_branch) do
    create(:protected_branch, project: project, name: protected_name)
  end

  describe "GET /projects/:id/protected_branches" do
    let(:route) { "/projects/#{project.id}/protected_branches" }

    shared_examples_for 'protected branches' do
      it 'returns the protected branches' do
        get api(route, user), per_page: 100

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array

        protected_branch_names = json_response.map { |x| x['name'] }
        expected_branch_names = project.protected_branches.map { |x| x['name'] }
        expect(protected_branch_names).to match_array(expected_branch_names)
      end
    end

    context 'when authenticated as a master' do
      before do
        project.add_master(user)
      end

      it_behaves_like 'protected branches'
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

  describe "GET /projects/:id/protected_branches/:branch" do
    let(:route) { "/projects/#{project.id}/protected_branches/#{branch_name}" }

    shared_examples_for 'protected branch' do
      it 'returns the protected branch' do
        get api(route, user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(::Gitlab::Access::MASTER)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(::Gitlab::Access::MASTER)
        expect(json_response['unprotect_access_levels']).to eq([])
      end

      context 'when protected branch does not exist' do
        let(:branch_name) { 'unknown' }

        it_behaves_like '404 response' do
          let(:request) { get api(route, user) }
          let(:message) { '404 Not found' }
        end
      end

      context 'with per user/group access levels' do
        let(:push_user) { create(:user) }
        let(:merge_group) { create(:group) }
        let(:unprotect_group) { create(:group) }

        before do
          protected_branch.push_access_levels.create!(user: push_user)
          protected_branch.merge_access_levels.create!(group: merge_group)
          protected_branch.unprotect_access_levels.create!(group: unprotect_group)
        end

        it 'returns access level details' do
          get api(route, user)

          push_user_ids = json_response['push_access_levels'].map {|level| level['user_id']}
          merge_group_ids = json_response['merge_access_levels'].map {|level| level['group_id']}
          unprotect_group_ids = json_response['unprotect_access_levels'].map {|level| level['group_id']}

          expect(response).to have_gitlab_http_status(200)
          expect(push_user_ids).to include(push_user.id)
          expect(merge_group_ids).to include(merge_group.id)
          expect(unprotect_group_ids).to include(unprotect_group.id)
        end
      end
    end

    context 'when authenticated as a master' do
      before do
        project.add_master(user)
      end

      it_behaves_like 'protected branch'

      context 'when protected branch contains a wildcard' do
        let(:protected_name) { 'feature*' }

        it_behaves_like 'protected branch'
      end

      context 'when protected branch contains a period' do
        let(:protected_name) { 'my.feature' }

        it_behaves_like 'protected branch'
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

  describe 'POST /projects/:id/protected_branches' do
    let(:branch_name) { 'new_branch' }
    let(:post_endpoint) { api("/projects/#{project.id}/protected_branches", user) }

    def expect_protection_to_be_successful
      expect(response).to have_gitlab_http_status(201)
      expect(json_response['name']).to eq(branch_name)
    end

    context 'when authenticated as a master' do
      before do
        project.add_master(user)
      end

      it 'protects a single branch' do
        post post_endpoint, name: branch_name

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::MASTER)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::MASTER)
        expect(json_response['unprotect_access_levels'][0]['access_level']).to eq(Gitlab::Access::MASTER)
      end

      it 'protects a single branch and developers can push' do
        post post_endpoint, name: branch_name, push_access_level: 30

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::DEVELOPER)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::MASTER)
      end

      it 'protects a single branch and developers can merge' do
        post post_endpoint, name: branch_name, merge_access_level: 30

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::MASTER)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::DEVELOPER)
      end

      it 'protects a single branch and developers can push and merge' do
        post post_endpoint, name: branch_name, push_access_level: 30, merge_access_level: 30

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::DEVELOPER)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::DEVELOPER)
      end

      it 'protects a single branch and no one can push' do
        post post_endpoint, name: branch_name, push_access_level: 0

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::NO_ACCESS)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::MASTER)
      end

      it 'protects a single branch and no one can merge' do
        post post_endpoint, name: branch_name, merge_access_level: 0

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::MASTER)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::NO_ACCESS)
      end

      it 'protects a single branch and only admins can unprotect' do
        post post_endpoint, name: branch_name, unprotect_access_level: Gitlab::Access::ADMIN

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::MASTER)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::MASTER)
        expect(json_response['unprotect_access_levels'][0]['access_level']).to eq(Gitlab::Access::ADMIN)
      end

      it 'protects a single branch and no one can push or merge' do
        post post_endpoint, name: branch_name, push_access_level: 0, merge_access_level: 0

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::NO_ACCESS)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::NO_ACCESS)
      end

      context 'with granular access' do
        let(:invited_group) do
          create(:project_group_link, project: project).group
        end

        let(:project_member) do
          create(:project_member, project: project).user
        end

        it 'can protect a branch while allowing an individual user to push' do
          push_user = project_member

          post post_endpoint, name: branch_name, allowed_to_push: [{ user_id: push_user.id }]

          expect_protection_to_be_successful
          expect(json_response['push_access_levels'][0]['user_id']).to eq(push_user.id)
        end

        it 'can protect a branch while allowing an individual user to merge' do
          merge_user = project_member

          post post_endpoint, name: branch_name, allowed_to_merge: [{ user_id: merge_user.id }]

          expect_protection_to_be_successful
          expect(json_response['merge_access_levels'][0]['user_id']).to eq(merge_user.id)
        end

        it 'can protect a branch while allowing an individual user to unprotect' do
          unprotect_user = project_member

          post post_endpoint, name: branch_name, allowed_to_unprotect: [{ user_id: unprotect_user.id }]

          expect_protection_to_be_successful
          expect(json_response['unprotect_access_levels'][0]['user_id']).to eq(unprotect_user.id)
        end

        it 'can protect a branch while allowing a group to push' do
          push_group = invited_group

          post post_endpoint, name: branch_name, allowed_to_push: [{ group_id: push_group.id }]

          expect_protection_to_be_successful
          expect(json_response['push_access_levels'][0]['group_id']).to eq(push_group.id)
        end

        it 'can protect a branch while allowing a group to merge' do
          merge_group = invited_group

          post post_endpoint, name: branch_name, allowed_to_merge: [{ group_id: merge_group.id }]

          expect_protection_to_be_successful
          expect(json_response['merge_access_levels'][0]['group_id']).to eq(merge_group.id)
        end

        it 'can protect a branch while allowing a group to unprotect' do
          unprotect_group = invited_group

          post post_endpoint, name: branch_name, allowed_to_unprotect: [{ group_id: unprotect_group.id }]

          expect_protection_to_be_successful
          expect(json_response['unprotect_access_levels'][0]['group_id']).to eq(unprotect_group.id)
        end

        it "fails if users don't all have access to the project" do
          push_user = create(:user)

          post post_endpoint, name: branch_name, allowed_to_merge: [{ user_id: push_user.id }]

          expect(response).to have_gitlab_http_status(422)
          expect(json_response['message'][0]).to match(/Cannot add users or groups/)
        end

        it "fails if groups aren't all invited to the project" do
          merge_group = create(:group)

          post post_endpoint, name: branch_name, allowed_to_merge: [{ group_id: merge_group.id }]

          expect(response).to have_gitlab_http_status(422)
          expect(json_response['message'][0]).to match(/Cannot add users or groups/)
        end

        it 'avoids creating default access levels unless necessary' do
          push_user = project_member

          post post_endpoint, name: branch_name, allowed_to_push: [{ user_id: push_user.id }]

          expect(response).to have_gitlab_http_status(201)
          expect(json_response['push_access_levels'].count).to eq(1)
          expect(json_response['merge_access_levels'].count).to eq(1)
          expect(json_response['push_access_levels'][0]['user_id']).to eq(push_user.id)
          expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::MASTER)
        end
      end

      it 'returns a 409 error if the same branch is protected twice' do
        post post_endpoint, name: protected_name

        expect(response).to have_gitlab_http_status(409)
      end

      context 'when branch has a wildcard in its name' do
        let(:branch_name) { 'feature/*' }

        it "protects multiple branches with a wildcard in the name" do
          post post_endpoint, name: branch_name

          expect_protection_to_be_successful
          expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::MASTER)
          expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::MASTER)
        end
      end

      context 'when a policy restricts rule deletion' do
        before do
          policy = instance_double(ProtectedBranchPolicy, can?: false)
          expect(ProtectedBranchPolicy).to receive(:new).and_return(policy)
        end

        it "prevents deletion of the protected branch rule" do
          post post_endpoint, name: branch_name

          expect(response).to have_gitlab_http_status(403)
        end
      end
    end

    context 'when authenticated as a guest' do
      before do
        project.add_guest(user)
      end

      it "returns a 403 error if guest" do
        post post_endpoint, name: branch_name

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end

  describe "DELETE /projects/:id/protected_branches/unprotect/:branch" do
    let(:delete_endpoint) { api("/projects/#{project.id}/protected_branches/#{branch_name}", user) }

    before do
      project.add_master(user)
    end

    it "unprotects a single branch" do
      delete delete_endpoint

      expect(response).to have_gitlab_http_status(204)
    end

    it_behaves_like '412 response' do
      let(:request) { delete_endpoint }
    end

    it "returns 404 if branch does not exist" do
      delete api("/projects/#{project.id}/protected_branches/barfoo", user)

      expect(response).to have_gitlab_http_status(404)
    end

    context 'when a policy restricts rule deletion' do
      before do
        policy = instance_double(ProtectedBranchPolicy, can?: false)
        expect(ProtectedBranchPolicy).to receive(:new).and_return(policy)
      end

      it "prevents deletion of the protected branch rule" do
        delete delete_endpoint

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'when branch has a wildcard in its name' do
      let(:protected_name) { 'feature*' }

      it "unprotects a wildcard branch" do
        delete delete_endpoint

        expect(response).to have_gitlab_http_status(204)
      end
    end
  end
end
