require 'spec_helper'

describe API::V3::Issues do
  set(:user)        { create(:user) }
  set(:user2)       { create(:user) }
  set(:non_member)  { create(:user) }
  set(:guest)       { create(:user) }
  set(:author)      { create(:author) }
  set(:assignee)    { create(:assignee) }
  set(:admin)       { create(:user, :admin) }
  let!(:project)    { create(:project, :public, creator_id: user.id, namespace: user.namespace ) }
  let!(:closed_issue) do
    create :closed_issue,
           author: user,
           assignees: [user],
           project: project,
           state: :closed,
           milestone: milestone,
           created_at: generate(:past_time),
           updated_at: 3.hours.ago
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
           updated_at: 1.hour.ago
  end
  let!(:label) do
    create(:label, title: 'label', color: '#FFAABB', project: project)
  end
  let!(:label_link) { create(:label_link, label: label, target: issue) }
  let!(:milestone) { create(:milestone, title: '1.0.0', project: project) }
  let!(:empty_milestone) do
    create(:milestone, title: '2.0.0', project: project)
  end
  let!(:note) { create(:note_on_issue, author: user, project: project, noteable: issue) }

  let(:no_milestone_title) { URI.escape(Milestone::None.title) }

  before do
    project.add_reporter(user)
    project.add_guest(guest)
  end

  describe "GET /issues" do
    context "when unauthenticated" do
      it "returns authentication error" do
        get v3_api("/issues")

        expect(response).to have_gitlab_http_status(401)
      end
    end

    context "when authenticated" do
      it "returns an array of issues" do
        get v3_api("/issues", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.first['title']).to eq(issue.title)
        expect(json_response.last).to have_key('web_url')
      end

      it 'returns an array of closed issues' do
        get v3_api('/issues?state=closed', user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(closed_issue.id)
      end

      it 'returns an array of opened issues' do
        get v3_api('/issues?state=opened', user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(issue.id)
      end

      it 'returns an array of all issues' do
        get v3_api('/issues?state=all', user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(2)
        expect(json_response.first['id']).to eq(issue.id)
        expect(json_response.second['id']).to eq(closed_issue.id)
      end

      it 'returns an array of labeled issues' do
        get v3_api("/issues?labels=#{label.title}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['labels']).to eq([label.title])
      end

      it 'returns an array of labeled issues when at least one label matches' do
        get v3_api("/issues?labels=#{label.title},foo,bar", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['labels']).to eq([label.title])
      end

      it 'returns an empty array if no issue matches labels' do
        get v3_api('/issues?labels=foo,bar', user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(0)
      end

      it 'returns an array of labeled issues matching given state' do
        get v3_api("/issues?labels=#{label.title}&state=opened", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['labels']).to eq([label.title])
        expect(json_response.first['state']).to eq('opened')
      end

      it 'returns an empty array if no issue matches labels and state filters' do
        get v3_api("/issues?labels=#{label.title}&state=closed", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(0)
      end

      it 'returns an empty array if no issue matches milestone' do
        get v3_api("/issues?milestone=#{empty_milestone.title}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(0)
      end

      it 'returns an empty array if milestone does not exist' do
        get v3_api("/issues?milestone=foo", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(0)
      end

      it 'returns an array of issues in given milestone' do
        get v3_api("/issues?milestone=#{milestone.title}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(2)
        expect(json_response.first['id']).to eq(issue.id)
        expect(json_response.second['id']).to eq(closed_issue.id)
      end

      it 'returns an array of issues matching state in milestone' do
        get v3_api("/issues?milestone=#{milestone.title}",  user),
          '&state=closed'

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(closed_issue.id)
      end

      it 'returns an array of issues with no milestone' do
        get v3_api("/issues?milestone=#{no_milestone_title}", author)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(confidential_issue.id)
      end

      it 'sorts by created_at descending by default' do
        get v3_api('/issues', user)

        response_dates = json_response.map { |issue| issue['created_at'] }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(response_dates).to eq(response_dates.sort.reverse)
      end

      it 'sorts ascending when requested' do
        get v3_api('/issues?sort=asc', user)

        response_dates = json_response.map { |issue| issue['created_at'] }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(response_dates).to eq(response_dates.sort)
      end

      it 'sorts by updated_at descending when requested' do
        get v3_api('/issues?order_by=updated_at', user)

        response_dates = json_response.map { |issue| issue['updated_at'] }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(response_dates).to eq(response_dates.sort.reverse)
      end

      it 'sorts by updated_at ascending when requested' do
        get v3_api('/issues?order_by=updated_at&sort=asc', user)

        response_dates = json_response.map { |issue| issue['updated_at'] }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(response_dates).to eq(response_dates.sort)
      end

      it 'matches V3 response schema' do
        get v3_api('/issues', user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v3/issues')
      end
    end
  end

  describe "GET /groups/:id/issues" do
    let!(:group)            { create(:group) }
    let!(:group_project)    { create(:project, :public, creator_id: user.id, namespace: group) }
    let!(:group_closed_issue) do
      create :closed_issue,
             author: user,
             assignees: [user],
             project: group_project,
             state: :closed,
             milestone: group_milestone,
             updated_at: 3.hours.ago
    end
    let!(:group_confidential_issue) do
      create :issue,
             :confidential,
             project: group_project,
             author: author,
             assignees: [assignee],
             updated_at: 2.hours.ago
    end
    let!(:group_issue) do
      create :issue,
             author: user,
             assignees: [user],
             project: group_project,
             milestone: group_milestone,
             updated_at: 1.hour.ago
    end
    let!(:group_label) do
      create(:label, title: 'group_lbl', color: '#FFAABB', project: group_project)
    end
    let!(:group_label_link) { create(:label_link, label: group_label, target: group_issue) }
    let!(:group_milestone) { create(:milestone, title: '3.0.0', project: group_project) }
    let!(:group_empty_milestone) do
      create(:milestone, title: '4.0.0', project: group_project)
    end
    let!(:group_note) { create(:note_on_issue, author: user, project: group_project, noteable: group_issue) }

    before do
      group_project.add_reporter(user)
    end
    let(:base_url) { "/groups/#{group.id}/issues" }

    it 'returns all group issues (including opened and closed)' do
      get v3_api(base_url, admin)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(3)
    end

    it 'returns group issues without confidential issues for non project members' do
      get v3_api("#{base_url}?state=opened", non_member)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['title']).to eq(group_issue.title)
    end

    it 'returns group confidential issues for author' do
      get v3_api("#{base_url}?state=opened", author)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(2)
    end

    it 'returns group confidential issues for assignee' do
      get v3_api("#{base_url}?state=opened", assignee)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(2)
    end

    it 'returns group issues with confidential issues for project members' do
      get v3_api("#{base_url}?state=opened", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(2)
    end

    it 'returns group confidential issues for admin' do
      get v3_api("#{base_url}?state=opened", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(2)
    end

    it 'returns an array of labeled group issues' do
      get v3_api("#{base_url}?labels=#{group_label.title}", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['labels']).to eq([group_label.title])
    end

    it 'returns an array of labeled group issues where all labels match' do
      get v3_api("#{base_url}?labels=#{group_label.title},foo,bar", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(0)
    end

    it 'returns an empty array if no group issue matches labels' do
      get v3_api("#{base_url}?labels=foo,bar", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(0)
    end

    it 'returns an empty array if no issue matches milestone' do
      get v3_api("#{base_url}?milestone=#{group_empty_milestone.title}", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(0)
    end

    it 'returns an empty array if milestone does not exist' do
      get v3_api("#{base_url}?milestone=foo", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(0)
    end

    it 'returns an array of issues in given milestone' do
      get v3_api("#{base_url}?state=opened&milestone=#{group_milestone.title}", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['id']).to eq(group_issue.id)
    end

    it 'returns an array of issues matching state in milestone' do
      get v3_api("#{base_url}?milestone=#{group_milestone.title}", user),
        '&state=closed'

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['id']).to eq(group_closed_issue.id)
    end

    it 'returns an array of issues with no milestone' do
      get v3_api("#{base_url}?milestone=#{no_milestone_title}", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['id']).to eq(group_confidential_issue.id)
    end

    it 'sorts by created_at descending by default' do
      get v3_api(base_url, user)

      response_dates = json_response.map { |issue| issue['created_at'] }

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(response_dates).to eq(response_dates.sort.reverse)
    end

    it 'sorts ascending when requested' do
      get v3_api("#{base_url}?sort=asc", user)

      response_dates = json_response.map { |issue| issue['created_at'] }

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(response_dates).to eq(response_dates.sort)
    end

    it 'sorts by updated_at descending when requested' do
      get v3_api("#{base_url}?order_by=updated_at", user)

      response_dates = json_response.map { |issue| issue['updated_at'] }

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(response_dates).to eq(response_dates.sort.reverse)
    end

    it 'sorts by updated_at ascending when requested' do
      get v3_api("#{base_url}?order_by=updated_at&sort=asc", user)

      response_dates = json_response.map { |issue| issue['updated_at'] }

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(response_dates).to eq(response_dates.sort)
    end
  end

  describe "GET /projects/:id/issues" do
    let(:base_url) { "/projects/#{project.id}" }

    it 'returns 404 when project does not exist' do
      get v3_api('/projects/1000/issues', non_member)

      expect(response).to have_gitlab_http_status(404)
    end

    it "returns 404 on private projects for other users" do
      private_project = create(:project, :private)
      create(:issue, project: private_project)

      get v3_api("/projects/#{private_project.id}/issues", non_member)

      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns no issues when user has access to project but not issues' do
      restricted_project = create(:project, :public, issues_access_level: ProjectFeature::PRIVATE)
      create(:issue, project: restricted_project)

      get v3_api("/projects/#{restricted_project.id}/issues", non_member)

      expect(json_response).to eq([])
    end

    it 'returns project issues without confidential issues for non project members' do
      get v3_api("#{base_url}/issues", non_member)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(2)
      expect(json_response.first['title']).to eq(issue.title)
    end

    it 'returns project issues without confidential issues for project members with guest role' do
      get v3_api("#{base_url}/issues", guest)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(2)
      expect(json_response.first['title']).to eq(issue.title)
    end

    it 'returns project confidential issues for author' do
      get v3_api("#{base_url}/issues", author)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(3)
      expect(json_response.first['title']).to eq(issue.title)
    end

    it 'returns project confidential issues for assignee' do
      get v3_api("#{base_url}/issues", assignee)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(3)
      expect(json_response.first['title']).to eq(issue.title)
    end

    it 'returns project issues with confidential issues for project members' do
      get v3_api("#{base_url}/issues", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(3)
      expect(json_response.first['title']).to eq(issue.title)
    end

    it 'returns project confidential issues for admin' do
      get v3_api("#{base_url}/issues", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(3)
      expect(json_response.first['title']).to eq(issue.title)
    end

    it 'returns an array of labeled project issues' do
      get v3_api("#{base_url}/issues?labels=#{label.title}", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['labels']).to eq([label.title])
    end

    it 'returns an array of labeled project issues where all labels match' do
      get v3_api("#{base_url}/issues?labels=#{label.title},foo,bar", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['labels']).to eq([label.title])
    end

    it 'returns an empty array if no project issue matches labels' do
      get v3_api("#{base_url}/issues?labels=foo,bar", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(0)
    end

    it 'returns an empty array if no issue matches milestone' do
      get v3_api("#{base_url}/issues?milestone=#{empty_milestone.title}", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(0)
    end

    it 'returns an empty array if milestone does not exist' do
      get v3_api("#{base_url}/issues?milestone=foo", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(0)
    end

    it 'returns an array of issues in given milestone' do
      get v3_api("#{base_url}/issues?milestone=#{milestone.title}", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(2)
      expect(json_response.first['id']).to eq(issue.id)
      expect(json_response.second['id']).to eq(closed_issue.id)
    end

    it 'returns an array of issues matching state in milestone' do
      get v3_api("#{base_url}/issues?milestone=#{milestone.title}", user),
        '&state=closed'

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['id']).to eq(closed_issue.id)
    end

    it 'returns an array of issues with no milestone' do
      get v3_api("#{base_url}/issues?milestone=#{no_milestone_title}", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['id']).to eq(confidential_issue.id)
    end

    it 'sorts by created_at descending by default' do
      get v3_api("#{base_url}/issues", user)

      response_dates = json_response.map { |issue| issue['created_at'] }

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(response_dates).to eq(response_dates.sort.reverse)
    end

    it 'sorts ascending when requested' do
      get v3_api("#{base_url}/issues?sort=asc", user)

      response_dates = json_response.map { |issue| issue['created_at'] }

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(response_dates).to eq(response_dates.sort)
    end

    it 'sorts by updated_at descending when requested' do
      get v3_api("#{base_url}/issues?order_by=updated_at", user)

      response_dates = json_response.map { |issue| issue['updated_at'] }

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(response_dates).to eq(response_dates.sort.reverse)
    end

    it 'sorts by updated_at ascending when requested' do
      get v3_api("#{base_url}/issues?order_by=updated_at&sort=asc", user)

      response_dates = json_response.map { |issue| issue['updated_at'] }

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_an Array
      expect(response_dates).to eq(response_dates.sort)
    end
  end

  describe "GET /projects/:id/issues/:issue_id" do
    it 'exposes known attributes' do
      get v3_api("/projects/#{project.id}/issues/#{issue.id}", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['id']).to eq(issue.id)
      expect(json_response['iid']).to eq(issue.iid)
      expect(json_response['project_id']).to eq(issue.project.id)
      expect(json_response['title']).to eq(issue.title)
      expect(json_response['description']).to eq(issue.description)
      expect(json_response['state']).to eq(issue.state)
      expect(json_response['created_at']).to be_present
      expect(json_response['updated_at']).to be_present
      expect(json_response['labels']).to eq(issue.label_names)
      expect(json_response['milestone']).to be_a Hash
      expect(json_response['assignee']).to be_a Hash
      expect(json_response['author']).to be_a Hash
      expect(json_response['confidential']).to be_falsy
    end

    it "returns a project issue by id" do
      get v3_api("/projects/#{project.id}/issues/#{issue.id}", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['title']).to eq(issue.title)
      expect(json_response['iid']).to eq(issue.iid)
    end

    it 'returns a project issue by iid' do
      get v3_api("/projects/#{project.id}/issues?iid=#{issue.iid}", user)

      expect(response.status).to eq 200
      expect(json_response.length).to eq 1
      expect(json_response.first['title']).to eq issue.title
      expect(json_response.first['id']).to eq issue.id
      expect(json_response.first['iid']).to eq issue.iid
    end

    it 'returns an empty array for an unknown project issue iid' do
      get v3_api("/projects/#{project.id}/issues?iid=#{issue.iid + 10}", user)

      expect(response.status).to eq 200
      expect(json_response.length).to eq 0
    end

    it "returns 404 if issue id not found" do
      get v3_api("/projects/#{project.id}/issues/54321", user)

      expect(response).to have_gitlab_http_status(404)
    end

    context 'confidential issues' do
      it "returns 404 for non project members" do
        get v3_api("/projects/#{project.id}/issues/#{confidential_issue.id}", non_member)

        expect(response).to have_gitlab_http_status(404)
      end

      it "returns 404 for project members with guest role" do
        get v3_api("/projects/#{project.id}/issues/#{confidential_issue.id}", guest)

        expect(response).to have_gitlab_http_status(404)
      end

      it "returns confidential issue for project members" do
        get v3_api("/projects/#{project.id}/issues/#{confidential_issue.id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['title']).to eq(confidential_issue.title)
        expect(json_response['iid']).to eq(confidential_issue.iid)
      end

      it "returns confidential issue for author" do
        get v3_api("/projects/#{project.id}/issues/#{confidential_issue.id}", author)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['title']).to eq(confidential_issue.title)
        expect(json_response['iid']).to eq(confidential_issue.iid)
      end

      it "returns confidential issue for assignee" do
        get v3_api("/projects/#{project.id}/issues/#{confidential_issue.id}", assignee)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['title']).to eq(confidential_issue.title)
        expect(json_response['iid']).to eq(confidential_issue.iid)
      end

      it "returns confidential issue for admin" do
        get v3_api("/projects/#{project.id}/issues/#{confidential_issue.id}", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['title']).to eq(confidential_issue.title)
        expect(json_response['iid']).to eq(confidential_issue.iid)
      end
    end
  end

  describe "POST /projects/:id/issues" do
    it 'creates a new project issue' do
      post v3_api("/projects/#{project.id}/issues", user),
        title: 'new issue', labels: 'label, label2', assignee_id: assignee.id

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['title']).to eq('new issue')
      expect(json_response['description']).to be_nil
      expect(json_response['labels']).to eq(%w(label label2))
      expect(json_response['confidential']).to be_falsy
      expect(json_response['assignee']['name']).to eq(assignee.name)
    end

    it 'creates a new confidential project issue' do
      post v3_api("/projects/#{project.id}/issues", user),
        title: 'new issue', confidential: true

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['title']).to eq('new issue')
      expect(json_response['confidential']).to be_truthy
    end

    it 'creates a new confidential project issue with a different param' do
      post v3_api("/projects/#{project.id}/issues", user),
        title: 'new issue', confidential: 'y'

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['title']).to eq('new issue')
      expect(json_response['confidential']).to be_truthy
    end

    it 'creates a public issue when confidential param is false' do
      post v3_api("/projects/#{project.id}/issues", user),
        title: 'new issue', confidential: false

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['title']).to eq('new issue')
      expect(json_response['confidential']).to be_falsy
    end

    it 'creates a public issue when confidential param is invalid' do
      post v3_api("/projects/#{project.id}/issues", user),
        title: 'new issue', confidential: 'foo'

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['error']).to eq('confidential is invalid')
    end

    it "returns a 400 bad request if title not given" do
      post v3_api("/projects/#{project.id}/issues", user), labels: 'label, label2'

      expect(response).to have_gitlab_http_status(400)
    end

    it 'allows special label names' do
      post v3_api("/projects/#{project.id}/issues", user),
           title: 'new issue',
           labels: 'label, label?, label&foo, ?, &'

      expect(response.status).to eq(201)
      expect(json_response['labels']).to include 'label'
      expect(json_response['labels']).to include 'label?'
      expect(json_response['labels']).to include 'label&foo'
      expect(json_response['labels']).to include '?'
      expect(json_response['labels']).to include '&'
    end

    it 'returns 400 if title is too long' do
      post v3_api("/projects/#{project.id}/issues", user),
           title: 'g' * 256

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']['title']).to eq([
        'is too long (maximum is 255 characters)'
      ])
    end

    context 'resolving issues in a merge request' do
      set(:diff_note_on_merge_request) { create(:diff_note_on_merge_request) }
      let(:discussion) { diff_note_on_merge_request.to_discussion }
      let(:merge_request) { discussion.noteable }
      let(:project) { merge_request.source_project }
      before do
        project.add_master(user)
        post v3_api("/projects/#{project.id}/issues", user),
             title: 'New Issue',
             merge_request_for_resolving_discussions: merge_request.iid
      end

      it 'creates a new project issue' do
        expect(response).to have_gitlab_http_status(:created)
      end

      it 'resolves the discussions in a merge request' do
        discussion.first_note.reload

        expect(discussion.resolved?).to be(true)
      end

      it 'assigns a description to the issue mentioning the merge request' do
        expect(json_response['description']).to include(merge_request.to_reference)
      end
    end

    context 'with due date' do
      it 'creates a new project issue' do
        due_date = 2.weeks.from_now.strftime('%Y-%m-%d')

        post v3_api("/projects/#{project.id}/issues", user),
          title: 'new issue', due_date: due_date

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['title']).to eq('new issue')
        expect(json_response['description']).to be_nil
        expect(json_response['due_date']).to eq(due_date)
      end
    end

    context 'when an admin or owner makes the request' do
      it 'accepts the creation date to be set' do
        creation_time = 2.weeks.ago
        post v3_api("/projects/#{project.id}/issues", user),
          title: 'new issue', labels: 'label, label2', created_at: creation_time

        expect(response).to have_gitlab_http_status(201)
        expect(Time.parse(json_response['created_at'])).to be_like_time(creation_time)
      end
    end

    context 'the user can only read the issue' do
      it 'cannot create new labels' do
        expect do
          post v3_api("/projects/#{project.id}/issues", non_member), title: 'new issue', labels: 'label, label2'
        end.not_to change { project.labels.count }
      end
    end
  end

  describe 'POST /projects/:id/issues with spam filtering' do
    before do
      allow_any_instance_of(SpamService).to receive(:check_for_spam?).and_return(true)
      allow_any_instance_of(AkismetService).to receive_messages(spam?: true)
    end

    let(:params) do
      {
        title: 'new issue',
        description: 'content here',
        labels: 'label, label2'
      }
    end

    it "does not create a new project issue" do
      expect { post v3_api("/projects/#{project.id}/issues", user), params }.not_to change(Issue, :count)

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']).to eq({ "error" => "Spam detected" })

      spam_logs = SpamLog.all

      expect(spam_logs.count).to eq(1)
      expect(spam_logs[0].title).to eq('new issue')
      expect(spam_logs[0].description).to eq('content here')
      expect(spam_logs[0].user).to eq(user)
      expect(spam_logs[0].noteable_type).to eq('Issue')
    end
  end

  describe "PUT /projects/:id/issues/:issue_id to update only title" do
    it "updates a project issue" do
      put v3_api("/projects/#{project.id}/issues/#{issue.id}", user),
        title: 'updated title'

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['title']).to eq('updated title')
    end

    it "returns 404 error if issue id not found" do
      put v3_api("/projects/#{project.id}/issues/44444", user),
        title: 'updated title'

      expect(response).to have_gitlab_http_status(404)
    end

    it 'allows special label names' do
      put v3_api("/projects/#{project.id}/issues/#{issue.id}", user),
          title: 'updated title',
          labels: 'label, label?, label&foo, ?, &'

      expect(response.status).to eq(200)
      expect(json_response['labels']).to include 'label'
      expect(json_response['labels']).to include 'label?'
      expect(json_response['labels']).to include 'label&foo'
      expect(json_response['labels']).to include '?'
      expect(json_response['labels']).to include '&'
    end

    context 'confidential issues' do
      it "returns 403 for non project members" do
        put v3_api("/projects/#{project.id}/issues/#{confidential_issue.id}", non_member),
          title: 'updated title'

        expect(response).to have_gitlab_http_status(403)
      end

      it "returns 403 for project members with guest role" do
        put v3_api("/projects/#{project.id}/issues/#{confidential_issue.id}", guest),
          title: 'updated title'

        expect(response).to have_gitlab_http_status(403)
      end

      it "updates a confidential issue for project members" do
        put v3_api("/projects/#{project.id}/issues/#{confidential_issue.id}", user),
          title: 'updated title'

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['title']).to eq('updated title')
      end

      it "updates a confidential issue for author" do
        put v3_api("/projects/#{project.id}/issues/#{confidential_issue.id}", author),
          title: 'updated title'

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['title']).to eq('updated title')
      end

      it "updates a confidential issue for admin" do
        put v3_api("/projects/#{project.id}/issues/#{confidential_issue.id}", admin),
          title: 'updated title'

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['title']).to eq('updated title')
      end

      it 'sets an issue to confidential' do
        put v3_api("/projects/#{project.id}/issues/#{issue.id}", user),
          confidential: true

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['confidential']).to be_truthy
      end

      it 'makes a confidential issue public' do
        put v3_api("/projects/#{project.id}/issues/#{confidential_issue.id}", user),
          confidential: false

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['confidential']).to be_falsy
      end

      it 'does not update a confidential issue with wrong confidential flag' do
        put v3_api("/projects/#{project.id}/issues/#{confidential_issue.id}", user),
          confidential: 'foo'

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['error']).to eq('confidential is invalid')
      end
    end
  end

  describe 'PUT /projects/:id/issues/:issue_id with spam filtering' do
    let(:params) do
      {
        title: 'updated title',
        description: 'content here',
        labels: 'label, label2'
      }
    end

    it "does not create a new project issue" do
      allow_any_instance_of(SpamService).to receive_messages(check_for_spam?: true)
      allow_any_instance_of(AkismetService).to receive_messages(spam?: true)

      put v3_api("/projects/#{project.id}/issues/#{issue.id}", user), params

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']).to eq({ "error" => "Spam detected" })

      spam_logs = SpamLog.all
      expect(spam_logs.count).to eq(1)
      expect(spam_logs[0].title).to eq('updated title')
      expect(spam_logs[0].description).to eq('content here')
      expect(spam_logs[0].user).to eq(user)
      expect(spam_logs[0].noteable_type).to eq('Issue')
    end
  end

  describe 'PUT /projects/:id/issues/:issue_id to update labels' do
    let!(:label) { create(:label, title: 'dummy', project: project) }
    let!(:label_link) { create(:label_link, label: label, target: issue) }

    it 'does not update labels if not present' do
      put v3_api("/projects/#{project.id}/issues/#{issue.id}", user),
          title: 'updated title'

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['labels']).to eq([label.title])
    end

    it 'removes all labels' do
      put v3_api("/projects/#{project.id}/issues/#{issue.id}", user), labels: ''

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['labels']).to eq([])
    end

    it 'updates labels' do
      put v3_api("/projects/#{project.id}/issues/#{issue.id}", user),
          labels: 'foo,bar'

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['labels']).to include 'foo'
      expect(json_response['labels']).to include 'bar'
    end

    it 'allows special label names' do
      put v3_api("/projects/#{project.id}/issues/#{issue.id}", user),
          labels: 'label:foo, label-bar,label_bar,label/bar,label?bar,label&bar,?,&'

      expect(response.status).to eq(200)
      expect(json_response['labels']).to include 'label:foo'
      expect(json_response['labels']).to include 'label-bar'
      expect(json_response['labels']).to include 'label_bar'
      expect(json_response['labels']).to include 'label/bar'
      expect(json_response['labels']).to include 'label?bar'
      expect(json_response['labels']).to include 'label&bar'
      expect(json_response['labels']).to include '?'
      expect(json_response['labels']).to include '&'
    end

    it 'returns 400 if title is too long' do
      put v3_api("/projects/#{project.id}/issues/#{issue.id}", user),
          title: 'g' * 256

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']['title']).to eq([
        'is too long (maximum is 255 characters)'
      ])
    end
  end

  describe "PUT /projects/:id/issues/:issue_id to update state and label" do
    it "updates a project issue" do
      put v3_api("/projects/#{project.id}/issues/#{issue.id}", user),
        labels: 'label2', state_event: "close"

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['labels']).to include 'label2'
      expect(json_response['state']).to eq "closed"
    end

    it 'reopens a project isssue' do
      put v3_api("/projects/#{project.id}/issues/#{closed_issue.id}", user), state_event: 'reopen'

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['state']).to eq 'opened'
    end

    context 'when an admin or owner makes the request' do
      it 'accepts the update date to be set' do
        update_time = 2.weeks.ago
        put v3_api("/projects/#{project.id}/issues/#{issue.id}", user),
          labels: 'label3', state_event: 'close', updated_at: update_time

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['labels']).to include 'label3'
        expect(Time.parse(json_response['updated_at'])).to be_like_time(update_time)
      end
    end
  end

  describe 'PUT /projects/:id/issues/:issue_id to update due date' do
    it 'creates a new project issue' do
      due_date = 2.weeks.from_now.strftime('%Y-%m-%d')

      put v3_api("/projects/#{project.id}/issues/#{issue.id}", user), due_date: due_date

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['due_date']).to eq(due_date)
    end
  end

  describe 'PUT /projects/:id/issues/:issue_id to update assignee' do
    it 'updates an issue with no assignee' do
      put v3_api("/projects/#{project.id}/issues/#{issue.id}", user), assignee_id: 0

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['assignee']).to eq(nil)
    end

    it 'updates an issue with assignee' do
      put v3_api("/projects/#{project.id}/issues/#{issue.id}", user), assignee_id: user2.id

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['assignee']['name']).to eq(user2.name)
    end
  end

  describe "DELETE /projects/:id/issues/:issue_id" do
    it "rejects a non member from deleting an issue" do
      delete v3_api("/projects/#{project.id}/issues/#{issue.id}", non_member)

      expect(response).to have_gitlab_http_status(403)
    end

    it "rejects a developer from deleting an issue" do
      delete v3_api("/projects/#{project.id}/issues/#{issue.id}", author)

      expect(response).to have_gitlab_http_status(403)
    end

    context "when the user is project owner" do
      set(:owner)     { create(:user) }
      let(:project)   { create(:project, namespace: owner.namespace) }

      it "deletes the issue if an admin requests it" do
        delete v3_api("/projects/#{project.id}/issues/#{issue.id}", owner)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['state']).to eq 'opened'
      end
    end

    context 'when issue does not exist' do
      it 'returns 404 when trying to move an issue' do
        delete v3_api("/projects/#{project.id}/issues/123", user)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe '/projects/:id/issues/:issue_id/move' do
    let!(:target_project) { create(:project, creator_id: user.id, namespace: user.namespace ) }
    let!(:target_project2) { create(:project, creator_id: non_member.id, namespace: non_member.namespace ) }

    it 'moves an issue' do
      post v3_api("/projects/#{project.id}/issues/#{issue.id}/move", user),
               to_project_id: target_project.id

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['project_id']).to eq(target_project.id)
    end

    context 'when source and target projects are the same' do
      it 'returns 400 when trying to move an issue' do
        post v3_api("/projects/#{project.id}/issues/#{issue.id}/move", user),
                 to_project_id: project.id

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['message']).to eq('Cannot move issue to project it originates from!')
      end
    end

    context 'when the user does not have the permission to move issues' do
      it 'returns 400 when trying to move an issue' do
        post v3_api("/projects/#{project.id}/issues/#{issue.id}/move", user),
                 to_project_id: target_project2.id

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['message']).to eq('Cannot move issue due to insufficient permissions!')
      end
    end

    it 'moves the issue to another namespace if I am admin' do
      post v3_api("/projects/#{project.id}/issues/#{issue.id}/move", admin),
               to_project_id: target_project2.id

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['project_id']).to eq(target_project2.id)
    end

    context 'when issue does not exist' do
      it 'returns 404 when trying to move an issue' do
        post v3_api("/projects/#{project.id}/issues/123/move", user),
                 to_project_id: target_project.id

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq('404 Issue Not Found')
      end
    end

    context 'when source project does not exist' do
      it 'returns 404 when trying to move an issue' do
        post v3_api("/projects/0/issues/#{issue.id}/move", user),
                 to_project_id: target_project.id

        expect(response).to have_gitlab_http_status(404)
        expect(json_response['message']).to eq('404 Project Not Found')
      end
    end

    context 'when target project does not exist' do
      it 'returns 404 when trying to move an issue' do
        post v3_api("/projects/#{project.id}/issues/#{issue.id}/move", user),
                 to_project_id: 0

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'POST :id/issues/:issue_id/subscription' do
    it 'subscribes to an issue' do
      post v3_api("/projects/#{project.id}/issues/#{issue.id}/subscription", user2)

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['subscribed']).to eq(true)
    end

    it 'returns 304 if already subscribed' do
      post v3_api("/projects/#{project.id}/issues/#{issue.id}/subscription", user)

      expect(response).to have_gitlab_http_status(304)
    end

    it 'returns 404 if the issue is not found' do
      post v3_api("/projects/#{project.id}/issues/123/subscription", user)

      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns 404 if the issue is confidential' do
      post v3_api("/projects/#{project.id}/issues/#{confidential_issue.id}/subscription", non_member)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'DELETE :id/issues/:issue_id/subscription' do
    it 'unsubscribes from an issue' do
      delete v3_api("/projects/#{project.id}/issues/#{issue.id}/subscription", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['subscribed']).to eq(false)
    end

    it 'returns 304 if not subscribed' do
      delete v3_api("/projects/#{project.id}/issues/#{issue.id}/subscription", user2)

      expect(response).to have_gitlab_http_status(304)
    end

    it 'returns 404 if the issue is not found' do
      delete v3_api("/projects/#{project.id}/issues/123/subscription", user)

      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns 404 if the issue is confidential' do
      delete v3_api("/projects/#{project.id}/issues/#{confidential_issue.id}/subscription", non_member)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'time tracking endpoints' do
    let(:issuable) { issue }

    include_examples 'V3 time tracking endpoints', 'issue'
  end
end
