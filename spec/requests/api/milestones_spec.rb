require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
  let!(:project) { create(:empty_project, namespace: user.namespace ) }
  let!(:closed_milestone) { create(:closed_milestone, project: project) }
  let!(:milestone) { create(:milestone, project: project) }

  before { project.team << [user, :developer] }

  describe 'GET /projects/:id/milestones' do
    it 'returns project milestones' do
      get api("/projects/#{project.id}/milestones", user)

      expect(response).to have_http_status(200)
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
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['id']).to eq(milestone.id)
    end

    it 'returns an array of closed milestones' do
      get api("/projects/#{project.id}/milestones?state=closed", user)

      expect(response).to have_http_status(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['id']).to eq(closed_milestone.id)
    end
  end

  describe 'GET /projects/:id/milestones/:milestone_id' do
    it 'returns a project milestone by id' do
      get api("/projects/#{project.id}/milestones/#{milestone.id}", user)

      expect(response).to have_http_status(200)
      expect(json_response['title']).to eq(milestone.title)
      expect(json_response['iid']).to eq(milestone.iid)
    end

    it 'returns a project milestone by iid' do
      get api("/projects/#{project.id}/milestones?iid=#{closed_milestone.iid}", user)

      expect(response.status).to eq 200
      expect(json_response.size).to eq(1)
      expect(json_response.first['title']).to eq closed_milestone.title
      expect(json_response.first['id']).to eq closed_milestone.id
    end

    it 'returns a project milestone by iid array' do
      get api("/projects/#{project.id}/milestones", user), iid: [milestone.iid, closed_milestone.iid]

      expect(response).to have_http_status(200)
      expect(json_response.size).to eq(2)
      expect(json_response.first['title']).to eq milestone.title
      expect(json_response.first['id']).to eq milestone.id
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

    it 'creates a new project milestone with description and due date' do
      post api("/projects/#{project.id}/milestones", user),
        title: 'new milestone', description: 'release', due_date: '2013-03-02'

      expect(response).to have_http_status(201)
      expect(json_response['description']).to eq('release')
      expect(json_response['due_date']).to eq('2013-03-02')
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
      expect(json_response).to be_an Array
      expect(json_response.first['milestone']['title']).to eq(milestone.title)
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
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(2)
        expect(json_response.map { |issue| issue['id'] }).to include(issue.id, confidential_issue.id)
      end

      it 'does not return confidential issues to team members with guest role' do
        member = create(:user)
        project.team << [member, :guest]

        get api("/projects/#{public_project.id}/milestones/#{milestone.id}/issues", member)

        expect(response).to have_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(1)
        expect(json_response.map { |issue| issue['id'] }).to include(issue.id)
      end

      it 'does not return confidential issues to regular users' do
        get api("/projects/#{public_project.id}/milestones/#{milestone.id}/issues", create(:user))

        expect(response).to have_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(1)
        expect(json_response.map { |issue| issue['id'] }).to include(issue.id)
      end
    end
  end
end
