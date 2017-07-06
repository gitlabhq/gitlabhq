require 'spec_helper'

describe API::Milestones do
  let(:user) { create(:user) }
  let!(:project) { create(:empty_project, namespace: user.namespace ) }
  let!(:closed_milestone) { create(:closed_milestone, project: project, title: 'version1', description: 'closed milestone') }
  let!(:milestone) { create(:milestone, project: project, title: 'version2', description: 'open milestone') }
  let(:label_1) { create(:label, title: 'label_1', project: project, priority: 1) }
  let(:label_2) { create(:label, title: 'label_2', project: project, priority: 2) }
  let(:label_3) { create(:label, title: 'label_3', project: project) }

  before do
    project.team << [user, :developer]

    stub_licensed_features(issue_weights: false)
  end

  describe 'GET /projects/:id/milestones' do
    it 'returns project milestones' do
      get api("/projects/#{project.id}/milestones", user)

      expect(response).to have_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.first['title']).to eq(milestone.title)
    end

    it 'returns a 401 error if user not authenticated' do
      get api("/projects/#{project.id}/milestones")

      expect(response).to have_http_status(401)
    end

    it 'returns an array of active milestones' do
      get api("/projects/#{project.id}/milestones?state=active", user)

      expect(response).to have_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['id']).to eq(milestone.id)
    end

    it 'returns an array of closed milestones' do
      get api("/projects/#{project.id}/milestones?state=closed", user)

      expect(response).to have_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['id']).to eq(closed_milestone.id)
    end

    it 'returns an array of milestones specified by iids' do
      other_milestone = create(:milestone, project: project)

      get api("/projects/#{project.id}/milestones", user), iids: [closed_milestone.iid, other_milestone.iid]

      expect(response).to have_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(2)
      expect(json_response.map{ |m| m['id'] }).to match_array([closed_milestone.id, other_milestone.id])
    end

    it 'does not return any milestone if none found' do
      get api("/projects/#{project.id}/milestones", user), iids: [Milestone.maximum(:iid).succ]

      expect(response).to have_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(0)
    end
  end

  describe 'GET /projects/:id/milestones/:milestone_id' do
    it 'returns a project milestone by id' do
      get api("/projects/#{project.id}/milestones/#{milestone.id}", user)

      expect(response).to have_http_status(200)
      expect(json_response['title']).to eq(milestone.title)
      expect(json_response['iid']).to eq(milestone.iid)
    end

    it 'returns a project milestone by iids array' do
      get api("/projects/#{project.id}/milestones?iids=#{closed_milestone.iid}", user)

      expect(response.status).to eq 200
      expect(response).to include_pagination_headers
      expect(json_response.size).to eq(1)
      expect(json_response.size).to eq(1)
      expect(json_response.first['title']).to eq closed_milestone.title
      expect(json_response.first['id']).to eq closed_milestone.id
    end

    it 'returns a project milestone by searching for title' do
      get api("/projects/#{project.id}/milestones", user), search: 'version2'

      expect(response).to have_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response.size).to eq(1)
      expect(json_response.first['title']).to eq milestone.title
      expect(json_response.first['id']).to eq milestone.id
    end

    it 'returns a project milestones by searching for description' do
      get api("/projects/#{project.id}/milestones", user), search: 'open'

      expect(response).to have_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response.size).to eq(1)
      expect(json_response.first['title']).to eq milestone.title
      expect(json_response.first['id']).to eq milestone.id
    end
  end

  describe 'GET /projects/:id/milestones/:milestone_id' do
    it 'returns a project milestone by id' do
      get api("/projects/#{project.id}/milestones/#{milestone.id}", user)

      expect(response).to have_http_status(200)
      expect(json_response['title']).to eq(milestone.title)
      expect(json_response['iid']).to eq(milestone.iid)
    end

    it 'returns 401 error if user not authenticated' do
      get api("/projects/#{project.id}/milestones/#{milestone.id}")

      expect(response).to have_http_status(401)
    end

    it 'returns a 404 error if milestone id not found' do
      get api("/projects/#{project.id}/milestones/1234", user)

      expect(response).to have_http_status(404)
    end
  end

  describe 'POST /projects/:id/milestones' do
    it 'creates a new project milestone' do
      post api("/projects/#{project.id}/milestones", user), title: 'new milestone'

      expect(response).to have_http_status(201)
      expect(json_response['title']).to eq('new milestone')
      expect(json_response['description']).to be_nil
    end

    it 'creates a new project milestone with description and dates' do
      post api("/projects/#{project.id}/milestones", user),
        title: 'new milestone', description: 'release', due_date: '2013-03-02', start_date: '2013-02-02'

      expect(response).to have_http_status(201)
      expect(json_response['description']).to eq('release')
      expect(json_response['due_date']).to eq('2013-03-02')
      expect(json_response['start_date']).to eq('2013-02-02')
    end

    it 'returns a 400 error if title is missing' do
      post api("/projects/#{project.id}/milestones", user)

      expect(response).to have_http_status(400)
    end

    it 'returns a 400 error if params are invalid (duplicate title)' do
      post api("/projects/#{project.id}/milestones", user),
        title: milestone.title, description: 'release', due_date: '2013-03-02'

      expect(response).to have_http_status(400)
    end

    it 'creates a new project with reserved html characters' do
      post api("/projects/#{project.id}/milestones", user), title: 'foo & bar 1.1 -> 2.2'

      expect(response).to have_http_status(201)
      expect(json_response['title']).to eq('foo & bar 1.1 -> 2.2')
      expect(json_response['description']).to be_nil
    end
  end

  describe 'PUT /projects/:id/milestones/:milestone_id' do
    it 'updates a project milestone' do
      put api("/projects/#{project.id}/milestones/#{milestone.id}", user),
        title: 'updated title'

      expect(response).to have_http_status(200)
      expect(json_response['title']).to eq('updated title')
    end

    it 'removes a due date if nil is passed' do
      milestone.update!(due_date: "2016-08-05")

      put api("/projects/#{project.id}/milestones/#{milestone.id}", user), due_date: nil

      expect(response).to have_http_status(200)
      expect(json_response['due_date']).to be_nil
    end

    it 'returns a 404 error if milestone id not found' do
      put api("/projects/#{project.id}/milestones/1234", user),
        title: 'updated title'

      expect(response).to have_http_status(404)
    end
  end

  describe 'PUT /projects/:id/milestones/:milestone_id to close milestone' do
    it 'updates a project milestone' do
      put api("/projects/#{project.id}/milestones/#{milestone.id}", user),
        state_event: 'close'
      expect(response).to have_http_status(200)

      expect(json_response['state']).to eq('closed')
    end
  end

  describe 'PUT /projects/:id/milestones/:milestone_id to test observer on close' do
    it 'creates an activity event when an milestone is closed' do
      expect(Event).to receive(:create)

      put api("/projects/#{project.id}/milestones/#{milestone.id}", user),
          state_event: 'close'
    end
  end

  describe 'GET /projects/:id/milestones/:milestone_id/issues' do
    before do
      milestone.issues << create(:issue, project: project)
    end
    it 'returns project issues for a particular milestone' do
      get api("/projects/#{project.id}/milestones/#{milestone.id}/issues", user)

      expect(response).to have_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.first['milestone']['title']).to eq(milestone.title)
    end

    it 'returns project issues sorted by label priority' do
      issue_1 = create(:labeled_issue, project: project, milestone: milestone, labels: [label_3])
      issue_2 = create(:labeled_issue, project: project, milestone: milestone, labels: [label_1])
      issue_3 = create(:labeled_issue, project: project, milestone: milestone, labels: [label_2])

      get api("/projects/#{project.id}/milestones/#{milestone.id}/issues", user)

      expect(json_response.first['id']).to eq(issue_2.id)
      expect(json_response.second['id']).to eq(issue_3.id)
      expect(json_response.third['id']).to eq(issue_1.id)
    end

    it 'matches V4 response schema for a list of issues' do
      get api("/projects/#{project.id}/milestones/#{milestone.id}/issues", user)

      expect(response).to have_http_status(200)
      expect(response).to match_response_schema('public_api/v4/issues')
    end

    it 'returns a 401 error if user not authenticated' do
      get api("/projects/#{project.id}/milestones/#{milestone.id}/issues")

      expect(response).to have_http_status(401)
    end

    describe 'confidential issues' do
      let(:public_project) { create(:empty_project, :public) }
      let(:milestone) { create(:milestone, project: public_project) }
      let(:issue) { create(:issue, project: public_project) }
      let(:confidential_issue) { create(:issue, confidential: true, project: public_project) }

      before do
        public_project.team << [user, :developer]
        milestone.issues << issue << confidential_issue
      end

      it 'returns confidential issues to team members' do
        get api("/projects/#{public_project.id}/milestones/#{milestone.id}/issues", user)

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(2)
        expect(json_response.map { |issue| issue['id'] }).to include(issue.id, confidential_issue.id)
      end

      it 'does not return confidential issues to team members with guest role' do
        member = create(:user)
        project.team << [member, :guest]

        get api("/projects/#{public_project.id}/milestones/#{milestone.id}/issues", member)

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(1)
        expect(json_response.map { |issue| issue['id'] }).to include(issue.id)
      end

      it 'does not return confidential issues to regular users' do
        get api("/projects/#{public_project.id}/milestones/#{milestone.id}/issues", create(:user))

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(1)
        expect(json_response.map { |issue| issue['id'] }).to include(issue.id)
      end

      it 'returns issues ordered by label priority' do
        issue.labels << label_2
        confidential_issue.labels << label_1

        get api("/projects/#{public_project.id}/milestones/#{milestone.id}/issues", user)

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(2)
        expect(json_response.first['id']).to eq(confidential_issue.id)
        expect(json_response.second['id']).to eq(issue.id)
      end
    end
  end

  describe 'GET /projects/:id/milestones/:milestone_id/merge_requests' do
    let(:merge_request) { create(:merge_request, source_project: project) }
    let(:another_merge_request) { create(:merge_request, :simple, source_project: project) }

    before do
      milestone.merge_requests << merge_request
    end

    it 'returns project merge_requests for a particular milestone' do
      # eager-load another_merge_request
      another_merge_request
      get api("/projects/#{project.id}/milestones/#{milestone.id}/merge_requests", user)

      expect(response).to have_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(1)
      expect(json_response.first['title']).to eq(merge_request.title)
      expect(json_response.first['milestone']['title']).to eq(milestone.title)
    end

    it 'returns project merge_requests sorted by label priority' do
      merge_request_1 = create(:labeled_merge_request, source_branch: 'branch_1', source_project: project, milestone: milestone, labels: [label_2])
      merge_request_2 = create(:labeled_merge_request, source_branch: 'branch_2', source_project: project, milestone: milestone, labels: [label_1])
      merge_request_3 = create(:labeled_merge_request, source_branch: 'branch_3', source_project: project, milestone: milestone, labels: [label_3])

      get api("/projects/#{project.id}/milestones/#{milestone.id}/merge_requests", user)

      expect(json_response.first['id']).to eq(merge_request_2.id)
      expect(json_response.second['id']).to eq(merge_request_1.id)
      expect(json_response.third['id']).to eq(merge_request_3.id)
    end

    it 'returns a 404 error if milestone id not found' do
      get api("/projects/#{project.id}/milestones/1234/merge_requests", user)

      expect(response).to have_http_status(404)
    end

    it 'returns a 404 if the user has no access to the milestone' do
      new_user = create :user
      get api("/projects/#{project.id}/milestones/#{milestone.id}/merge_requests", new_user)

      expect(response).to have_http_status(404)
    end

    it 'returns a 401 error if user not authenticated' do
      get api("/projects/#{project.id}/milestones/#{milestone.id}/merge_requests")

      expect(response).to have_http_status(401)
    end

    it 'returns merge_requests ordered by position asc' do
      milestone.merge_requests << another_merge_request
      another_merge_request.labels << label_1
      merge_request.labels << label_2

      get api("/projects/#{project.id}/milestones/#{milestone.id}/merge_requests", user)

      expect(response).to have_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(2)
      expect(json_response.first['id']).to eq(another_merge_request.id)
      expect(json_response.second['id']).to eq(merge_request.id)
    end
  end
end
