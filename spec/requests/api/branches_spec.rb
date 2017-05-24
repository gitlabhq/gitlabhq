require 'spec_helper'
require 'mime/types'

describe API::Branches do
  let(:user) { create(:user) }
  let!(:project) { create(:project, :repository, creator: user) }
  let!(:master) { create(:project_member, :master, user: user, project: project) }
  let(:guest) { create(:user).tap { |u| create(:project_member, :guest, user: u, project: project) } }
  let!(:branch_name) { 'feature' }
  let!(:branch_sha) { '0b4bc9a49b562e85de7cc9e834518ea6828729b9' }
  let(:branch_with_dot) { CreateBranchService.new(project, user).execute("with.1.2.3", "master")[:branch] }

  describe "GET /projects/:id/repository/branches" do
    let(:route) { "/projects/#{project.id}/repository/branches" }

    shared_examples_for 'repository branches' do
      it 'returns the repository branches' do
        get api(route, current_user), per_page: 100

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        branch_names = json_response.map { |x| x['name'] }
        expect(branch_names).to match_array(project.repository.branch_names)
      end

      context 'when repository is disabled' do
        include_context 'disabled repository'

        it_behaves_like '403 response' do
          let(:request) { get api(route, current_user) }
        end
      end
    end

    context 'when unauthenticated', 'and project is public' do
      it_behaves_like 'repository branches' do
        let(:project) { create(:project, :public, :repository) }
        let(:current_user) { nil }
      end
    end

    context 'when unauthenticated', 'and project is private' do
      it_behaves_like '404 response' do
        let(:request) { get api(route) }
        let(:message) { '404 Project Not Found' }
      end
    end

    context 'when authenticated', 'as a developer' do
      it_behaves_like 'repository branches' do
        let(:current_user) { user }
      end
    end

    context 'when authenticated', 'as a guest' do
      it_behaves_like '403 response' do
        let(:request) { get api(route, guest) }
      end
    end
  end

  describe "GET /projects/:id/repository/branches/:branch" do
    let(:route) { "/projects/#{project.id}/repository/branches/#{branch_name}" }

    shared_examples_for 'repository branch' do |merged: false|
      it 'returns the repository branch' do
        get api(route, current_user)

        expect(response).to have_http_status(200)
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['merged']).to eq(merged)
        expect(json_response['protected']).to eq(false)
        expect(json_response['developers_can_push']).to eq(false)
        expect(json_response['developers_can_merge']).to eq(false)

        json_commit = json_response['commit']
        expect(json_commit['id']).to eq(branch_sha)
        expect(json_commit).to have_key('short_id')
        expect(json_commit).to have_key('title')
        expect(json_commit).to have_key('message')
        expect(json_commit).to have_key('author_name')
        expect(json_commit).to have_key('author_email')
        expect(json_commit).to have_key('authored_date')
        expect(json_commit).to have_key('committer_name')
        expect(json_commit).to have_key('committer_email')
        expect(json_commit).to have_key('committed_date')
        expect(json_commit).to have_key('parent_ids')
      end

      context 'when branch does not exist' do
        let(:branch_name) { 'unknown' }

        it_behaves_like '404 response' do
          let(:request) { get api(route, current_user) }
          let(:message) { '404 Branch Not Found' }
        end
      end

      context 'when repository is disabled' do
        include_context 'disabled repository'

        it_behaves_like '403 response' do
          let(:request) { get api(route, current_user) }
        end
      end
    end

    context 'when unauthenticated', 'and project is public' do
      it_behaves_like 'repository branch' do
        let(:project) { create(:project, :public, :repository) }
        let(:current_user) { nil }
      end
    end

    context 'when unauthenticated', 'and project is private' do
      it_behaves_like '404 response' do
        let(:request) { get api(route) }
        let(:message) { '404 Project Not Found' }
      end
    end

    context 'when authenticated', 'as a developer' do
      let(:current_user) { user }
      it_behaves_like 'repository branch'

      context 'when branch contains a dot' do
        let(:branch_name) { branch_with_dot.name }
        let(:branch_sha) { project.commit('master').sha }

        it_behaves_like 'repository branch'
      end

      context 'when branch is merged' do
        let(:branch_name) { 'merge-test' }
        let(:branch_sha) { project.commit('merge-test').sha }

        it_behaves_like 'repository branch', merged: true
      end
    end

    context 'when authenticated', 'as a guest' do
      it_behaves_like '403 response' do
        let(:request) { get api(route, guest) }
      end
    end
  end

  describe 'PUT /projects/:id/repository/branches/:branch/protect' do
    context "when a protected branch doesn't already exist" do
      it 'protects a single branch' do
        put api("/projects/#{project.id}/repository/branches/#{branch_name}/protect", user)

        expect(response).to have_http_status(200)
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['commit']['id']).to eq(branch_sha)
        expect(json_response['protected']).to eq(true)
        expect(json_response['developers_can_push']).to eq(false)
        expect(json_response['developers_can_merge']).to eq(false)
      end

      it "protects a single branch with dots in the name" do
        put api("/projects/#{project.id}/repository/branches/#{branch_with_dot.name}/protect", user)

        expect(response).to have_http_status(200)
        expect(json_response['name']).to eq(branch_with_dot.name)
        expect(json_response['protected']).to eq(true)
      end

      it 'protects a single branch and developers can push' do
        put api("/projects/#{project.id}/repository/branches/#{branch_name}/protect", user),
            developers_can_push: true

        expect(response).to have_http_status(200)
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['commit']['id']).to eq(branch_sha)
        expect(json_response['protected']).to eq(true)
        expect(json_response['developers_can_push']).to eq(true)
        expect(json_response['developers_can_merge']).to eq(false)
      end

      it 'protects a single branch and developers can merge' do
        put api("/projects/#{project.id}/repository/branches/#{branch_name}/protect", user),
            developers_can_merge: true

        expect(response).to have_http_status(200)
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['commit']['id']).to eq(branch_sha)
        expect(json_response['protected']).to eq(true)
        expect(json_response['developers_can_push']).to eq(false)
        expect(json_response['developers_can_merge']).to eq(true)
      end

      it 'protects a single branch and developers can push and merge' do
        put api("/projects/#{project.id}/repository/branches/#{branch_name}/protect", user),
            developers_can_push: true, developers_can_merge: true

        expect(response).to have_http_status(200)
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['commit']['id']).to eq(branch_sha)
        expect(json_response['protected']).to eq(true)
        expect(json_response['developers_can_push']).to eq(true)
        expect(json_response['developers_can_merge']).to eq(true)
      end
    end

    context 'for an existing protected branch' do
      before do
        project.repository.add_branch(user, protected_branch.name, 'master')
      end

      context "when developers can push and merge" do
        let(:protected_branch) { create(:protected_branch, :developers_can_push, :developers_can_merge, project: project, name: 'protected_branch') }

        it 'updates that a developer cannot push or merge' do
          put api("/projects/#{project.id}/repository/branches/#{protected_branch.name}/protect", user),
              developers_can_push: false, developers_can_merge: false

          expect(response).to have_http_status(200)
          expect(json_response['name']).to eq(protected_branch.name)
          expect(json_response['protected']).to eq(true)
          expect(json_response['developers_can_push']).to eq(false)
          expect(json_response['developers_can_merge']).to eq(false)
        end

        it "doesn't result in 0 access levels when 'developers_can_push' is switched off" do
          put api("/projects/#{project.id}/repository/branches/#{protected_branch.name}/protect", user),
              developers_can_push: false

          expect(response).to have_http_status(200)
          expect(json_response['name']).to eq(protected_branch.name)
          expect(protected_branch.reload.push_access_levels.first).to be_present
          expect(protected_branch.reload.push_access_levels.first.access_level).to eq(Gitlab::Access::MASTER)
        end

        it "doesn't result in 0 access levels when 'developers_can_merge' is switched off" do
          put api("/projects/#{project.id}/repository/branches/#{protected_branch.name}/protect", user),
              developers_can_merge: false

          expect(response).to have_http_status(200)
          expect(json_response['name']).to eq(protected_branch.name)
          expect(protected_branch.reload.merge_access_levels.first).to be_present
          expect(protected_branch.reload.merge_access_levels.first.access_level).to eq(Gitlab::Access::MASTER)
        end
      end

      context "when developers cannot push or merge" do
        let(:protected_branch) { create(:protected_branch, project: project, name: 'protected_branch') }

        it 'updates that a developer can push and merge' do
          put api("/projects/#{project.id}/repository/branches/#{protected_branch.name}/protect", user),
              developers_can_push: true, developers_can_merge: true

          expect(response).to have_http_status(200)
          expect(json_response['name']).to eq(protected_branch.name)
          expect(json_response['protected']).to eq(true)
          expect(json_response['developers_can_push']).to eq(true)
          expect(json_response['developers_can_merge']).to eq(true)
        end
      end

      context "when no one can push" do
        let(:protected_branch) { create(:protected_branch, :no_one_can_push, project: project, name: 'protected_branch') }

        it "updates 'developers_can_push' without removing the 'no_one' access level" do
          put api("/projects/#{project.id}/repository/branches/#{protected_branch.name}/protect", user),
              developers_can_push: true, developers_can_merge: true

          expect(response).to have_http_status(200)
          expect(json_response['name']).to eq(protected_branch.name)
          expect(protected_branch.reload.push_access_levels.pluck(:access_level)).to include(Gitlab::Access::NO_ACCESS)
        end
      end
    end

    context "multiple API calls" do
      it "returns success when `protect` is called twice" do
        put api("/projects/#{project.id}/repository/branches/#{branch_name}/protect", user)
        put api("/projects/#{project.id}/repository/branches/#{branch_name}/protect", user)

        expect(response).to have_http_status(200)
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['protected']).to eq(true)
        expect(json_response['developers_can_push']).to eq(false)
        expect(json_response['developers_can_merge']).to eq(false)
      end

      it "returns success when `protect` is called twice with `developers_can_push` turned on" do
        put api("/projects/#{project.id}/repository/branches/#{branch_name}/protect", user), developers_can_push: true
        put api("/projects/#{project.id}/repository/branches/#{branch_name}/protect", user), developers_can_push: true

        expect(response).to have_http_status(200)
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['protected']).to eq(true)
        expect(json_response['developers_can_push']).to eq(true)
        expect(json_response['developers_can_merge']).to eq(false)
      end

      it "returns success when `protect` is called twice with `developers_can_merge` turned on" do
        put api("/projects/#{project.id}/repository/branches/#{branch_name}/protect", user), developers_can_merge: true
        put api("/projects/#{project.id}/repository/branches/#{branch_name}/protect", user), developers_can_merge: true

        expect(response).to have_http_status(200)
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['protected']).to eq(true)
        expect(json_response['developers_can_push']).to eq(false)
        expect(json_response['developers_can_merge']).to eq(true)
      end
    end

    it "returns a 404 error if branch not found" do
      put api("/projects/#{project.id}/repository/branches/unknown/protect", user)
      expect(response).to have_http_status(404)
    end

    it "returns a 403 error if guest" do
      put api("/projects/#{project.id}/repository/branches/#{branch_name}/protect", guest)
      expect(response).to have_http_status(403)
    end
  end

  describe "PUT /projects/:id/repository/branches/:branch/unprotect" do
    it "unprotects a single branch" do
      put api("/projects/#{project.id}/repository/branches/#{branch_name}/unprotect", user)
      expect(response).to have_http_status(200)

      expect(json_response['name']).to eq(branch_name)
      expect(json_response['commit']['id']).to eq(branch_sha)
      expect(json_response['protected']).to eq(false)
    end

    it "update branches with dots in branch name" do
      put api("/projects/#{project.id}/repository/branches/#{branch_with_dot.name}/unprotect", user)

      expect(response).to have_http_status(200)
      expect(json_response['name']).to eq(branch_with_dot.name)
      expect(json_response['protected']).to eq(false)
    end

    it "returns success when unprotect branch" do
      put api("/projects/#{project.id}/repository/branches/unknown/unprotect", user)
      expect(response).to have_http_status(404)
    end

    it "returns success when unprotect branch again" do
      put api("/projects/#{project.id}/repository/branches/#{branch_name}/unprotect", user)
      put api("/projects/#{project.id}/repository/branches/#{branch_name}/unprotect", user)
      expect(response).to have_http_status(200)
    end
  end

  describe "POST /projects/:id/repository/branches" do
    it "creates a new branch" do
      post api("/projects/#{project.id}/repository/branches", user),
           branch: 'feature1',
           ref: branch_sha

      expect(response).to have_http_status(201)

      expect(json_response['name']).to eq('feature1')
      expect(json_response['commit']['id']).to eq(branch_sha)
    end

    it "denies for user without push access" do
      post api("/projects/#{project.id}/repository/branches", guest),
           branch: branch_name,
           ref: branch_sha
      expect(response).to have_http_status(403)
    end

    it 'returns 400 if branch name is invalid' do
      post api("/projects/#{project.id}/repository/branches", user),
           branch: 'new design',
           ref: branch_sha
      expect(response).to have_http_status(400)
      expect(json_response['message']).to eq('Branch name is invalid')
    end

    it 'returns 400 if branch already exists' do
      post api("/projects/#{project.id}/repository/branches", user),
           branch: 'new_design1',
           ref: branch_sha
      expect(response).to have_http_status(201)

      post api("/projects/#{project.id}/repository/branches", user),
           branch: 'new_design1',
           ref: branch_sha
      expect(response).to have_http_status(400)
      expect(json_response['message']).to eq('Branch already exists')
    end

    it 'returns 400 if ref name is invalid' do
      post api("/projects/#{project.id}/repository/branches", user),
           branch: 'new_design3',
           ref: 'foo'
      expect(response).to have_http_status(400)
      expect(json_response['message']).to eq('Invalid reference name')
    end
  end

  describe "DELETE /projects/:id/repository/branches/:branch" do
    before do
      allow_any_instance_of(Repository).to receive(:rm_branch).and_return(true)
    end

    it "removes branch" do
      delete api("/projects/#{project.id}/repository/branches/#{branch_name}", user)

      expect(response).to have_http_status(204)
    end

    it "removes a branch with dots in the branch name" do
      delete api("/projects/#{project.id}/repository/branches/#{branch_with_dot.name}", user)

      expect(response).to have_http_status(204)
    end

    it 'returns 404 if branch not exists' do
      delete api("/projects/#{project.id}/repository/branches/foobar", user)
      expect(response).to have_http_status(404)
    end
  end

  describe "DELETE /projects/:id/repository/merged_branches" do
    before do
      allow_any_instance_of(Repository).to receive(:rm_branch).and_return(true)
    end

    it 'returns 202 with json body' do
      delete api("/projects/#{project.id}/repository/merged_branches", user)

      expect(response).to have_http_status(202)
      expect(json_response['message']).to eql('202 Accepted')
    end

    it 'returns a 403 error if guest' do
      delete api("/projects/#{project.id}/repository/merged_branches", guest)
      expect(response).to have_http_status(403)
    end
  end
end
