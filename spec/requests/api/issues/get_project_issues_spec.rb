# frozen_string_literal: true

require 'spec_helper'

describe API::Issues do
  set(:user) { create(:user) }
  set(:project) { create(:project, :public, :repository, creator_id: user.id, namespace: user.namespace) }
  set(:private_mrs_project) do
    create(:project, :public, :repository, creator_id: user.id, namespace: user.namespace, merge_requests_access_level: ProjectFeature::PRIVATE)
  end

  let(:user2)       { create(:user) }
  let(:non_member)  { create(:user) }
  set(:guest)       { create(:user) }
  set(:author)      { create(:author) }
  set(:assignee)    { create(:assignee) }
  let(:admin)       { create(:user, :admin) }
  let(:issue_title)       { 'foo' }
  let(:issue_description) { 'closed' }
  let!(:closed_issue) do
    create :closed_issue,
      author: user,
      assignees: [user],
      project: project,
      state: :closed,
      milestone: milestone,
      created_at: generate(:past_time),
      updated_at: 3.hours.ago,
      closed_at: 1.hour.ago
  end
  let!(:confidential_issue) do
    create :issue,
      :confidential,
      project: project,
      author: author,
      assignees: [assignee],
      created_at: generate(:past_time),
      updated_at: 2.hours.ago
  end
  let!(:issue) do
    create :issue,
      author: user,
      assignees: [user],
      project: project,
      milestone: milestone,
      created_at: generate(:past_time),
      updated_at: 1.hour.ago,
      title: issue_title,
      description: issue_description
  end
  set(:label) do
    create(:label, title: 'label', color: '#FFAABB', project: project)
  end
  let!(:label_link) { create(:label_link, label: label, target: issue) }
  let(:milestone) { create(:milestone, title: '1.0.0', project: project) }
  set(:empty_milestone) do
    create(:milestone, title: '2.0.0', project: project)
  end
  let!(:note) { create(:note_on_issue, author: user, project: project, noteable: issue) }

  let(:no_milestone_title) { 'None' }
  let(:any_milestone_title) { 'Any' }

  let!(:merge_request1) do
    create(:merge_request,
           :simple,
           author: user,
           source_project: project,
           target_project: project,
           description: "closes #{issue.to_reference}")
  end
  let!(:merge_request2) do
    create(:merge_request,
           :simple,
           author: user,
           source_project: private_mrs_project,
           target_project: private_mrs_project,
           description: "closes #{issue.to_reference(private_mrs_project)}")
  end

  before(:all) do
    project.add_reporter(user)
    project.add_guest(guest)
    private_mrs_project.add_reporter(user)
    private_mrs_project.add_guest(guest)
  end

  before do
    stub_licensed_features(multiple_issue_assignees: false, issue_weights: false)
  end

  shared_examples 'project issues statistics' do
    it 'returns project issues statistics' do
      get api("/issues_statistics", user), params: params

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['statistics']).not_to be_nil
      expect(json_response['statistics']['counts']['all']).to eq counts[:all]
      expect(json_response['statistics']['counts']['closed']).to eq counts[:closed]
      expect(json_response['statistics']['counts']['opened']).to eq counts[:opened]
    end
  end

  describe "GET /projects/:id/issues" do
    let(:base_url) { "/projects/#{project.id}" }

    context 'when unauthenticated' do
      it 'returns public project issues' do
        get api("/projects/#{project.id}/issues")

        expect_paginated_array_response([issue.id, closed_issue.id])
      end

      context 'issues_statistics' do
        context 'no state is treated as all state' do
          let(:params) { {} }
          let(:counts) { { all: 2, closed: 1, opened: 1 } }

          it_behaves_like 'project issues statistics'
        end

        context 'statistics when all state is passed' do
          let(:params) { { state: :all } }
          let(:counts) { { all: 2, closed: 1, opened: 1 } }

          it_behaves_like 'project issues statistics'
        end

        context 'closed state is treated as all state' do
          let(:params) { { state: :closed } }
          let(:counts) { { all: 2, closed: 1, opened: 1 } }

          it_behaves_like 'project issues statistics'
        end

        context 'opened state is treated as all state' do
          let(:params) { { state: :opened } }
          let(:counts) { { all: 2, closed: 1, opened: 1 } }

          it_behaves_like 'project issues statistics'
        end

        context 'when filtering by milestone and no state treated as all state' do
          let(:params) { { milestone: milestone.title } }
          let(:counts) { { all: 2, closed: 1, opened: 1 } }

          it_behaves_like 'project issues statistics'
        end

        context 'when filtering by milestone and all state' do
          let(:params) { { milestone: milestone.title, state: :all } }
          let(:counts) { { all: 2, closed: 1, opened: 1 } }

          it_behaves_like 'project issues statistics'
        end

        context 'when filtering by milestone and closed state treated as all state' do
          let(:params) { { milestone: milestone.title, state: :closed } }
          let(:counts) { { all: 2, closed: 1, opened: 1 } }

          it_behaves_like 'project issues statistics'
        end

        context 'when filtering by milestone and opened state treated as all state' do
          let(:params) { { milestone: milestone.title, state: :opened } }
          let(:counts) { { all: 2, closed: 1, opened: 1 } }

          it_behaves_like 'project issues statistics'
        end

        context 'sort does not affect statistics ' do
          let(:params) { { state: :opened, order_by: 'updated_at' } }
          let(:counts) { { all: 2, closed: 1, opened: 1 } }

          it_behaves_like 'project issues statistics'
        end
      end
    end

    it 'avoids N+1 queries' do
      get api("/projects/#{project.id}/issues", user)

      create_list(:issue, 3, project: project)

      control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        get api("/projects/#{project.id}/issues", user)
      end.count

      expect do
        get api("/projects/#{project.id}/issues", user)
      end.not_to exceed_all_query_limit(control_count)
    end

    it 'returns 404 when project does not exist' do
      max_project_id = Project.maximum(:id).to_i

      get api("/projects/#{max_project_id + 1}/issues", non_member)

      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns 404 on private projects for other users' do
      private_project = create(:project, :private)
      create(:issue, project: private_project)

      get api("/projects/#{private_project.id}/issues", non_member)

      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns no issues when user has access to project but not issues' do
      restricted_project = create(:project, :public, :issues_private)
      create(:issue, project: restricted_project)

      get api("/projects/#{restricted_project.id}/issues", non_member)

      expect_paginated_array_response([])
    end

    it 'returns project issues without confidential issues for non project members' do
      get api("#{base_url}/issues", non_member)

      expect_paginated_array_response([issue.id, closed_issue.id])
    end

    it 'returns project issues without confidential issues for project members with guest role' do
      get api("#{base_url}/issues", guest)

      expect_paginated_array_response([issue.id, closed_issue.id])
    end

    it 'returns project confidential issues for author' do
      get api("#{base_url}/issues", author)

      expect_paginated_array_response([issue.id, confidential_issue.id, closed_issue.id])
    end

    it 'returns only confidential issues' do
      get api("#{base_url}/issues", author), params: { confidential: true }

      expect_paginated_array_response(confidential_issue.id)
    end

    it 'returns only public issues' do
      get api("#{base_url}/issues", author), params: { confidential: false }

      expect_paginated_array_response([issue.id, closed_issue.id])
    end

    it 'returns project confidential issues for assignee' do
      get api("#{base_url}/issues", assignee)

      expect_paginated_array_response([issue.id, confidential_issue.id, closed_issue.id])
    end

    it 'returns project issues with confidential issues for project members' do
      get api("#{base_url}/issues", user)

      expect_paginated_array_response([issue.id, confidential_issue.id, closed_issue.id])
    end

    it 'returns project confidential issues for admin' do
      get api("#{base_url}/issues", admin)

      expect_paginated_array_response([issue.id, confidential_issue.id, closed_issue.id])
    end

    it 'returns an array of labeled project issues' do
      get api("#{base_url}/issues", user), params: { labels: label.title }

      expect_paginated_array_response(issue.id)
    end

    it 'returns an array of labeled project issues with labels param as array' do
      get api("#{base_url}/issues", user), params: { labels: [label.title] }

      expect_paginated_array_response(issue.id)
    end

    it_behaves_like 'accessible merge requests count' do
      let(:api_url) { "/projects/#{project.id}/issues" }
      let(:target_issue) { issue }
    end

    context 'with labeled issues' do
      let(:issue2) { create :issue, project: project }
      let(:label_b) { create(:label, title: 'foo', project: project) }
      let(:label_c) { create(:label, title: 'bar', project: project) }

      before do
        create(:label_link, label: label, target: issue2)
        create(:label_link, label: label_b, target: issue)
        create(:label_link, label: label_b, target: issue2)
        create(:label_link, label: label_c, target: issue)

        get api('/issues', user), params: params
      end

      it_behaves_like 'labeled issues with labels and label_name params'
    end

    context 'with_labels_details' do
      let(:label_b) { create(:label, title: 'foo', project: project) }
      let(:label_c) { create(:label, title: 'bar', project: project) }

      it 'avoids N+1 queries' do
        control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          get api("/projects/#{project.id}/issues?with_labels_details=true", user)
        end.count

        new_issue = create(:issue, project: project)
        create(:label_link, label: label, target: new_issue)
        create(:label_link, label: label_b, target: new_issue)
        create(:label_link, label: label_c, target: new_issue)

        expect do
          get api("/projects/#{project.id}/issues?with_labels_details=true", user)
        end.not_to exceed_all_query_limit(control_count)
      end
    end

    it 'returns issues matching given search string for title' do
      get api("#{base_url}/issues?search=#{issue.title}", user)

      expect_paginated_array_response(issue.id)
    end

    it 'returns issues matching given search string for description' do
      get api("#{base_url}/issues?search=#{issue.description}", user)

      expect_paginated_array_response(issue.id)
    end

    it 'returns an array of issues found by iids' do
      get api("#{base_url}/issues", user), params: { iids: [issue.iid] }

      expect_paginated_array_response(issue.id)
    end

    it 'returns an empty array if iid does not exist' do
      get api("#{base_url}/issues", user), params: { iids: [0] }

      expect_paginated_array_response([])
    end

    it 'returns an empty array if not all labels matches' do
      get api("#{base_url}/issues?labels=#{label.title},foo", user)

      expect_paginated_array_response([])
    end

    it 'returns an array of project issues with any label' do
      get api("#{base_url}/issues", user), params: { labels: IssuesFinder::FILTER_ANY }

      expect_paginated_array_response(issue.id)
    end

    it 'returns an array of project issues with any label with labels param as array' do
      get api("#{base_url}/issues", user), params: { labels: [IssuesFinder::FILTER_ANY] }

      expect_paginated_array_response(issue.id)
    end

    it 'returns an array of project issues with no label' do
      get api("#{base_url}/issues", user), params: { labels: IssuesFinder::FILTER_NONE }

      expect_paginated_array_response([confidential_issue.id, closed_issue.id])
    end

    it 'returns an array of project issues with no label with labels param as array' do
      get api("#{base_url}/issues", user), params: { labels: [IssuesFinder::FILTER_NONE] }

      expect_paginated_array_response([confidential_issue.id, closed_issue.id])
    end

    it 'returns an empty array if no project issue matches labels' do
      get api("#{base_url}/issues", user), params: { labels: 'foo,bar' }

      expect_paginated_array_response([])
    end

    it 'returns an empty array if no issue matches milestone' do
      get api("#{base_url}/issues", user), params: { milestone: empty_milestone.title }

      expect_paginated_array_response([])
    end

    it 'returns an empty array if milestone does not exist' do
      get api("#{base_url}/issues", user), params: { milestone: :foo }

      expect_paginated_array_response([])
    end

    it 'returns an array of issues in given milestone' do
      get api("#{base_url}/issues", user), params: { milestone: milestone.title }

      expect_paginated_array_response([issue.id, closed_issue.id])
    end

    it 'returns an array of issues matching state in milestone' do
      get api("#{base_url}/issues", user), params: { milestone: milestone.title, state: :closed }

      expect_paginated_array_response(closed_issue.id)
    end

    it 'returns an array of issues with no milestone' do
      get api("#{base_url}/issues", user), params: { milestone: no_milestone_title }

      expect_paginated_array_response(confidential_issue.id)
    end

    it 'returns an array of issues with any milestone' do
      get api("#{base_url}/issues", user), params: { milestone: any_milestone_title }

      expect_paginated_array_response([issue.id, closed_issue.id])
    end

    context 'without sort params' do
      it 'sorts by created_at descending by default' do
        get api("#{base_url}/issues", user)

        expect_paginated_array_response([issue.id, confidential_issue.id, closed_issue.id])
      end

      context 'with 2 issues with same created_at' do
        let!(:closed_issue2) do
          create :closed_issue,
            author: user,
            assignees: [user],
            project: project,
            milestone: milestone,
            created_at: closed_issue.created_at,
            updated_at: 1.hour.ago,
            title: issue_title,
            description: issue_description
        end

        it 'page breaks first page correctly' do
          get api("#{base_url}/issues?per_page=3", user)

          expect_paginated_array_response([issue.id, confidential_issue.id, closed_issue2.id])
        end

        it 'page breaks second page correctly' do
          get api("#{base_url}/issues?per_page=3&page=2", user)

          expect_paginated_array_response([closed_issue.id])
        end
      end
    end

    it 'sorts ascending when requested' do
      get api("#{base_url}/issues", user), params: { sort: :asc }

      expect_paginated_array_response([closed_issue.id, confidential_issue.id, issue.id])
    end

    it 'sorts by updated_at descending when requested' do
      get api("#{base_url}/issues", user), params: { order_by: :updated_at }

      issue.touch(:updated_at)

      expect_paginated_array_response([issue.id, confidential_issue.id, closed_issue.id])
    end

    it 'sorts by updated_at ascending when requested' do
      get api("#{base_url}/issues", user), params: { order_by: :updated_at, sort: :asc }

      expect_paginated_array_response([closed_issue.id, confidential_issue.id, issue.id])
    end

    it 'exposes known attributes' do
      get api("#{base_url}/issues", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response.last.keys).to include(*%w(id iid project_id title description))
      expect(json_response.last).not_to have_key('subscribed')
    end

    context 'issues_statistics' do
      context 'no state is treated as all state' do
        let(:params) { {} }
        let(:counts) { { all: 2, closed: 1, opened: 1 } }

        it_behaves_like 'project issues statistics'
      end

      context 'statistics when all state is passed' do
        let(:params) { { state: :all } }
        let(:counts) { { all: 2, closed: 1, opened: 1 } }

        it_behaves_like 'project issues statistics'
      end

      context 'closed state is treated as all state' do
        let(:params) { { state: :closed } }
        let(:counts) { { all: 2, closed: 1, opened: 1 } }

        it_behaves_like 'project issues statistics'
      end

      context 'opened state is treated as all state' do
        let(:params) { { state: :opened } }
        let(:counts) { { all: 2, closed: 1, opened: 1 } }

        it_behaves_like 'project issues statistics'
      end

      context 'when filtering by milestone and no state treated as all state' do
        let(:params) { { milestone: milestone.title } }
        let(:counts) { { all: 2, closed: 1, opened: 1 } }

        it_behaves_like 'project issues statistics'
      end

      context 'when filtering by milestone and all state' do
        let(:params) { { milestone: milestone.title, state: :all } }
        let(:counts) { { all: 2, closed: 1, opened: 1 } }

        it_behaves_like 'project issues statistics'
      end

      context 'when filtering by milestone and closed state treated as all state' do
        let(:params) { { milestone: milestone.title, state: :closed } }
        let(:counts) { { all: 2, closed: 1, opened: 1 } }

        it_behaves_like 'project issues statistics'
      end

      context 'when filtering by milestone and opened state treated as all state' do
        let(:params) { { milestone: milestone.title, state: :opened } }
        let(:counts) { { all: 2, closed: 1, opened: 1 } }

        it_behaves_like 'project issues statistics'
      end

      context 'sort does not affect statistics ' do
        let(:params) { { state: :opened, order_by: 'updated_at' } }
        let(:counts) { { all: 2, closed: 1, opened: 1 } }

        it_behaves_like 'project issues statistics'
      end
    end

    context 'filtering by assignee_username' do
      let(:another_assignee) { create(:assignee) }
      let!(:issue1) { create(:issue, author: user2, project: project, created_at: 3.days.ago) }
      let!(:issue2) { create(:issue, author: user2, project: project, created_at: 2.days.ago) }
      let!(:issue3) { create(:issue, author: user2, assignees: [assignee, another_assignee], project: project, created_at: 1.day.ago) }

      it 'returns issues by assignee_username' do
        get api("/issues", user), params: { assignee_username: [assignee.username], scope: 'all' }

        expect(issue3.reload.assignees.pluck(:id)).to match_array([assignee.id, another_assignee.id])
        expect_paginated_array_response([confidential_issue.id, issue3.id])
      end

      it 'returns issues by assignee_username as string' do
        get api("/issues", user), params: { assignee_username: assignee.username, scope: 'all' }

        expect(issue3.reload.assignees.pluck(:id)).to match_array([assignee.id, another_assignee.id])
        expect_paginated_array_response([confidential_issue.id, issue3.id])
      end

      it 'returns error when multiple assignees are passed' do
        get api("/issues", user), params: { assignee_username: [assignee.username, another_assignee.username], scope: 'all' }

        expect(response).to have_gitlab_http_status(400)
        expect(json_response["error"]).to include("allows one value, but found 2")
      end

      it 'returns error when assignee_username and assignee_id are passed together' do
        get api("/issues", user), params: { assignee_username: [assignee.username], assignee_id: another_assignee.id, scope: 'all' }

        expect(response).to have_gitlab_http_status(400)
        expect(json_response["error"]).to include("mutually exclusive")
      end
    end
  end

  describe 'GET /projects/:id/issues/:issue_iid' do
    context 'when unauthenticated' do
      it 'returns public issues' do
        get api("/projects/#{project.id}/issues/#{issue.iid}")

        expect(response).to have_gitlab_http_status(200)
      end
    end

    it 'exposes known attributes' do
      get api("/projects/#{project.id}/issues/#{issue.iid}", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['id']).to eq(issue.id)
      expect(json_response['iid']).to eq(issue.iid)
      expect(json_response['project_id']).to eq(issue.project.id)
      expect(json_response['title']).to eq(issue.title)
      expect(json_response['description']).to eq(issue.description)
      expect(json_response['state']).to eq(issue.state)
      expect(json_response['closed_at']).to be_falsy
      expect(json_response['created_at']).to be_present
      expect(json_response['updated_at']).to be_present
      expect(json_response['labels']).to eq(issue.label_names)
      expect(json_response['milestone']).to be_a Hash
      expect(json_response['assignees']).to be_a Array
      expect(json_response['assignee']).to be_a Hash
      expect(json_response['author']).to be_a Hash
      expect(json_response['confidential']).to be_falsy
      expect(json_response['subscribed']).to be_truthy
    end

    context "moved_to_id" do
      let(:moved_issue) do
        create(:closed_issue, project: project, moved_to: issue)
      end

      it 'returns null when not moved' do
        get api("/projects/#{project.id}/issues/#{issue.iid}", user)

        expect(json_response['moved_to_id']).to be_nil
      end

      it 'returns issue id when moved' do
        get api("/projects/#{project.id}/issues/#{moved_issue.iid}", user)

        expect(json_response['moved_to_id']).to eq(issue.id)
      end
    end

    it 'exposes the closed_at attribute' do
      get api("/projects/#{project.id}/issues/#{closed_issue.iid}", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['closed_at']).to be_present
    end

    context 'links exposure' do
      it 'exposes related resources full URIs' do
        get api("/projects/#{project.id}/issues/#{issue.iid}", user)

        links = json_response['_links']

        expect(links['self']).to end_with("/api/v4/projects/#{project.id}/issues/#{issue.iid}")
        expect(links['notes']).to end_with("/api/v4/projects/#{project.id}/issues/#{issue.iid}/notes")
        expect(links['award_emoji']).to end_with("/api/v4/projects/#{project.id}/issues/#{issue.iid}/award_emoji")
        expect(links['project']).to end_with("/api/v4/projects/#{project.id}")
      end
    end

    it 'returns a project issue by internal id' do
      get api("/projects/#{project.id}/issues/#{issue.iid}", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['title']).to eq(issue.title)
      expect(json_response['iid']).to eq(issue.iid)
    end

    it 'returns 404 if issue id not found' do
      get api("/projects/#{project.id}/issues/54321", user)
      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns 404 if the issue ID is used' do
      get api("/projects/#{project.id}/issues/#{issue.id}", user)

      expect(response).to have_gitlab_http_status(404)
    end

    context 'confidential issues' do
      it 'returns 404 for non project members' do
        get api("/projects/#{project.id}/issues/#{confidential_issue.iid}", non_member)

        expect(response).to have_gitlab_http_status(404)
      end

      it 'returns 404 for project members with guest role' do
        get api("/projects/#{project.id}/issues/#{confidential_issue.iid}", guest)

        expect(response).to have_gitlab_http_status(404)
      end

      it 'returns confidential issue for project members' do
        get api("/projects/#{project.id}/issues/#{confidential_issue.iid}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['title']).to eq(confidential_issue.title)
        expect(json_response['iid']).to eq(confidential_issue.iid)
      end

      it 'returns confidential issue for author' do
        get api("/projects/#{project.id}/issues/#{confidential_issue.iid}", author)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['title']).to eq(confidential_issue.title)
        expect(json_response['iid']).to eq(confidential_issue.iid)
      end

      it 'returns confidential issue for assignee' do
        get api("/projects/#{project.id}/issues/#{confidential_issue.iid}", assignee)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['title']).to eq(confidential_issue.title)
        expect(json_response['iid']).to eq(confidential_issue.iid)
      end

      it 'returns confidential issue for admin' do
        get api("/projects/#{project.id}/issues/#{confidential_issue.iid}", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['title']).to eq(confidential_issue.title)
        expect(json_response['iid']).to eq(confidential_issue.iid)
      end
    end

    it_behaves_like 'accessible merge requests count' do
      let(:api_url) { "/projects/#{project.id}/issues/#{issue.iid}" }
      let(:target_issue) { issue }
    end
  end

  describe 'GET :id/issues/:issue_iid/closed_by' do
    context 'when unauthenticated' do
      it 'return public project issues' do
        get api("/projects/#{project.id}/issues/#{issue.iid}/closed_by")

        expect_paginated_array_response(merge_request1.id)
      end
    end

    it 'returns merge requests that will close issue on merge' do
      get api("/projects/#{project.id}/issues/#{issue.iid}/closed_by", user)

      expect_paginated_array_response(merge_request1.id)
    end

    context 'when no merge requests will close issue' do
      it 'returns empty array' do
        get api("/projects/#{project.id}/issues/#{closed_issue.iid}/closed_by", user)

        expect_paginated_array_response([])
      end
    end

    it "returns 404 when issue doesn't exists" do
      get api("/projects/#{project.id}/issues/0/closed_by", user)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'GET :id/issues/:issue_iid/related_merge_requests' do
    def get_related_merge_requests(project_id, issue_iid, user = nil)
      get api("/projects/#{project_id}/issues/#{issue_iid}/related_merge_requests", user)
    end

    def create_referencing_mr(user, project, issue)
      attributes = {
        author: user,
        source_project: project,
        target_project: project,
        source_branch: 'master',
        target_branch: 'test',
        description: "See #{issue.to_reference}"
      }
      create(:merge_request, attributes).tap do |merge_request|
        create(:note, :system, project: issue.project, noteable: issue, author: user, note: merge_request.to_reference(full: true))
      end
    end

    let!(:related_mr) { create_referencing_mr(user, project, issue) }

    context 'when unauthenticated' do
      it 'return list of referenced merge requests from issue' do
        get_related_merge_requests(project.id, issue.iid)

        expect_paginated_array_response(related_mr.id)
        expect(response).to have_gitlab_http_status(200)
        expect(json_response.last).not_to have_key('subscribed')
      end

      it 'renders 404 if project is not visible' do
        private_project = create(:project, :private)
        private_issue = create(:issue, project: private_project)
        create_referencing_mr(user, private_project, private_issue)

        get_related_merge_requests(private_project.id, private_issue.iid)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    it 'returns merge requests that mentioned a issue' do
      get_related_merge_requests(project.id, issue.iid, user)

      expect_paginated_array_response(related_mr.id)
    end

    it 'returns merge requests cross-project wide' do
      project2 = create(:project, :public, creator_id: user.id, namespace: user.namespace)
      merge_request = create_referencing_mr(user, project2, issue)

      get_related_merge_requests(project.id, issue.iid, user)

      expect_paginated_array_response([related_mr.id, merge_request.id])
    end

    it 'does not generate references to projects with no access' do
      private_project = create(:project, :private)
      create_referencing_mr(private_project.creator, private_project, issue)

      get_related_merge_requests(project.id, issue.iid, user)

      expect_paginated_array_response(related_mr.id)
    end

    context 'no merge request mentioned a issue' do
      it 'returns empty array' do
        get_related_merge_requests(project.id, closed_issue.iid, user)

        expect_paginated_array_response([])
      end
    end

    it "returns 404 when issue doesn't exists" do
      get_related_merge_requests(project.id, 0, user)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'GET /projects/:id/issues/:issue_iid/user_agent_detail' do
    let!(:user_agent_detail) { create(:user_agent_detail, subject: issue) }

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        get api("/projects/#{project.id}/issues/#{issue.iid}/user_agent_detail")

        expect(response).to have_gitlab_http_status(401)
      end
    end

    it 'exposes known attributes' do
      get api("/projects/#{project.id}/issues/#{issue.iid}/user_agent_detail", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['user_agent']).to eq(user_agent_detail.user_agent)
      expect(json_response['ip_address']).to eq(user_agent_detail.ip_address)
      expect(json_response['akismet_submitted']).to eq(user_agent_detail.submitted)
    end

    it 'returns unauthorized for non-admin users' do
      get api("/projects/#{project.id}/issues/#{issue.iid}/user_agent_detail", user)

      expect(response).to have_gitlab_http_status(403)
    end
  end

  describe 'GET projects/:id/issues/:issue_iid/participants' do
    it_behaves_like 'issuable participants endpoint' do
      let(:entity) { issue }
    end

    it 'returns 404 if the issue is confidential' do
      post api("/projects/#{project.id}/issues/#{confidential_issue.iid}/participants", non_member)

      expect(response).to have_gitlab_http_status(404)
    end
  end
end
