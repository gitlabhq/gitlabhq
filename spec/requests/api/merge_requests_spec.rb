require "spec_helper"

describe API::MergeRequests do
  include ProjectForksHelper

  let(:base_time)   { Time.now }
  let(:user)        { create(:user) }
  let(:admin)       { create(:user, :admin) }
  let(:non_member)  { create(:user) }
  let!(:project)    { create(:project, :public, :repository, creator: user, namespace: user.namespace, only_allow_merge_if_pipeline_succeeds: false) }
  let(:milestone)   { create(:milestone, title: '1.0.0', project: project) }
  let(:pipeline)    { create(:ci_empty_pipeline) }
  let(:milestone1)   { create(:milestone, title: '0.9', project: project) }
  let!(:merge_request) { create(:merge_request, :simple, milestone: milestone1, author: user, assignee: user, source_project: project, target_project: project, title: "Test", created_at: base_time) }
  let!(:merge_request_closed) { create(:merge_request, state: "closed", milestone: milestone1, author: user, assignee: user, source_project: project, target_project: project, title: "Closed test", created_at: base_time + 1.second) }
  let!(:merge_request_merged) { create(:merge_request, state: "merged", author: user, assignee: user, source_project: project, target_project: project, title: "Merged test", created_at: base_time + 2.seconds, merge_commit_sha: '9999999999999999999999999999999999999999') }
  let!(:note)       { create(:note_on_merge_request, author: user, project: project, noteable: merge_request, note: "a comment on a MR") }
  let!(:note2)      { create(:note_on_merge_request, author: user, project: project, noteable: merge_request, note: "another comment on a MR") }
  let!(:label) do
    create(:label, title: 'label', color: '#FFAABB', project: project)
  end
  let!(:label2) { create(:label, title: 'a-test', color: '#FFFFFF', project: project) }
  let!(:label_link) { create(:label_link, label: label, target: merge_request) }
  let!(:label_link2) { create(:label_link, label: label2, target: merge_request) }
  let!(:downvote) { create(:award_emoji, :downvote, awardable: merge_request) }
  let!(:upvote) { create(:award_emoji, :upvote, awardable: merge_request) }

  before do
    project.add_reporter(user)
  end

  describe 'GET /merge_requests' do
    context 'when unauthenticated' do
      it 'returns an array of all merge requests' do
        get api('/merge_requests', user), scope: 'all'

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
      end

      it "returns authentication error without any scope" do
        get api("/merge_requests")

        expect(response).to have_gitlab_http_status(401)
      end

      it "returns authentication error  when scope is assigned-to-me" do
        get api("/merge_requests"), scope: 'assigned-to-me'

        expect(response).to have_gitlab_http_status(401)
      end

      it "returns authentication error  when scope is created-by-me" do
        get api("/merge_requests"), scope: 'created-by-me'

        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'when authenticated' do
      let!(:project2) { create(:project, :public, namespace: user.namespace) }
      let!(:merge_request2) { create(:merge_request, :simple, author: user, assignee: user, source_project: project2, target_project: project2) }
      let(:user2) { create(:user) }

      it 'returns an array of all merge requests' do
        get api('/merge_requests', user), scope: :all

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.map { |mr| mr['id'] })
          .to contain_exactly(merge_request.id, merge_request_closed.id, merge_request_merged.id, merge_request2.id)
      end

      it 'does not return unauthorized merge requests' do
        private_project = create(:project, :private)
        merge_request3 = create(:merge_request, :simple, source_project: private_project, target_project: private_project, source_branch: 'other-branch')

        get api('/merge_requests', user), scope: :all

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.map { |mr| mr['id'] })
          .not_to include(merge_request3.id)
      end

      it 'returns an array of merge requests created by current user if no scope is given' do
        merge_request3 = create(:merge_request, :simple, author: user2, assignee: user, source_project: project2, target_project: project2, source_branch: 'other-branch')

        get api('/merge_requests', user2)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(merge_request3.id)
      end

      it 'returns an array of merge requests authored by the given user' do
        merge_request3 = create(:merge_request, :simple, author: user2, assignee: user, source_project: project2, target_project: project2, source_branch: 'other-branch')

        get api('/merge_requests', user), author_id: user2.id, scope: :all

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(merge_request3.id)
      end

      it 'returns an array of merge requests assigned to the given user' do
        merge_request3 = create(:merge_request, :simple, author: user, assignee: user2, source_project: project2, target_project: project2, source_branch: 'other-branch')

        get api('/merge_requests', user), assignee_id: user2.id, scope: :all

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(merge_request3.id)
      end

      it 'returns an array of merge requests assigned to me' do
        merge_request3 = create(:merge_request, :simple, author: user, assignee: user2, source_project: project2, target_project: project2, source_branch: 'other-branch')

        get api('/merge_requests', user2), scope: 'assigned-to-me'

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(merge_request3.id)
      end

      it 'returns an array of merge requests created by me' do
        merge_request3 = create(:merge_request, :simple, author: user2, assignee: user, source_project: project2, target_project: project2, source_branch: 'other-branch')

        get api('/merge_requests', user2), scope: 'created-by-me'

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(merge_request3.id)
      end

      it 'returns merge requests reacted by the authenticated user by the given emoji' do
        merge_request3 = create(:merge_request, :simple, author: user, assignee: user, source_project: project2, target_project: project2, source_branch: 'other-branch')
        award_emoji = create(:award_emoji, awardable: merge_request3, user: user2, name: 'star')

        get api('/merge_requests', user2), my_reaction_emoji: award_emoji.name, scope: 'all'

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(merge_request3.id)
      end

      context 'source_branch param' do
        it 'returns merge requests with the given source branch' do
          get api('/merge_requests', user), source_branch: merge_request_closed.source_branch, state: 'all'

          expect(json_response.length).to eq(2)
          expect(json_response.map { |mr| mr['id'] })
            .to contain_exactly(merge_request_closed.id, merge_request_merged.id)
        end
      end

      context 'target_branch param' do
        it 'returns merge requests with the given target branch' do
          get api('/merge_requests', user), target_branch: merge_request_closed.target_branch, state: 'all'

          expect(json_response.length).to eq(2)
          expect(json_response.map { |mr| mr['id'] })
            .to contain_exactly(merge_request_closed.id, merge_request_merged.id)
        end
      end

      it 'returns merge requests created before a specific date' do
        merge_request2 = create(:merge_request, :simple, source_project: project, target_project: project, source_branch: 'feature_1', created_at: Date.new(2000, 1, 1))

        get api('/merge_requests?created_before=2000-01-02T00:00:00.060Z', user)

        expect(json_response.size).to eq(1)
        expect(json_response.first['id']).to eq(merge_request2.id)
      end

      it 'returns merge requests created after a specific date' do
        merge_request2 = create(:merge_request, :simple, source_project: project, target_project: project, source_branch: 'feature_1', created_at: 1.week.from_now)

        get api("/merge_requests?created_after=#{merge_request2.created_at}", user)

        expect(json_response.size).to eq(1)
        expect(json_response.first['id']).to eq(merge_request2.id)
      end

      it 'returns merge requests updated before a specific date' do
        merge_request2 = create(:merge_request, :simple, source_project: project, target_project: project, source_branch: 'feature_1', updated_at: Date.new(2000, 1, 1))

        get api('/merge_requests?updated_before=2000-01-02T00:00:00.060Z', user)

        expect(json_response.size).to eq(1)
        expect(json_response.first['id']).to eq(merge_request2.id)
      end

      it 'returns merge requests updated after a specific date' do
        merge_request2 = create(:merge_request, :simple, source_project: project, target_project: project, source_branch: 'feature_1', updated_at: 1.week.from_now)

        get api("/merge_requests?updated_after=#{merge_request2.updated_at}", user)

        expect(json_response.size).to eq(1)
        expect(json_response.first['id']).to eq(merge_request2.id)
      end

      context 'search params' do
        before do
          merge_request.update(title: 'Search title', description: 'Search description')
        end

        it 'returns merge requests matching given search string for title' do
          get api("/merge_requests", user), search: merge_request.title

          expect(json_response.length).to eq(1)
          expect(json_response.first['id']).to eq(merge_request.id)
        end

        it 'returns merge requests for project matching given search string for description' do
          get api("/merge_requests", user), project_id: project.id, search: merge_request.description

          expect(json_response.length).to eq(1)
          expect(json_response.first['id']).to eq(merge_request.id)
        end
      end
    end
  end

  describe "GET /projects/:id/merge_requests" do
    context "when unauthenticated" do
      it 'returns merge requests for public projects' do
        get api("/projects/#{project.id}/merge_requests")

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
      end

      it "returns 404 for non public projects" do
        project = create(:project, :private)
        get api("/projects/#{project.id}/merge_requests")

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context "when authenticated" do
      it 'avoids N+1 queries' do
        control = ActiveRecord::QueryRecorder.new do
          get api("/projects/#{project.id}/merge_requests", user)
        end

        create(:merge_request, state: 'closed', milestone: milestone1, author: user, assignee: user, source_project: project, target_project: project, title: "Test", created_at: base_time)

        create(:merge_request, milestone: milestone1, author: user, assignee: user, source_project: project, target_project: project, title: "Test", created_at: base_time)

        expect do
          get api("/projects/#{project.id}/merge_requests", user)
        end.not_to exceed_query_limit(control)
      end

      it "returns an array of all merge_requests" do
        get api("/projects/#{project.id}/merge_requests", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(3)
        expect(json_response.last['title']).to eq(merge_request.title)
        expect(json_response.last).to have_key('web_url')
        expect(json_response.last['sha']).to eq(merge_request.diff_head_sha)
        expect(json_response.last['merge_commit_sha']).to be_nil
        expect(json_response.last['merge_commit_sha']).to eq(merge_request.merge_commit_sha)
        expect(json_response.last['downvotes']).to eq(1)
        expect(json_response.last['upvotes']).to eq(1)
        expect(json_response.last['labels']).to eq([label2.title, label.title])
        expect(json_response.first['title']).to eq(merge_request_merged.title)
        expect(json_response.first['sha']).to eq(merge_request_merged.diff_head_sha)
        expect(json_response.first['merge_commit_sha']).not_to be_nil
        expect(json_response.first['merge_commit_sha']).to eq(merge_request_merged.merge_commit_sha)
      end

      it "returns an array of all merge_requests using simple mode" do
        get api("/projects/#{project.id}/merge_requests?view=simple", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response.last.keys).to match_array(%w(id iid title web_url created_at description project_id state updated_at))
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(3)
        expect(json_response.last['iid']).to eq(merge_request.iid)
        expect(json_response.last['title']).to eq(merge_request.title)
        expect(json_response.last).to have_key('web_url')
        expect(json_response.first['iid']).to eq(merge_request_merged.iid)
        expect(json_response.first['title']).to eq(merge_request_merged.title)
        expect(json_response.first).to have_key('web_url')
      end

      it "returns an array of all merge_requests" do
        get api("/projects/#{project.id}/merge_requests?state", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(3)
        expect(json_response.last['title']).to eq(merge_request.title)
      end

      it "returns an array of open merge_requests" do
        get api("/projects/#{project.id}/merge_requests?state=opened", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.last['title']).to eq(merge_request.title)
      end

      it "returns an array of closed merge_requests" do
        get api("/projects/#{project.id}/merge_requests?state=closed", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['title']).to eq(merge_request_closed.title)
      end

      it "returns an array of merged merge_requests" do
        get api("/projects/#{project.id}/merge_requests?state=merged", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['title']).to eq(merge_request_merged.title)
      end

      it 'returns merge_request by "iids" array' do
        get api("/projects/#{project.id}/merge_requests", user), iids: [merge_request.iid, merge_request_closed.iid]

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(2)
        expect(json_response.first['title']).to eq merge_request_closed.title
        expect(json_response.first['id']).to eq merge_request_closed.id
      end

      it 'matches V4 response schema' do
        get api("/projects/#{project.id}/merge_requests", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/merge_requests')
      end

      it 'returns an empty array if no issue matches milestone' do
        get api("/projects/#{project.id}/merge_requests", user), milestone: '1.0.0'

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(0)
      end

      it 'returns an empty array if milestone does not exist' do
        get api("/projects/#{project.id}/merge_requests", user), milestone: 'foo'

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(0)
      end

      it 'returns an array of merge requests in given milestone' do
        get api("/projects/#{project.id}/merge_requests", user), milestone: '0.9'

        expect(json_response.first['title']).to eq merge_request_closed.title
        expect(json_response.first['id']).to eq merge_request_closed.id
      end

      it 'returns an array of merge requests matching state in milestone' do
        get api("/projects/#{project.id}/merge_requests", user), milestone: '0.9', state: 'closed'

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(merge_request_closed.id)
      end

      it 'returns an array of labeled merge requests' do
        get api("/projects/#{project.id}/merge_requests?labels=#{label.title}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['labels']).to eq([label2.title, label.title])
      end

      it 'returns an array of labeled merge requests where all labels match' do
        get api("/projects/#{project.id}/merge_requests?labels=#{label.title},foo,bar", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(0)
      end

      it 'returns an empty array if no merge request matches labels' do
        get api("/projects/#{project.id}/merge_requests?labels=foo,bar", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(0)
      end

      it 'returns an array of labeled merge requests that are merged for a milestone' do
        bug_label = create(:label, title: 'bug', color: '#FFAABB', project: project)

        mr1 = create(:merge_request, state: "merged", source_project: project, target_project: project, milestone: milestone)
        mr2 = create(:merge_request, state: "merged", source_project: project, target_project: project, milestone: milestone1)
        mr3 = create(:merge_request, state: "closed", source_project: project, target_project: project, milestone: milestone1)
        _mr = create(:merge_request, state: "merged", source_project: project, target_project: project, milestone: milestone1)

        create(:label_link, label: bug_label, target: mr1)
        create(:label_link, label: bug_label, target: mr2)
        create(:label_link, label: bug_label, target: mr3)

        get api("/projects/#{project.id}/merge_requests?labels=#{bug_label.title}&milestone=#{milestone1.title}&state=merged", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(mr2.id)
      end

      context "with ordering" do
        before do
          @mr_later = mr_with_later_created_and_updated_at_time
          @mr_earlier = mr_with_earlier_created_and_updated_at_time
        end

        it "returns an array of merge_requests in ascending order" do
          get api("/projects/#{project.id}/merge_requests?sort=asc", user)

          expect(response).to have_gitlab_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(3)
          response_dates = json_response.map { |merge_request| merge_request['created_at'] }
          expect(response_dates).to eq(response_dates.sort)
        end

        it "returns an array of merge_requests in descending order" do
          get api("/projects/#{project.id}/merge_requests?sort=desc", user)

          expect(response).to have_gitlab_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(3)
          response_dates = json_response.map { |merge_request| merge_request['created_at'] }
          expect(response_dates).to eq(response_dates.sort.reverse)
        end

        it "returns an array of merge_requests ordered by updated_at" do
          get api("/projects/#{project.id}/merge_requests?order_by=updated_at", user)

          expect(response).to have_gitlab_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(3)
          response_dates = json_response.map { |merge_request| merge_request['updated_at'] }
          expect(response_dates).to eq(response_dates.sort.reverse)
        end

        it "returns an array of merge_requests ordered by created_at" do
          get api("/projects/#{project.id}/merge_requests?order_by=created_at&sort=asc", user)

          expect(response).to have_gitlab_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(3)
          response_dates = json_response.map { |merge_request| merge_request['created_at'] }
          expect(response_dates).to eq(response_dates.sort)
        end
      end

      context 'source_branch param' do
        it 'returns merge requests with the given source branch' do
          get api('/merge_requests', user), source_branch: merge_request_closed.source_branch, state: 'all'

          expect(json_response.length).to eq(2)
          expect(json_response.map { |mr| mr['id'] })
            .to contain_exactly(merge_request_closed.id, merge_request_merged.id)
        end
      end

      context 'target_branch param' do
        it 'returns merge requests with the given target branch' do
          get api('/merge_requests', user), target_branch: merge_request_closed.target_branch, state: 'all'

          expect(json_response.length).to eq(2)
          expect(json_response.map { |mr| mr['id'] })
            .to contain_exactly(merge_request_closed.id, merge_request_merged.id)
        end
      end
    end
  end

  describe "GET /projects/:id/merge_requests/:merge_request_iid" do
    it 'exposes known attributes' do
      get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}", user)

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
      expect(json_response['milestone']).to be_a Hash
      expect(json_response['assignee']).to be_a Hash
      expect(json_response['author']).to be_a Hash
      expect(json_response['target_branch']).to eq(merge_request.target_branch)
      expect(json_response['source_branch']).to eq(merge_request.source_branch)
      expect(json_response['upvotes']).to eq(1)
      expect(json_response['downvotes']).to eq(1)
      expect(json_response['source_project_id']).to eq(merge_request.source_project.id)
      expect(json_response['target_project_id']).to eq(merge_request.target_project.id)
      expect(json_response['work_in_progress']).to be_falsy
      expect(json_response['merge_when_pipeline_succeeds']).to be_falsy
      expect(json_response['merge_status']).to eq('can_be_merged')
      expect(json_response['should_close_merge_request']).to be_falsy
      expect(json_response['force_close_merge_request']).to be_falsy
      expect(json_response['changes_count']).to eq(merge_request.merge_request_diff.real_size)
    end

    context 'merge_request_metrics' do
      before do
        merge_request.metrics.update!(merged_by: user,
                                      latest_closed_by: user,
                                      latest_closed_at: 1.hour.ago,
                                      merged_at: 2.hours.ago,
                                      pipeline: pipeline,
                                      latest_build_started_at: 3.hours.ago,
                                      latest_build_finished_at: 1.hour.ago,
                                      first_deployed_to_production_at: 3.minutes.ago)
      end

      it 'has fields from merge request metrics' do
        get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}", user)

        expect(json_response).to include('merged_by',
          'merged_at',
          'closed_by',
          'closed_at',
          'latest_build_started_at',
          'latest_build_finished_at',
          'first_deployed_to_production_at',
          'pipeline')
      end

      it 'returns correct values' do
        get api("/projects/#{project.id}/merge_requests/#{merge_request.reload.iid}", user)

        expect(json_response['merged_by']['id']).to eq(merge_request.metrics.merged_by_id)
        expect(Time.parse json_response['merged_at']).to be_like_time(merge_request.metrics.merged_at)
        expect(json_response['closed_by']['id']).to eq(merge_request.metrics.latest_closed_by_id)
        expect(Time.parse json_response['closed_at']).to be_like_time(merge_request.metrics.latest_closed_at)
        expect(json_response['pipeline']['id']).to eq(merge_request.metrics.pipeline_id)
        expect(Time.parse json_response['latest_build_started_at']).to be_like_time(merge_request.metrics.latest_build_started_at)
        expect(Time.parse json_response['latest_build_finished_at']).to be_like_time(merge_request.metrics.latest_build_finished_at)
        expect(Time.parse json_response['first_deployed_to_production_at']).to be_like_time(merge_request.metrics.first_deployed_to_production_at)
      end
    end

    it "returns a 404 error if merge_request_iid not found" do
      get api("/projects/#{project.id}/merge_requests/999", user)
      expect(response).to have_gitlab_http_status(404)
    end

    it "returns a 404 error if merge_request `id` is used instead of iid" do
      get api("/projects/#{project.id}/merge_requests/#{merge_request.id}", user)

      expect(response).to have_gitlab_http_status(404)
    end

    context 'Work in Progress' do
      let!(:merge_request_wip) { create(:merge_request, author: user, assignee: user, source_project: project, target_project: project, title: "WIP: Test", created_at: base_time + 1.second) }

      it "returns merge request" do
        get api("/projects/#{project.id}/merge_requests/#{merge_request_wip.iid}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['work_in_progress']).to eq(true)
      end
    end

    context 'when a merge request has more than the changes limit' do
      it "returns a string indicating that more changes were made" do
        stub_const('Commit::DIFF_HARD_LIMIT_FILES', 5)

        merge_request_overflow = create(:merge_request, :simple,
                                        author: user,
                                        assignee: user,
                                        source_project: project,
                                        source_branch: 'expand-collapse-files',
                                        target_project: project,
                                        target_branch: 'master')

        get api("/projects/#{project.id}/merge_requests/#{merge_request_overflow.iid}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['changes_count']).to eq('5+')
      end
    end

    context 'for forked projects' do
      let(:user2) { create(:user) }
      let(:project) { create(:project, :public, :repository) }
      let(:forked_project) { fork_project(project, user2, repository: true) }
      let(:merge_request) do
        create(:merge_request,
               source_project: forked_project,
               target_project: project,
               source_branch: 'fixes',
               allow_maintainer_to_push: true)
      end

      it 'includes the `allow_maintainer_to_push` field' do
        get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}", user)

        expect(json_response['allow_maintainer_to_push']).to be_truthy
      end
    end
  end

  describe 'GET /projects/:id/merge_requests/:merge_request_iid/participants' do
    it_behaves_like 'issuable participants endpoint' do
      let(:entity) { merge_request }
    end
  end

  describe 'GET /projects/:id/merge_requests/:merge_request_iid/commits' do
    it 'returns a 200 when merge request is valid' do
      get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/commits", user)
      commit = merge_request.commits.first

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(merge_request.commits.size)
      expect(json_response.first['id']).to eq(commit.id)
      expect(json_response.first['title']).to eq(commit.title)
    end

    it 'returns a 404 when merge_request_iid not found' do
      get api("/projects/#{project.id}/merge_requests/999/commits", user)
      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns a 404 when merge_request id is used instead of iid' do
      get api("/projects/#{project.id}/merge_requests/#{merge_request.id}/commits", user)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'GET /projects/:id/merge_requests/:merge_request_iid/changes' do
    it 'returns the change information of the merge_request' do
      get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/changes", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['changes'].size).to eq(merge_request.diffs.size)
    end

    it 'returns a 404 when merge_request_iid not found' do
      get api("/projects/#{project.id}/merge_requests/999/changes", user)
      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns a 404 when merge_request id is used instead of iid' do
      get api("/projects/#{project.id}/merge_requests/#{merge_request.id}/changes", user)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'GET /projects/:id/merge_requests/:merge_request_iid/pipelines' do
    context 'when authorized' do
      let!(:pipeline) { create(:ci_empty_pipeline, project: project, user: user, ref: merge_request.source_branch, sha: merge_request.diff_head_sha) }
      let!(:pipeline2) { create(:ci_empty_pipeline, project: project) }

      it 'returns a paginated array of corresponding pipelines' do
        get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/pipelines")

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.count).to eq(1)
        expect(json_response.first['id']).to eq(pipeline.id)
      end

      it 'exposes basic attributes' do
        get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/pipelines")

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/pipelines')
      end

      it 'returns 404 if MR does not exist' do
        get api("/projects/#{project.id}/merge_requests/777/pipelines")

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when unauthorized' do
      it 'returns 403' do
        project = create(:project, public_builds: false)
        merge_request = create(:merge_request, :simple, source_project: project)
        guest = create(:user)
        project.add_guest(guest)

        get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/pipelines", guest)

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end

  describe "POST /projects/:id/merge_requests" do
    context 'between branches projects' do
      it "returns merge_request" do
        post api("/projects/#{project.id}/merge_requests", user),
             title: 'Test merge_request',
             source_branch: 'feature_conflict',
             target_branch: 'master',
             author: user,
             labels: 'label, label2',
             milestone_id: milestone.id

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['title']).to eq('Test merge_request')
        expect(json_response['labels']).to eq(%w(label label2))
        expect(json_response['milestone']['id']).to eq(milestone.id)
        expect(json_response['force_remove_source_branch']).to be_falsy
      end

      it "returns 422 when source_branch equals target_branch" do
        post api("/projects/#{project.id}/merge_requests", user),
        title: "Test merge_request", source_branch: "master", target_branch: "master", author: user
        expect(response).to have_gitlab_http_status(422)
      end

      it "returns 400 when source_branch is missing" do
        post api("/projects/#{project.id}/merge_requests", user),
        title: "Test merge_request", target_branch: "master", author: user
        expect(response).to have_gitlab_http_status(400)
      end

      it "returns 400 when target_branch is missing" do
        post api("/projects/#{project.id}/merge_requests", user),
        title: "Test merge_request", source_branch: "markdown", author: user
        expect(response).to have_gitlab_http_status(400)
      end

      it "returns 400 when title is missing" do
        post api("/projects/#{project.id}/merge_requests", user),
        target_branch: 'master', source_branch: 'markdown'
        expect(response).to have_gitlab_http_status(400)
      end

      it 'allows special label names' do
        post api("/projects/#{project.id}/merge_requests", user),
             title: 'Test merge_request',
             source_branch: 'markdown',
             target_branch: 'master',
             author: user,
             labels: 'label, label?, label&foo, ?, &'
        expect(response).to have_gitlab_http_status(201)
        expect(json_response['labels']).to include 'label'
        expect(json_response['labels']).to include 'label?'
        expect(json_response['labels']).to include 'label&foo'
        expect(json_response['labels']).to include '?'
        expect(json_response['labels']).to include '&'
      end

      context 'with existing MR' do
        before do
          post api("/projects/#{project.id}/merge_requests", user),
               title: 'Test merge_request',
               source_branch: 'feature_conflict',
               target_branch: 'master',
               author: user
          @mr = MergeRequest.all.last
        end

        it 'returns 409 when MR already exists for source/target' do
          expect do
            post api("/projects/#{project.id}/merge_requests", user),
                 title: 'New test merge_request',
                 source_branch: 'feature_conflict',
                 target_branch: 'master',
                 author: user
          end.to change { MergeRequest.count }.by(0)
          expect(response).to have_gitlab_http_status(409)
        end
      end

      context 'accepts remove_source_branch parameter' do
        let(:params) do
          { title: 'Test merge_request',
            source_branch: 'markdown',
            target_branch: 'master',
            author: user }
        end

        it 'sets force_remove_source_branch to false' do
          post api("/projects/#{project.id}/merge_requests", user), params.merge(remove_source_branch: false)

          expect(json_response['force_remove_source_branch']).to be_falsy
        end

        it 'sets force_remove_source_branch to true' do
          post api("/projects/#{project.id}/merge_requests", user), params.merge(remove_source_branch: true)

          expect(json_response['force_remove_source_branch']).to be_truthy
        end
      end
    end

    context 'forked projects' do
      let!(:user2) { create(:user) }
      let(:project) { create(:project, :public, :repository) }
      let!(:forked_project) { fork_project(project, user2, repository: true) }
      let!(:unrelated_project) { create(:project,  namespace: create(:user).namespace, creator_id: user2.id) }

      before do
        forked_project.add_reporter(user2)
      end

      it "returns merge_request" do
        post api("/projects/#{forked_project.id}/merge_requests", user2),
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
        post api("/projects/#{forked_project.id}/merge_requests", user2),
        title: 'Test merge_request', source_branch: "master", target_branch: "master", author: user2, target_project_id: project.id
        expect(response).to have_gitlab_http_status(201)
        expect(json_response['title']).to eq('Test merge_request')
      end

      it 'returns 422 when target project has disabled merge requests' do
        project.project_feature.update(merge_requests_access_level: 0)

        post api("/projects/#{forked_project.id}/merge_requests", user2),
             title: 'Test',
             target_branch: 'master',
             source_branch: 'markdown',
             author: user2,
             target_project_id: project.id

        expect(response).to have_gitlab_http_status(422)
      end

      it "returns 400 when source_branch is missing" do
        post api("/projects/#{forked_project.id}/merge_requests", user2),
        title: 'Test merge_request', target_branch: "master", author: user2, target_project_id: project.id
        expect(response).to have_gitlab_http_status(400)
      end

      it "returns 400 when target_branch is missing" do
        post api("/projects/#{forked_project.id}/merge_requests", user2),
        title: 'Test merge_request', target_branch: "master", author: user2, target_project_id: project.id
        expect(response).to have_gitlab_http_status(400)
      end

      it "returns 400 when title is missing" do
        post api("/projects/#{forked_project.id}/merge_requests", user2),
        target_branch: 'master', source_branch: 'markdown', author: user2, target_project_id: project.id
        expect(response).to have_gitlab_http_status(400)
      end

      it 'allows setting `allow_maintainer_to_push`' do
        post api("/projects/#{forked_project.id}/merge_requests", user2),
          title: 'Test merge_request', source_branch: "feature_conflict", target_branch: "master",
          author: user2, target_project_id: project.id, allow_maintainer_to_push: true
        expect(response).to have_gitlab_http_status(201)
        expect(json_response['allow_maintainer_to_push']).to be_truthy
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

          post api("/projects/#{forked_project.id}/merge_requests", user2), params

          expect(response).to have_gitlab_http_status(422)
        end

        it 'returns 403 if targeting a different fork which user can not access' do
          post api("/projects/#{forked_project.id}/merge_requests", user2), params

          expect(response).to have_gitlab_http_status(403)
        end
      end

      it "returns 201 when target_branch is specified and for the same project" do
        post api("/projects/#{forked_project.id}/merge_requests", user2),
        title: 'Test merge_request', target_branch: 'master', source_branch: 'markdown', author: user2, target_project_id: forked_project.id
        expect(response).to have_gitlab_http_status(201)
      end
    end
  end

  describe "DELETE /projects/:id/merge_requests/:merge_request_iid" do
    context "when the user is developer" do
      let(:developer) { create(:user) }

      before do
        project.add_developer(developer)
      end

      it "denies the deletion of the merge request" do
        delete api("/projects/#{project.id}/merge_requests/#{merge_request.iid}", developer)
        expect(response).to have_gitlab_http_status(403)
      end
    end

    context "when the user is project owner" do
      it "destroys the merge request owners can destroy" do
        delete api("/projects/#{project.id}/merge_requests/#{merge_request.iid}", user)

        expect(response).to have_gitlab_http_status(204)
      end

      it "returns 404 for an invalid merge request IID" do
        delete api("/projects/#{project.id}/merge_requests/12345", user)

        expect(response).to have_gitlab_http_status(404)
      end

      it "returns 404 if the merge request id is used instead of iid" do
        delete api("/projects/#{project.id}/merge_requests/#{merge_request.id}", user)

        expect(response).to have_gitlab_http_status(404)
      end

      it_behaves_like '412 response' do
        let(:request) { api("/projects/#{project.id}/merge_requests/#{merge_request.iid}", user) }
      end
    end
  end

  describe "PUT /projects/:id/merge_requests/:merge_request_iid/merge" do
    let(:pipeline) { create(:ci_pipeline_without_jobs) }

    it "returns merge_request in case of success" do
      put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/merge", user)

      expect(response).to have_gitlab_http_status(200)
    end

    it "returns 406 if branch can't be merged" do
      allow_any_instance_of(MergeRequest)
        .to receive(:can_be_merged?).and_return(false)

      put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/merge", user)

      expect(response).to have_gitlab_http_status(406)
      expect(json_response['message']).to eq('Branch cannot be merged')
    end

    it "returns 405 if merge_request is not open" do
      merge_request.close
      put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/merge", user)
      expect(response).to have_gitlab_http_status(405)
      expect(json_response['message']).to eq('405 Method Not Allowed')
    end

    it "returns 405 if merge_request is a work in progress" do
      merge_request.update_attribute(:title, "WIP: #{merge_request.title}")
      put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/merge", user)
      expect(response).to have_gitlab_http_status(405)
      expect(json_response['message']).to eq('405 Method Not Allowed')
    end

    it 'returns 405 if the build failed for a merge request that requires success' do
      allow_any_instance_of(MergeRequest).to receive(:mergeable_ci_state?).and_return(false)

      put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/merge", user)

      expect(response).to have_gitlab_http_status(405)
      expect(json_response['message']).to eq('405 Method Not Allowed')
    end

    it "returns 401 if user has no permissions to merge" do
      user2 = create(:user)
      project.add_reporter(user2)
      put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/merge", user2)
      expect(response).to have_gitlab_http_status(401)
      expect(json_response['message']).to eq('401 Unauthorized')
    end

    it "returns 409 if the SHA parameter doesn't match" do
      put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/merge", user), sha: merge_request.diff_head_sha.reverse

      expect(response).to have_gitlab_http_status(409)
      expect(json_response['message']).to start_with('SHA does not match HEAD of source branch')
    end

    it "succeeds if the SHA parameter matches" do
      put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/merge", user), sha: merge_request.diff_head_sha

      expect(response).to have_gitlab_http_status(200)
    end

    it "enables merge when pipeline succeeds if the pipeline is active" do
      allow_any_instance_of(MergeRequest).to receive(:head_pipeline).and_return(pipeline)
      allow(pipeline).to receive(:active?).and_return(true)

      put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/merge", user), merge_when_pipeline_succeeds: true

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['title']).to eq('Test')
      expect(json_response['merge_when_pipeline_succeeds']).to eq(true)
    end

    it "enables merge when pipeline succeeds if the pipeline is active and only_allow_merge_if_pipeline_succeeds is true" do
      allow_any_instance_of(MergeRequest).to receive(:head_pipeline).and_return(pipeline)
      allow(pipeline).to receive(:active?).and_return(true)
      project.update_attribute(:only_allow_merge_if_pipeline_succeeds, true)

      put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/merge", user), merge_when_pipeline_succeeds: true

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['title']).to eq('Test')
      expect(json_response['merge_when_pipeline_succeeds']).to eq(true)
    end

    it "returns 404 for an invalid merge request IID" do
      put api("/projects/#{project.id}/merge_requests/12345/merge", user)

      expect(response).to have_gitlab_http_status(404)
    end

    it "returns 404 if the merge request id is used instead of iid" do
      put api("/projects/#{project.id}/merge_requests/#{merge_request.id}/merge", user)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe "PUT /projects/:id/merge_requests/:merge_request_iid" do
    context "to close a MR" do
      it "returns merge_request" do
        put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}", user), state_event: "close"

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['state']).to eq('closed')
      end
    end

    it "updates title and returns merge_request" do
      put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}", user), title: "New title"
      expect(response).to have_gitlab_http_status(200)
      expect(json_response['title']).to eq('New title')
    end

    it "updates description and returns merge_request" do
      put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}", user), description: "New description"
      expect(response).to have_gitlab_http_status(200)
      expect(json_response['description']).to eq('New description')
    end

    it "updates milestone_id and returns merge_request" do
      put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}", user), milestone_id: milestone.id
      expect(response).to have_gitlab_http_status(200)
      expect(json_response['milestone']['id']).to eq(milestone.id)
    end

    it "returns merge_request with renamed target_branch" do
      put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}", user), target_branch: "wiki"
      expect(response).to have_gitlab_http_status(200)
      expect(json_response['target_branch']).to eq('wiki')
    end

    it "returns merge_request that removes the source branch" do
      put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}", user), remove_source_branch: true

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['force_remove_source_branch']).to be_truthy
    end

    it 'allows special label names' do
      put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}", user),
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
      put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}", user), state_event: 'close', title: nil

      merge_request.reload
      expect(response).to have_gitlab_http_status(400)
      expect(merge_request.state).to eq('opened')
    end

    it 'does not update state when target_branch is empty' do
      put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}", user), state_event: 'close', target_branch: nil

      merge_request.reload
      expect(response).to have_gitlab_http_status(400)
      expect(merge_request.state).to eq('opened')
    end

    it "returns 404 for an invalid merge request IID" do
      put api("/projects/#{project.id}/merge_requests/12345", user), state_event: "close"

      expect(response).to have_gitlab_http_status(404)
    end

    it "returns 404 if the merge request id is used instead of iid" do
      put api("/projects/#{project.id}/merge_requests/#{merge_request.id}", user), state_event: "close"

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'GET :id/merge_requests/:merge_request_iid/closes_issues' do
    it 'returns the issue that will be closed on merge' do
      issue = create(:issue, project: project)
      mr = merge_request.tap do |mr|
        mr.update_attribute(:description, "Closes #{issue.to_reference(mr.project)}")
      end

      get api("/projects/#{project.id}/merge_requests/#{mr.iid}/closes_issues", user)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['id']).to eq(issue.id)
    end

    it 'returns an empty array when there are no issues to be closed' do
      get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/closes_issues", user)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(0)
    end

    it 'handles external issues' do
      jira_project = create(:jira_project, :public, :repository, name: 'JIR_EXT1')
      ext_issue = ExternalIssue.new("#{jira_project.name}-123", jira_project)
      issue = create(:issue, project: jira_project)
      description = "Closes #{ext_issue.to_reference(jira_project)}\ncloses #{issue.to_reference}"
      merge_request = create(:merge_request,
        :simple, author: user, assignee: user, source_project: jira_project, description: description)

      get api("/projects/#{jira_project.id}/merge_requests/#{merge_request.iid}/closes_issues", user)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(2)
      expect(json_response.second['title']).to eq(ext_issue.title)
      expect(json_response.second['id']).to eq(ext_issue.id)
      expect(json_response.second['confidential']).to be_nil
      expect(json_response.first['title']).to eq(issue.title)
      expect(json_response.first['id']).to eq(issue.id)
      expect(json_response.first['confidential']).not_to be_nil
    end

    it 'returns 403 if the user has no access to the merge request' do
      project = create(:project, :private)
      merge_request = create(:merge_request, :simple, source_project: project)
      guest = create(:user)
      project.add_guest(guest)

      get api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/closes_issues", guest)

      expect(response).to have_gitlab_http_status(403)
    end

    it "returns 404 for an invalid merge request IID" do
      get api("/projects/#{project.id}/merge_requests/12345/closes_issues", user)

      expect(response).to have_gitlab_http_status(404)
    end

    it "returns 404 if the merge request id is used instead of iid" do
      get api("/projects/#{project.id}/merge_requests/#{merge_request.id}/closes_issues", user)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'POST :id/merge_requests/:merge_request_iid/subscribe' do
    it 'subscribes to a merge request' do
      post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/subscribe", admin)

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['subscribed']).to eq(true)
    end

    it 'returns 304 if already subscribed' do
      post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/subscribe", user)

      expect(response).to have_gitlab_http_status(304)
    end

    it 'returns 404 if the merge request is not found' do
      post api("/projects/#{project.id}/merge_requests/123/subscribe", user)

      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns 404 if the merge request id is used instead of iid' do
      post api("/projects/#{project.id}/merge_requests/#{merge_request.id}/subscribe", user)

      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns 403 if user has no access to read code' do
      guest = create(:user)
      project.add_guest(guest)

      post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/subscribe", guest)

      expect(response).to have_gitlab_http_status(403)
    end
  end

  describe 'POST :id/merge_requests/:merge_request_iid/unsubscribe' do
    it 'unsubscribes from a merge request' do
      post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/unsubscribe", user)

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['subscribed']).to eq(false)
    end

    it 'returns 304 if not subscribed' do
      post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/unsubscribe", admin)

      expect(response).to have_gitlab_http_status(304)
    end

    it 'returns 404 if the merge request is not found' do
      post api("/projects/#{project.id}/merge_requests/123/unsubscribe", user)

      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns 404 if the merge request id is used instead of iid' do
      post api("/projects/#{project.id}/merge_requests/#{merge_request.id}/unsubscribe", user)

      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns 403 if user has no access to read code' do
      guest = create(:user)
      project.add_guest(guest)

      post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/unsubscribe", guest)

      expect(response).to have_gitlab_http_status(403)
    end
  end

  describe 'POST :id/merge_requests/:merge_request_iid/cancel_merge_when_pipeline_succeeds' do
    before do
      ::MergeRequests::MergeWhenPipelineSucceedsService.new(merge_request.target_project, user).execute(merge_request)
    end

    it 'removes the merge_when_pipeline_succeeds status' do
      post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/cancel_merge_when_pipeline_succeeds", user)

      expect(response).to have_gitlab_http_status(201)
    end

    it 'returns 404 if the merge request is not found' do
      post api("/projects/#{project.id}/merge_requests/123/merge_when_pipeline_succeeds", user)

      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns 404 if the merge request id is used instead of iid' do
      post api("/projects/#{project.id}/merge_requests/#{merge_request.id}/merge_when_pipeline_succeeds", user)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'Time tracking' do
    let(:issuable) { merge_request }

    include_examples 'time tracking endpoints', 'merge_request'
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
