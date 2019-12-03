# frozen_string_literal: true

require 'spec_helper'

describe API::Branches do
  set(:user) { create(:user) }
  let(:project) { create(:project, :repository, creator: user, path: 'my.project') }
  let(:guest) { create(:user).tap { |u| project.add_guest(u) } }
  let(:branch_name) { 'feature' }
  let(:branch_sha) { '0b4bc9a49b562e85de7cc9e834518ea6828729b9' }
  let(:branch_with_dot) { project.repository.find_branch('ends-with.json') }
  let(:branch_with_slash) { project.repository.find_branch('improve/awesome') }

  let(:project_id) { project.id }
  let(:current_user) { nil }

  before do
    project.add_maintainer(user)
  end

  describe "GET /projects/:id/repository/branches" do
    let(:route) { "/projects/#{project_id}/repository/branches" }

    shared_examples_for 'repository branches' do
      RSpec::Matchers.define :has_up_to_merged_branch_names_count do |expected|
        match do |actual|
          expected >= actual[:merged_branch_names].count
        end
      end

      it 'returns the repository branches' do
        get api(route, current_user), params: { per_page: 100 }

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/branches')
        expect(response).to include_pagination_headers
        branch_names = json_response.map { |x| x['name'] }
        expect(branch_names).to match_array(project.repository.branch_names)
      end

      def check_merge_status(json_response)
        merged, unmerged = json_response.partition { |branch| branch['merged'] }
        merged_branches = merged.map { |branch| branch['name'] }
        unmerged_branches = unmerged.map { |branch| branch['name'] }
        expect(Set.new(merged_branches)).to eq(project.repository.merged_branch_names(merged_branches + unmerged_branches))
        expect(project.repository.merged_branch_names(unmerged_branches)).to be_empty
      end

      it 'determines only a limited number of merged branch names' do
        expect(API::Entities::Branch).to receive(:represent).with(anything, has_up_to_merged_branch_names_count(2)).and_call_original

        get api(route, current_user), params: { per_page: 2 }

        expect(response).to have_gitlab_http_status(200)

        check_merge_status(json_response)
      end

      it 'merge status matches reality on paginated input' do
        get api(route, current_user), params: { per_page: 20, page: 2 }

        expect(response).to have_gitlab_http_status(200)

        check_merge_status(json_response)
      end

      context 'when repository is disabled' do
        include_context 'disabled repository'

        it_behaves_like '404 response' do
          let(:request) { get api(route, current_user) }
        end
      end
    end

    context 'when search parameter is passed' do
      context 'and branch exists' do
        it 'returns correct branches' do
          get api(route, user), params: { per_page: 100, search: branch_name }

          searched_branch_names = json_response.map { |branch| branch['name'] }
          project_branch_names = project.repository.branch_names.grep(/#{branch_name}/)

          expect(searched_branch_names).to match_array(project_branch_names)
        end
      end

      context 'and branch does not exist' do
        it 'returns an empty array' do
          get api(route, user), params: { per_page: 100, search: 'no_such_branch_name_entropy_of_jabadabadu' }

          expect(json_response).to eq []
        end
      end
    end

    context 'when unauthenticated', 'and project is public' do
      before do
        project.update(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
      end

      it_behaves_like 'repository branches'
    end

    context 'when unauthenticated', 'and project is private' do
      it_behaves_like '404 response' do
        let(:request) { get api(route) }
        let(:message) { '404 Project Not Found' }
      end
    end

    context 'when authenticated', 'as a maintainer' do
      let(:current_user) { user }

      it_behaves_like 'repository branches'

      context 'requesting with the escaped project full path' do
        let(:project_id) { CGI.escape(project.full_path) }

        it_behaves_like 'repository branches'
      end

      it 'does not submit N+1 DB queries', :request_store do
        create(:protected_branch, name: 'master', project: project)

        # Make sure no setup step query is recorded.
        get api(route, current_user), params: { per_page: 100 }

        control = ActiveRecord::QueryRecorder.new do
          get api(route, current_user), params: { per_page: 100 }
        end

        new_branch_name = 'protected-branch'
        ::Branches::CreateService.new(project, current_user).execute(new_branch_name, 'master')
        create(:protected_branch, name: new_branch_name, project: project)

        expect do
          get api(route, current_user), params: { per_page: 100 }
        end.not_to exceed_query_limit(control)
      end
    end

    context 'when authenticated', 'as a guest' do
      it_behaves_like '403 response' do
        let(:request) { get api(route, guest) }
      end
    end
  end

  describe "GET /projects/:id/repository/branches/:branch" do
    let(:route) { "/projects/#{project_id}/repository/branches/#{branch_name}" }

    shared_examples_for 'repository branch' do
      context 'HEAD request' do
        it 'returns 204 No Content' do
          head api(route, user)

          expect(response).to have_gitlab_http_status(204)
          expect(response.body).to be_empty
        end

        it 'returns 404 Not Found' do
          head api("/projects/#{project_id}/repository/branches/unknown", user)

          expect(response).to have_gitlab_http_status(404)
          expect(response.body).to be_empty
        end
      end

      it 'returns the repository branch' do
        get api(route, current_user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/branch')
        expect(json_response['name']).to eq(CGI.unescape(branch_name))
      end

      context 'when branch does not exist' do
        let(:branch_name) { 'unknown' }

        it_behaves_like '404 response' do
          let(:request) { get api(route, current_user) }
          let(:message) { '404 Branch Not Found' }
        end
      end

      context 'when the branch refname is invalid' do
        let(:branch_name) { 'branch*' }
        let(:message) { 'The branch refname is invalid' }

        it_behaves_like '400 response' do
          let(:request) { get api(route, current_user) }
        end
      end

      context 'when repository is disabled' do
        include_context 'disabled repository'

        it_behaves_like '404 response' do
          let(:request) { get api(route, current_user) }
        end
      end
    end

    context 'when unauthenticated', 'and project is public' do
      before do
        project.update(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
      end

      it_behaves_like 'repository branch'

      it 'returns that the current user cannot push' do
        get api(route, current_user)

        expect(json_response['can_push']).to eq(false)
      end
    end

    context 'when unauthenticated', 'and project is private' do
      it_behaves_like '404 response' do
        let(:request) { get api(route) }
        let(:message) { '404 Project Not Found' }
      end
    end

    context 'when authenticated', 'as a maintainer' do
      let(:current_user) { user }

      it_behaves_like 'repository branch'

      it 'returns that the current user can push' do
        get api(route, current_user)

        expect(json_response['can_push']).to eq(true)
      end

      context 'when branch contains a dot' do
        let(:branch_name) { branch_with_dot.name }

        it_behaves_like 'repository branch'
      end

      context 'when branch contains a slash' do
        let(:branch_name) { branch_with_slash.name }

        it_behaves_like '404 response' do
          let(:request) { get api(route, current_user) }
        end
      end

      context 'when branch contains an escaped slash' do
        let(:branch_name) { CGI.escape(branch_with_slash.name) }

        it_behaves_like 'repository branch'
      end

      context 'requesting with the escaped project full path' do
        let(:project_id) { CGI.escape(project.full_path) }

        it_behaves_like 'repository branch'

        context 'when branch contains a dot' do
          let(:branch_name) { branch_with_dot.name }

          it_behaves_like 'repository branch'
        end
      end
    end

    context 'when authenticated', 'as a developer and branch is protected' do
      let(:current_user) { create(:user) }
      let!(:protected_branch) { create(:protected_branch, project: project, name: branch_name) }

      before do
        project.add_developer(current_user)
      end

      it_behaves_like 'repository branch'

      it 'returns that the current user cannot push' do
        get api(route, current_user)

        expect(json_response['can_push']).to eq(false)
      end
    end

    context 'when authenticated', 'as a guest' do
      it_behaves_like '403 response' do
        let(:request) { get api(route, guest) }
      end
    end
  end

  describe 'PUT /projects/:id/repository/branches/:branch/protect' do
    let(:route) { "/projects/#{project_id}/repository/branches/#{branch_name}/protect" }

    shared_examples_for 'repository new protected branch' do
      it 'protects a single branch' do
        put api(route, current_user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/branch')
        expect(json_response['name']).to eq(CGI.unescape(branch_name))
        expect(json_response['protected']).to eq(true)
      end

      it 'protects a single branch and developers can push' do
        put api(route, current_user), params: { developers_can_push: true }

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/branch')
        expect(json_response['name']).to eq(CGI.unescape(branch_name))
        expect(json_response['protected']).to eq(true)
        expect(json_response['developers_can_push']).to eq(true)
        expect(json_response['developers_can_merge']).to eq(false)
      end

      it 'protects a single branch and developers can merge' do
        put api(route, current_user), params: { developers_can_merge: true }

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/branch')
        expect(json_response['name']).to eq(CGI.unescape(branch_name))
        expect(json_response['protected']).to eq(true)
        expect(json_response['developers_can_push']).to eq(false)
        expect(json_response['developers_can_merge']).to eq(true)
      end

      it 'protects a single branch and developers can push and merge' do
        put api(route, current_user), params: { developers_can_push: true, developers_can_merge: true }

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/branch')
        expect(json_response['name']).to eq(CGI.unescape(branch_name))
        expect(json_response['protected']).to eq(true)
        expect(json_response['developers_can_push']).to eq(true)
        expect(json_response['developers_can_merge']).to eq(true)
      end

      context 'when branch does not exist' do
        let(:branch_name) { 'unknown' }

        it_behaves_like '404 response' do
          let(:request) { put api(route, current_user) }
          let(:message) { '404 Branch Not Found' }
        end
      end

      context 'when the branch refname is invalid' do
        let(:branch_name) { 'branch*' }
        let(:message) { 'The branch refname is invalid' }

        it_behaves_like '400 response' do
          let(:request) { put api(route, current_user) }
        end
      end

      context 'when repository is disabled' do
        include_context 'disabled repository'

        it_behaves_like '404 response' do
          let(:request) { put api(route, current_user) }
        end
      end
    end

    context 'when unauthenticated', 'and project is private' do
      it_behaves_like '404 response' do
        let(:request) { put api(route) }
        let(:message) { '404 Project Not Found' }
      end
    end

    context 'when authenticated', 'as a guest' do
      it_behaves_like '403 response' do
        let(:request) { put api(route, guest) }
      end
    end

    context 'when authenticated', 'as a maintainer' do
      let(:current_user) { user }

      context "when a protected branch doesn't already exist" do
        it_behaves_like 'repository new protected branch'

        context 'when branch contains a dot' do
          let(:branch_name) { branch_with_dot.name }

          it_behaves_like 'repository new protected branch'
        end

        context 'when branch contains a slash' do
          let(:branch_name) { branch_with_slash.name }

          it_behaves_like '404 response' do
            let(:request) { put api(route, current_user) }
          end
        end

        context 'when branch contains an escaped slash' do
          let(:branch_name) { CGI.escape(branch_with_slash.name) }

          it_behaves_like 'repository new protected branch'
        end

        context 'requesting with the escaped project full path' do
          let(:project_id) { CGI.escape(project.full_path) }

          it_behaves_like 'repository new protected branch'

          context 'when branch contains a dot' do
            let(:branch_name) { branch_with_dot.name }

            it_behaves_like 'repository new protected branch'
          end
        end
      end

      context 'when protected branch already exists' do
        before do
          project.repository.add_branch(user, protected_branch.name, 'master')
        end

        context 'when developers can push and merge' do
          let(:protected_branch) { create(:protected_branch, :developers_can_push, :developers_can_merge, project: project, name: 'protected_branch') }

          it 'updates that a developer cannot push or merge' do
            put api("/projects/#{project.id}/repository/branches/#{protected_branch.name}/protect", user),
                params: { developers_can_push: false, developers_can_merge: false }

            expect(response).to have_gitlab_http_status(200)
            expect(response).to match_response_schema('public_api/v4/branch')
            expect(json_response['name']).to eq(protected_branch.name)
            expect(json_response['protected']).to eq(true)
            expect(json_response['developers_can_push']).to eq(false)
            expect(json_response['developers_can_merge']).to eq(false)
            expect(protected_branch.reload.push_access_levels.first.access_level).to eq(Gitlab::Access::MAINTAINER)
            expect(protected_branch.reload.merge_access_levels.first.access_level).to eq(Gitlab::Access::MAINTAINER)
          end
        end

        context 'when developers cannot push or merge' do
          let(:protected_branch) { create(:protected_branch, project: project, name: 'protected_branch') }

          it 'updates that a developer can push and merge' do
            put api("/projects/#{project.id}/repository/branches/#{protected_branch.name}/protect", user),
                params: { developers_can_push: true, developers_can_merge: true }

            expect(response).to have_gitlab_http_status(200)
            expect(response).to match_response_schema('public_api/v4/branch')
            expect(json_response['name']).to eq(protected_branch.name)
            expect(json_response['protected']).to eq(true)
            expect(json_response['developers_can_push']).to eq(true)
            expect(json_response['developers_can_merge']).to eq(true)
          end
        end
      end
    end
  end

  describe 'PUT /projects/:id/repository/branches/:branch/unprotect' do
    let(:route) { "/projects/#{project_id}/repository/branches/#{branch_name}/unprotect" }

    shared_examples_for 'repository unprotected branch' do
      it 'unprotects a single branch' do
        put api(route, current_user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/branch')
        expect(json_response['name']).to eq(CGI.unescape(branch_name))
        expect(json_response['protected']).to eq(false)
      end

      context 'when branch does not exist' do
        let(:branch_name) { 'unknown' }

        it_behaves_like '404 response' do
          let(:request) { put api(route, current_user) }
          let(:message) { '404 Branch Not Found' }
        end
      end

      context 'when the branch refname is invalid' do
        let(:branch_name) { 'branch*' }
        let(:message) { 'The branch refname is invalid' }

        it_behaves_like '400 response' do
          let(:request) { put api(route, current_user) }
        end
      end

      context 'when repository is disabled' do
        include_context 'disabled repository'

        it_behaves_like '404 response' do
          let(:request) { put api(route, current_user) }
        end
      end
    end

    context 'when unauthenticated', 'and project is private' do
      it_behaves_like '404 response' do
        let(:request) { put api(route) }
        let(:message) { '404 Project Not Found' }
      end
    end

    context 'when authenticated', 'as a guest' do
      it_behaves_like '403 response' do
        let(:request) { put api(route, guest) }
      end
    end

    context 'when authenticated', 'as a maintainer' do
      let(:current_user) { user }

      context "when a protected branch doesn't already exist" do
        it_behaves_like 'repository unprotected branch'

        context 'when branch contains a dot' do
          let(:branch_name) { branch_with_dot.name }

          it_behaves_like 'repository unprotected branch'
        end

        context 'when branch contains a slash' do
          let(:branch_name) { branch_with_slash.name }

          it_behaves_like '404 response' do
            let(:request) { put api(route, current_user) }
          end
        end

        context 'when branch contains an escaped slash' do
          let(:branch_name) { CGI.escape(branch_with_slash.name) }

          it_behaves_like 'repository unprotected branch'
        end

        context 'requesting with the escaped project full path' do
          let(:project_id) { CGI.escape(project.full_path) }

          it_behaves_like 'repository unprotected branch'

          context 'when branch contains a dot' do
            let(:branch_name) { branch_with_dot.name }

            it_behaves_like 'repository unprotected branch'
          end
        end
      end
    end
  end

  describe 'POST /projects/:id/repository/branches' do
    let(:route) { "/projects/#{project_id}/repository/branches" }

    shared_examples_for 'repository new branch' do
      it 'creates a new branch' do
        post api(route, current_user), params: { branch: 'feature1', ref: branch_sha }

        expect(response).to have_gitlab_http_status(201)
        expect(response).to match_response_schema('public_api/v4/branch')
        expect(json_response['name']).to eq('feature1')
        expect(json_response['commit']['id']).to eq(branch_sha)
      end

      context 'when repository is disabled' do
        include_context 'disabled repository'

        it_behaves_like '404 response' do
          let(:request) { post api(route, current_user) }
        end
      end
    end

    context 'when unauthenticated', 'and project is private' do
      it_behaves_like '404 response' do
        let(:request) { post api(route) }
        let(:message) { '404 Project Not Found' }
      end
    end

    context 'when authenticated', 'as a guest' do
      it_behaves_like '403 response' do
        let(:request) { post api(route, guest) }
      end
    end

    context 'when authenticated', 'as a maintainer' do
      let(:current_user) { user }

      context "when a protected branch doesn't already exist" do
        it_behaves_like 'repository new branch'

        context 'requesting with the escaped project full path' do
          let(:project_id) { CGI.escape(project.full_path) }

          it_behaves_like 'repository new branch'
        end
      end
    end

    it 'returns 400 if branch name is invalid' do
      post api(route, user), params: { branch: 'new design', ref: branch_sha }

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']).to eq('Branch name is invalid')
    end

    it 'returns 400 if branch already exists' do
      post api(route, user), params: { branch: 'new_design1', ref: branch_sha }

      expect(response).to have_gitlab_http_status(201)

      post api(route, user), params: { branch: 'new_design1', ref: branch_sha }

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']).to eq('Branch already exists')
    end

    it 'returns 400 if ref name is invalid' do
      post api(route, user), params: { branch: 'new_design3', ref: 'foo' }

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']).to eq('Invalid reference name: new_design3')
    end
  end

  describe 'DELETE /projects/:id/repository/branches/:branch' do
    before do
      allow_any_instance_of(Repository).to receive(:rm_branch).and_return(true)
    end

    it 'removes branch' do
      delete api("/projects/#{project.id}/repository/branches/#{branch_name}", user)

      expect(response).to have_gitlab_http_status(204)
    end

    it 'removes a branch with dots in the branch name' do
      delete api("/projects/#{project.id}/repository/branches/#{branch_with_dot.name}", user)

      expect(response).to have_gitlab_http_status(204)
    end

    it 'returns 404 if branch not exists' do
      delete api("/projects/#{project.id}/repository/branches/foobar", user)

      expect(response).to have_gitlab_http_status(404)
    end

    context 'when the branch refname is invalid' do
      let(:branch_name) { 'branch*' }
      let(:message) { 'The branch refname is invalid' }

      it_behaves_like '400 response' do
        let(:request) { delete api("/projects/#{project.id}/repository/branches/#{branch_name}", user) }
      end
    end

    it_behaves_like '412 response' do
      let(:request) { api("/projects/#{project.id}/repository/branches/#{branch_name}", user) }
    end
  end

  describe 'DELETE /projects/:id/repository/merged_branches' do
    before do
      allow_any_instance_of(Repository).to receive(:rm_branch).and_return(true)
    end

    it 'returns 202 with json body' do
      delete api("/projects/#{project.id}/repository/merged_branches", user)

      expect(response).to have_gitlab_http_status(202)
      expect(json_response['message']).to eql('202 Accepted')
    end

    it 'returns a 403 error if guest' do
      delete api("/projects/#{project.id}/repository/merged_branches", guest)

      expect(response).to have_gitlab_http_status(403)
    end
  end
end
