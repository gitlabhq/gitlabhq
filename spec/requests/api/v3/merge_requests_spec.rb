require "spec_helper"

describe API::MergeRequests do
  include ProjectForksHelper

  let(:base_time)   { Time.now }
  let(:user)        { create(:user) }
  let(:admin)       { create(:user, :admin) }
  let(:non_member)  { create(:user) }
  let!(:project)    { create(:project, :public, :repository, creator: user, namespace: user.namespace) }
  let!(:merge_request) { create(:merge_request, :simple, author: user, assignee: user, source_project: project, title: "Test", created_at: base_time) }
  let!(:merge_request_closed) { create(:merge_request, state: "closed", author: user, assignee: user, source_project: project, title: "Closed test", created_at: base_time + 1.second) }
  let!(:merge_request_merged) { create(:merge_request, state: "merged", author: user, assignee: user, source_project: project, title: "Merged test", created_at: base_time + 2.seconds, merge_commit_sha: '9999999999999999999999999999999999999999') }
  let(:milestone)   { create(:milestone, title: '1.0.0', project: project) }

  before do
    project.add_reporter(user)
  end

  describe "GET /projects/:id/merge_requests" do
    context "when unauthenticated" do
      it "returns authentication error" do
        get v3_api("/projects/#{project.id}/merge_requests")
        expect(response).to have_gitlab_http_status(401)
      end
    end

    context "when authenticated" do
      it "returns an array of all merge_requests" do
        get v3_api("/projects/#{project.id}/merge_requests", user)
        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(3)
        expect(json_response.last['title']).to eq(merge_request.title)
        expect(json_response.last).to have_key('web_url')
        expect(json_response.last['sha']).to eq(merge_request.diff_head_sha)
        expect(json_response.last['merge_commit_sha']).to be_nil
        expect(json_response.last['merge_commit_sha']).to eq(merge_request.merge_commit_sha)
        expect(json_response.first['title']).to eq(merge_request_merged.title)
        expect(json_response.first['sha']).to eq(merge_request_merged.diff_head_sha)
        expect(json_response.first['merge_commit_sha']).not_to be_nil
        expect(json_response.first['merge_commit_sha']).to eq(merge_request_merged.merge_commit_sha)
        expect(json_response.first['squash']).to eq(merge_request_merged.squash)
      end

      it "returns an array of all merge_requests" do
        get v3_api("/projects/#{project.id}/merge_requests?state", user)
        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(3)
        expect(json_response.last['title']).to eq(merge_request.title)
      end

      it "returns an array of open merge_requests" do
        get v3_api("/projects/#{project.id}/merge_requests?state=opened", user)
        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.last['title']).to eq(merge_request.title)
      end

      it "returns an array of closed merge_requests" do
        get v3_api("/projects/#{project.id}/merge_requests?state=closed", user)
        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['title']).to eq(merge_request_closed.title)
      end

      it "returns an array of merged merge_requests" do
        get v3_api("/projects/#{project.id}/merge_requests?state=merged", user)
        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['title']).to eq(merge_request_merged.title)
      end

      it 'matches V3 response schema' do
        get v3_api("/projects/#{project.id}/merge_requests", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v3/merge_requests')
      end

      context "with ordering" do
        before do
          @mr_later = mr_with_later_created_and_updated_at_time
          @mr_earlier = mr_with_earlier_created_and_updated_at_time
        end

        it "returns an array of merge_requests in ascending order" do
          get v3_api("/projects/#{project.id}/merge_requests?sort=asc", user)
          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(3)
          response_dates = json_response.map { |merge_request| merge_request['created_at'] }
          expect(response_dates).to eq(response_dates.sort)
        end

        it "returns an array of merge_requests in descending order" do
          get v3_api("/projects/#{project.id}/merge_requests?sort=desc", user)
          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(3)
          response_dates = json_response.map { |merge_request| merge_request['created_at'] }
          expect(response_dates).to eq(response_dates.sort.reverse)
        end

        it "returns an array of merge_requests ordered by updated_at" do
          get v3_api("/projects/#{project.id}/merge_requests?order_by=updated_at", user)
          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(3)
          response_dates = json_response.map { |merge_request| merge_request['updated_at'] }
          expect(response_dates).to eq(response_dates.sort.reverse)
        end

        it "returns an array of merge_requests ordered by created_at" do
          get v3_api("/projects/#{project.id}/merge_requests?order_by=created_at&sort=asc", user)
          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(3)
          response_dates = json_response.map { |merge_request| merge_request['created_at'] }
          expect(response_dates).to eq(response_dates.sort)
        end
      end
    end
  end

  describe "GET /projects/:id/merge_requests/:merge_request_id" do
    it 'exposes known attributes' do
      get v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['id']).to eq(merge_request.id)
      expect(json_response['iid']).to eq(merge_request.iid)
      expect(json_response['project_id']).to eq(merge_request.project.id)
      expect(json_response['title']).to eq(merge_request.title)
      expect(json_response['description']).to eq(merge_request.description)
      expect(json_response['state']).to eq(merge_request.state)
      expect(json_response['created_at']).to be_present
      expect(json_response['updated_at']).to be_present
      expect(json_response['labels']).to eq(merge_request.label_names)
      expect(json_response['milestone']).to be_nil
      expect(json_response['assignee']).to be_a Hash
      expect(json_response['author']).to be_a Hash
      expect(json_response['target_branch']).to eq(merge_request.target_branch)
      expect(json_response['source_branch']).to eq(merge_request.source_branch)
      expect(json_response['upvotes']).to eq(0)
      expect(json_response['downvotes']).to eq(0)
      expect(json_response['source_project_id']).to eq(merge_request.source_project.id)
      expect(json_response['target_project_id']).to eq(merge_request.target_project.id)
      expect(json_response['work_in_progress']).to be_falsy
      expect(json_response['merge_when_build_succeeds']).to be_falsy
      expect(json_response['merge_status']).to eq('can_be_merged')
      expect(json_response['should_close_merge_request']).to be_falsy
      expect(json_response['force_close_merge_request']).to be_falsy
    end

    it "returns merge_request" do
      get v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}", user)
      expect(response).to have_gitlab_http_status(200)
      expect(json_response['title']).to eq(merge_request.title)
      expect(json_response['iid']).to eq(merge_request.iid)
      expect(json_response['work_in_progress']).to eq(false)
      expect(json_response['merge_status']).to eq('can_be_merged')
      expect(json_response['should_close_merge_request']).to be_falsy
      expect(json_response['force_close_merge_request']).to be_falsy
    end

    it 'returns merge_request by iid' do
      url = "/projects/#{project.id}/merge_requests?iid=#{merge_request.iid}"
      get v3_api(url, user)
      expect(response.status).to eq 200
      expect(json_response.first['title']).to eq merge_request.title
      expect(json_response.first['id']).to eq merge_request.id
    end

    it 'returns merge_request by iid array' do
      get v3_api("/projects/#{project.id}/merge_requests", user), iid: [merge_request.iid, merge_request_closed.iid]

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(2)
      expect(json_response.first['title']).to eq merge_request_closed.title
      expect(json_response.first['id']).to eq merge_request_closed.id
    end

    it "returns a 404 error if merge_request_id not found" do
      get v3_api("/projects/#{project.id}/merge_requests/999", user)
      expect(response).to have_gitlab_http_status(404)
    end

    context 'Work in Progress' do
      let!(:merge_request_wip) { create(:merge_request, author: user, assignee: user, source_project: project, target_project: project, title: "WIP: Test", created_at: base_time + 1.second) }

      it "returns merge_request" do
        get v3_api("/projects/#{project.id}/merge_requests/#{merge_request_wip.id}", user)
        expect(response).to have_gitlab_http_status(200)
        expect(json_response['work_in_progress']).to eq(true)
      end
    end
  end

  describe 'GET /projects/:id/merge_requests/:merge_request_id/commits' do
    it 'returns a 200 when merge request is valid' do
      get v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/commits", user)
      commit = merge_request.commits.first

      expect(response.status).to eq 200
      expect(json_response.size).to eq(merge_request.commits.size)
      expect(json_response.first['id']).to eq(commit.id)
      expect(json_response.first['title']).to eq(commit.title)
    end

    it 'returns a 404 when merge_request_id not found' do
      get v3_api("/projects/#{project.id}/merge_requests/999/commits", user)
      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'GET /projects/:id/merge_requests/:merge_request_id/changes' do
    it 'returns the change information of the merge_request' do
      get v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/changes", user)
      expect(response.status).to eq 200
      expect(json_response['changes'].size).to eq(merge_request.diffs.size)
    end

    it 'returns a 404 when merge_request_id not found' do
      get v3_api("/projects/#{project.id}/merge_requests/999/changes", user)
      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe "POST /projects/:id/merge_requests" do
    context 'between branches projects' do
      it "returns merge_request" do
        post v3_api("/projects/#{project.id}/merge_requests", user),
             title: 'Test merge_request',
             source_branch: 'feature_conflict',
             target_branch: 'master',
             author: user,
             labels: 'label, label2',
             milestone_id: milestone.id,
             remove_source_branch: true,
             squash: true

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['title']).to eq('Test merge_request')
        expect(json_response['labels']).to eq(%w(label label2))
        expect(json_response['milestone']['id']).to eq(milestone.id)
        expect(json_response['force_remove_source_branch']).to be_truthy
        expect(json_response['squash']).to be_truthy
      end

      it "returns 422 when source_branch equals target_branch" do
        post v3_api("/projects/#{project.id}/merge_requests", user),
        title: "Test merge_request", source_branch: "master", target_branch: "master", author: user
        expect(response).to have_gitlab_http_status(422)
      end

      it "returns 400 when source_branch is missing" do
        post v3_api("/projects/#{project.id}/merge_requests", user),
        title: "Test merge_request", target_branch: "master", author: user
        expect(response).to have_gitlab_http_status(400)
      end

      it "returns 400 when target_branch is missing" do
        post v3_api("/projects/#{project.id}/merge_requests", user),
        title: "Test merge_request", source_branch: "markdown", author: user
        expect(response).to have_gitlab_http_status(400)
      end

      it "returns 400 when title is missing" do
        post v3_api("/projects/#{project.id}/merge_requests", user),
        target_branch: 'master', source_branch: 'markdown'
        expect(response).to have_gitlab_http_status(400)
      end

      it 'allows special label names' do
        post v3_api("/projects/#{project.id}/merge_requests", user),
             title: 'Test merge_request',
             source_branch: 'markdown',
             target_branch: 'master',
             author: user,
             labels: 'label, label?, label&foo, ?, &'
        expect(response.status).to eq(201)
        expect(json_response['labels']).to include 'label'
        expect(json_response['labels']).to include 'label?'
        expect(json_response['labels']).to include 'label&foo'
        expect(json_response['labels']).to include '?'
        expect(json_response['labels']).to include '&'
      end

      context 'with existing MR' do
        before do
          post v3_api("/projects/#{project.id}/merge_requests", user),
               title: 'Test merge_request',
               source_branch: 'feature_conflict',
               target_branch: 'master',
               author: user
          @mr = MergeRequest.all.last
        end

        it 'returns 409 when MR already exists for source/target' do
          expect do
            post v3_api("/projects/#{project.id}/merge_requests", user),
                 title: 'New test merge_request',
                 source_branch: 'feature_conflict',
                 target_branch: 'master',
                 author: user
          end.to change { MergeRequest.count }.by(0)
          expect(response).to have_gitlab_http_status(409)
        end
      end
    end

    context 'forked projects' do
      let!(:user2) { create(:user) }
      let!(:forked_project) { fork_project(project, user2, repository: true) }
      let!(:unrelated_project) { create(:project,  namespace: create(:user).namespace, creator_id: user2.id) }

      before do
        forked_project.add_reporter(user2)
      end

      it "returns merge_request" do
        post v3_api("/projects/#{forked_project.id}/merge_requests", user2),
          title: 'Test merge_request', source_branch: "feature_conflict", target_branch: "master",
          author: user2, target_project_id: project.id, description: 'Test description for Test merge_request'
        expect(response).to have_gitlab_http_status(201)
        expect(json_response['title']).to eq('Test merge_request')
        expect(json_response['description']).to eq('Test description for Test merge_request')
      end

      it "does not return 422 when source_branch equals target_branch" do
        expect(project.id).not_to eq(forked_project.id)
        expect(forked_project.forked?).to be_truthy
        expect(forked_project.forked_from_project).to eq(project)
        post v3_api("/projects/#{forked_project.id}/merge_requests", user2),
        title: 'Test merge_request', source_branch: "master", target_branch: "master", author: user2, target_project_id: project.id
        expect(response).to have_gitlab_http_status(201)
        expect(json_response['title']).to eq('Test merge_request')
      end

      it "returns 403 when target project has disabled merge requests" do
        project.project_feature.update(merge_requests_access_level: 0)

        post v3_api("/projects/#{forked_project.id}/merge_requests", user2),
             title: 'Test',
             target_branch: "master",
             source_branch: 'markdown',
             author: user2,
             target_project_id: project.id

        expect(response).to have_gitlab_http_status(403)
      end

      it "returns 400 when source_branch is missing" do
        post v3_api("/projects/#{forked_project.id}/merge_requests", user2),
        title: 'Test merge_request', target_branch: "master", author: user2, target_project_id: project.id
        expect(response).to have_gitlab_http_status(400)
      end

      it "returns 400 when target_branch is missing" do
        post v3_api("/projects/#{forked_project.id}/merge_requests", user2),
        title: 'Test merge_request', target_branch: "master", author: user2, target_project_id: project.id
        expect(response).to have_gitlab_http_status(400)
      end

      it "returns 400 when title is missing" do
        post v3_api("/projects/#{forked_project.id}/merge_requests", user2),
        target_branch: 'master', source_branch: 'markdown', author: user2, target_project_id: project.id
        expect(response).to have_gitlab_http_status(400)
      end

      context 'when target_branch and target_project_id is specified' do
        let(:params) do
          { title: 'Test merge_request',
            target_branch: 'master',
            source_branch: 'markdown',
            author: user2,
            target_project_id: unrelated_project.id }
        end

        it 'returns 422 if targeting a different fork' do
          unrelated_project.add_developer(user2)

          post v3_api("/projects/#{forked_project.id}/merge_requests", user2), params

          expect(response).to have_gitlab_http_status(422)
        end

        it 'returns 403 if targeting a different fork which user can not access' do
          post v3_api("/projects/#{forked_project.id}/merge_requests", user2), params

          expect(response).to have_gitlab_http_status(403)
        end
      end

      it "returns 201 when target_branch is specified and for the same project" do
        post v3_api("/projects/#{forked_project.id}/merge_requests", user2),
        title: 'Test merge_request', target_branch: 'master', source_branch: 'markdown', author: user2, target_project_id: forked_project.id
        expect(response).to have_gitlab_http_status(201)
      end
    end

    context 'the approvals_before_merge param' do
      def create_merge_request(approvals_before_merge)
        post v3_api("/projects/#{project.id}/merge_requests", user),
             title: 'Test merge_request',
             source_branch: 'feature_conflict',
             target_branch: 'master',
             author: user,
             labels: 'label, label2',
             milestone_id: milestone.id,
             approvals_before_merge: approvals_before_merge
      end

      context 'when the target project has approvals_before_merge set to zero' do
        before do
          project.update_attributes(approvals_before_merge: 0)
          create_merge_request(1)
        end

        it 'returns a 400' do
          expect(response).to have_gitlab_http_status(400)
        end

        it 'includes the error in the response' do
          expect(json_response['message']['validate_approvals_before_merge']).not_to be_empty
        end
      end

      context 'when the target project has a non-zero approvals_before_merge' do
        context 'when the approvals_before_merge param is less than or equal to the value in the target project' do
          before do
            project.update_attributes(approvals_before_merge: 1)
            create_merge_request(1)
          end

          it 'returns a 400' do
            expect(response).to have_gitlab_http_status(400)
          end

          it 'includes the error in the response' do
            expect(json_response['message']['validate_approvals_before_merge']).not_to be_empty
          end
        end

        context 'when the approvals_before_merge param is greater than the value in the target project' do
          before do
            project.update_attributes(approvals_before_merge: 1)
            create_merge_request(2)
          end

          it 'returns a created status' do
            expect(response).to have_gitlab_http_status(201)
          end

          it 'sets approvals_before_merge of the newly-created MR' do
            expect(json_response['approvals_before_merge']).to eq(2)
          end
        end
      end
    end
  end

  describe "DELETE /projects/:id/merge_requests/:merge_request_id" do
    context "when the user is developer" do
      let(:developer) { create(:user) }

      before do
        project.add_developer(developer)
      end

      it "denies the deletion of the merge request" do
        delete v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}", developer)
        expect(response).to have_gitlab_http_status(403)
      end
    end

    context "when the user is project owner" do
      it "destroys the merge request owners can destroy" do
        delete v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}", user)

        expect(response).to have_gitlab_http_status(200)
      end
    end
  end

  describe "PUT /projects/:id/merge_requests/:merge_request_id/merge" do
    let(:pipeline) { create(:ci_pipeline_without_jobs) }

    it "returns merge_request in case of success" do
      put v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/merge", user)

      expect(response).to have_gitlab_http_status(200)
    end

    it "returns 406 if branch can't be merged" do
      allow_any_instance_of(MergeRequest)
        .to receive(:can_be_merged?).and_return(false)

      put v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/merge", user)

      expect(response).to have_gitlab_http_status(406)
      expect(json_response['message']).to eq('Branch cannot be merged')
    end

    it "returns 405 if merge_request is not open" do
      merge_request.close
      put v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/merge", user)
      expect(response).to have_gitlab_http_status(405)
      expect(json_response['message']).to eq('405 Method Not Allowed')
    end

    it "returns 405 if merge_request is a work in progress" do
      merge_request.update_attribute(:title, "WIP: #{merge_request.title}")
      put v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/merge", user)
      expect(response).to have_gitlab_http_status(405)
      expect(json_response['message']).to eq('405 Method Not Allowed')
    end

    it 'returns 405 if the build failed for a merge request that requires success' do
      allow_any_instance_of(MergeRequest).to receive(:mergeable_ci_state?).and_return(false)

      put v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/merge", user)

      expect(response).to have_gitlab_http_status(405)
      expect(json_response['message']).to eq('405 Method Not Allowed')
    end

    it "returns 401 if user has no permissions to merge" do
      user2 = create(:user)
      project.add_reporter(user2)
      put v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/merge", user2)
      expect(response).to have_gitlab_http_status(401)
      expect(json_response['message']).to eq('401 Unauthorized')
    end

    it "returns 409 if the SHA parameter doesn't match" do
      put v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/merge", user), sha: merge_request.diff_head_sha.reverse

      expect(response).to have_gitlab_http_status(409)
      expect(json_response['message']).to start_with('SHA does not match HEAD of source branch')
    end

    it "succeeds if the SHA parameter matches" do
      put v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/merge", user), sha: merge_request.diff_head_sha

      expect(response).to have_gitlab_http_status(200)
    end

    it "updates the MR's squash attribute" do
      expect do
        put v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/merge", user), squash: true
      end.to change { merge_request.reload.squash }

      expect(response).to have_gitlab_http_status(200)
    end

    it "enables merge when pipeline succeeds if the pipeline is active" do
      allow_any_instance_of(MergeRequest).to receive(:head_pipeline).and_return(pipeline)
      allow(pipeline).to receive(:active?).and_return(true)

      put v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/merge", user), merge_when_build_succeeds: true

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['title']).to eq('Test')
      expect(json_response['merge_when_build_succeeds']).to eq(true)
    end
  end

  describe "PUT /projects/:id/merge_requests/:merge_request_id" do
    context "to close a MR" do
      it "returns merge_request" do
        put v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}", user), state_event: "close"

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['state']).to eq('closed')
      end
    end

    it "updates title and returns merge_request" do
      put v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}", user), title: "New title"
      expect(response).to have_gitlab_http_status(200)
      expect(json_response['title']).to eq('New title')
    end

    it "updates description and returns merge_request" do
      put v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}", user), description: "New description"
      expect(response).to have_gitlab_http_status(200)
      expect(json_response['description']).to eq('New description')
    end

    it "updates milestone_id and returns merge_request" do
      put v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}", user), milestone_id: milestone.id
      expect(response).to have_gitlab_http_status(200)
      expect(json_response['milestone']['id']).to eq(milestone.id)
    end

    it "updates squash and returns merge_request" do
      put v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}", user), squash: true

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['squash']).to be_truthy
    end

    it "returns merge_request with renamed target_branch" do
      put v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}", user), target_branch: "wiki"
      expect(response).to have_gitlab_http_status(200)
      expect(json_response['target_branch']).to eq('wiki')
    end

    it "returns merge_request that removes the source branch" do
      put v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}", user), remove_source_branch: true

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['force_remove_source_branch']).to be_truthy
    end

    it 'allows special label names' do
      put v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}", user),
        title: 'new issue',
        labels: 'label, label?, label&foo, ?, &'

      expect(response.status).to eq(200)
      expect(json_response['labels']).to include 'label'
      expect(json_response['labels']).to include 'label?'
      expect(json_response['labels']).to include 'label&foo'
      expect(json_response['labels']).to include '?'
      expect(json_response['labels']).to include '&'
    end

    it 'does not update state when title is empty' do
      put v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}", user), state_event: 'close', title: nil

      merge_request.reload
      expect(response).to have_gitlab_http_status(400)
      expect(merge_request.state).to eq('opened')
    end

    it 'does not update state when target_branch is empty' do
      put v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}", user), state_event: 'close', target_branch: nil

      merge_request.reload
      expect(response).to have_gitlab_http_status(400)
      expect(merge_request.state).to eq('opened')
    end
  end

  describe "POST /projects/:id/merge_requests/:merge_request_id/comments" do
    it "returns comment" do
      original_count = merge_request.notes.size

      post v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/comments", user), note: "My comment"

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['note']).to eq('My comment')
      expect(json_response['author']['name']).to eq(user.name)
      expect(json_response['author']['username']).to eq(user.username)
      expect(merge_request.reload.notes.size).to eq(original_count + 1)
    end

    it "returns 400 if note is missing" do
      post v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/comments", user)
      expect(response).to have_gitlab_http_status(400)
    end

    it "returns 404 if note is attached to non existent merge request" do
      post v3_api("/projects/#{project.id}/merge_requests/404/comments", user),
        note: 'My comment'
      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe "GET :id/merge_requests/:merge_request_id/comments" do
    let!(:note)  { create(:note_on_merge_request, author: user, project: project, noteable: merge_request, note: "a comment on a MR") }
    let!(:note2) { create(:note_on_merge_request, author: user, project: project, noteable: merge_request, note: "another comment on a MR") }

    it "returns merge_request comments ordered by created_at" do
      get v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/comments", user)
      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(2)
      expect(json_response.first['note']).to eq("a comment on a MR")
      expect(json_response.first['author']['id']).to eq(user.id)
      expect(json_response.last['note']).to eq("another comment on a MR")
    end

    it "returns a 404 error if merge_request_id not found" do
      get v3_api("/projects/#{project.id}/merge_requests/999/comments", user)
      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'GET :id/merge_requests/:merge_request_id/closes_issues' do
    it 'returns the issue that will be closed on merge' do
      issue = create(:issue, project: project)
      mr = merge_request.tap do |mr|
        mr.update_attribute(:description, "Closes #{issue.to_reference(mr.project)}")
      end

      get v3_api("/projects/#{project.id}/merge_requests/#{mr.id}/closes_issues", user)
      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['id']).to eq(issue.id)
    end

    it 'returns an empty array when there are no issues to be closed' do
      get v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/closes_issues", user)
      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(0)
    end

    it 'handles external issues' do
      jira_project = create(:jira_project, :public, :repository, name: 'JIR_EXT1')
      issue = ExternalIssue.new("#{jira_project.name}-123", jira_project)
      merge_request = create(:merge_request, :simple, author: user, assignee: user, source_project: jira_project)
      merge_request.update_attribute(:description, "Closes #{issue.to_reference(jira_project)}")

      get v3_api("/projects/#{jira_project.id}/merge_requests/#{merge_request.id}/closes_issues", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['title']).to eq(issue.title)
      expect(json_response.first['id']).to eq(issue.id)
    end

    it 'returns 403 if the user has no access to the merge request' do
      project = create(:project, :private, :repository)
      merge_request = create(:merge_request, :simple, source_project: project)
      guest = create(:user)
      project.add_guest(guest)

      get v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/closes_issues", guest)

      expect(response).to have_gitlab_http_status(403)
    end
  end

  describe 'POST :id/merge_requests/:merge_request_id/subscription' do
    it 'subscribes to a merge request' do
      post v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/subscription", admin)

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['subscribed']).to eq(true)
    end

    it 'returns 304 if already subscribed' do
      post v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/subscription", user)

      expect(response).to have_gitlab_http_status(304)
    end

    it 'returns 404 if the merge request is not found' do
      post v3_api("/projects/#{project.id}/merge_requests/123/subscription", user)

      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns 403 if user has no access to read code' do
      guest = create(:user)
      project.add_guest(guest)

      post v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/subscription", guest)

      expect(response).to have_gitlab_http_status(403)
    end
  end

  describe 'DELETE :id/merge_requests/:merge_request_id/subscription' do
    it 'unsubscribes from a merge request' do
      delete v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/subscription", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['subscribed']).to eq(false)
    end

    it 'returns 304 if not subscribed' do
      delete v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/subscription", admin)

      expect(response).to have_gitlab_http_status(304)
    end

    it 'returns 404 if the merge request is not found' do
      post v3_api("/projects/#{project.id}/merge_requests/123/subscription", user)

      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns 403 if user has no access to read code' do
      guest = create(:user)
      project.add_guest(guest)

      delete v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/subscription", guest)

      expect(response).to have_gitlab_http_status(403)
    end
  end

  describe 'GET :id/merge_requests/:merge_request_id/approvals' do
    it 'retrieves the approval status' do
      approver = create :user
      project.update_attribute(:approvals_before_merge, 2)
      project.add_developer(approver)
      project.add_developer(create(:user))
      merge_request.approvals.create(user: approver)

      get v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/approvals", user)

      expect(response.status).to eq(200)
      expect(json_response['approvals_required']).to eq 2
      expect(json_response['approvals_left']).to eq 1
      expect(json_response['approved_by'][0]['user']['username']).to eq(approver.username)
      expect(json_response['user_can_approve']).to be false
      expect(json_response['user_has_approved']).to be false
    end
  end

  describe 'POST :id/merge_requests/:merge_request_id/approve' do
    before { project.update_attribute(:approvals_before_merge, 2) }

    context 'as the author of the merge request' do
      before { post v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/approve", user) }

      it 'returns a 401' do
        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'as a valid approver' do
      let(:approver) { create(:user) }

      before do
        project.add_developer(approver)
        project.add_developer(create(:user))

        post v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/approve", approver)
      end

      it 'approves the merge request' do
        expect(response.status).to eq(201)
        expect(json_response['approvals_left']).to eq(1)
        expect(json_response['approved_by'][0]['user']['username']).to eq(approver.username)
        expect(json_response['user_has_approved']).to be true
      end
    end
  end

  describe 'DELETE :id/merge_requests/:merge_request_id/unapprove' do
    before { project.update_attribute(:approvals_before_merge, 2) }

    context 'as a user who has approved the merge request' do
      let(:approver) { create(:user) }
      let(:unapprover) { create(:user) }

      before do
        project.add_developer(approver)
        project.add_developer(unapprover)
        project.add_developer(create(:user))
        merge_request.approvals.create(user: approver)
        merge_request.approvals.create(user: unapprover)

        delete v3_api("/projects/#{project.id}/merge_requests/#{merge_request.id}/unapprove", unapprover)
      end

      it 'unapproves the merge request' do
        expect(response.status).to eq(200)
        expect(json_response['approvals_left']).to eq(1)
        usernames = json_response['approved_by'].map { |u| u['user']['username'] }
        expect(usernames).not_to include(unapprover.username)
        expect(usernames.size).to be 1
        expect(json_response['user_has_approved']).to be false
        expect(json_response['user_can_approve']).to be true
      end
    end
  end

  describe 'Time tracking' do
    let(:issuable) { merge_request }

    include_examples 'V3 time tracking endpoints', 'merge_request'
  end

  def mr_with_later_created_and_updated_at_time
    merge_request
    merge_request.created_at += 1.hour
    merge_request.updated_at += 30.minutes
    merge_request.save
    merge_request
  end

  def mr_with_earlier_created_and_updated_at_time
    merge_request_closed
    merge_request_closed.created_at -= 1.hour
    merge_request_closed.updated_at -= 30.minutes
    merge_request_closed.save
    merge_request_closed
  end
end
