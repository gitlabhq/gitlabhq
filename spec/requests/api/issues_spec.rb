require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
  let!(:project) { create(:project, namespace: user.namespace ) }
  let!(:closed_issue) do
    create :closed_issue,
           author: user,
           assignee: user,
           project: project,
           state: :closed,
           milestone: milestone
  end
  let!(:issue) do
    create :issue,
           author: user,
           assignee: user,
           project: project,
           milestone: milestone
  end
  let!(:label) do
    create(:label, title: 'label', color: '#FFAABB', project: project)
  end
  let!(:label_link) { create(:label_link, label: label, target: issue) }
  let!(:milestone) { create(:milestone, title: '1.0.0', project: project) }
  let!(:empty_milestone) do
    create(:milestone, title: '2.0.0', project: project)
  end

  before { project.team << [user, :reporter] }

  describe "GET /issues" do
    context "when unauthenticated" do
      it "should return authentication error" do
        get api("/issues")
        expect(response.status).to eq(401)
      end
    end

    context "when authenticated" do
      it "should return an array of issues" do
        get api("/issues", user)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.first['title']).to eq(issue.title)
      end

      it "should add pagination headers and keep query params" do
        get api("/issues?state=closed&per_page=3", user)
        expect(response.headers['Link']).to eq(
          '<http://www.example.com/api/v3/issues?page=1&per_page=3&private_token=%s&state=closed>; rel="first", <http://www.example.com/api/v3/issues?page=1&per_page=3&private_token=%s&state=closed>; rel="last"' % [user.private_token, user.private_token]
        )
      end

      it 'should return an array of closed issues' do
        get api('/issues?state=closed', user)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(closed_issue.id)
      end

      it 'should return an array of opened issues' do
        get api('/issues?state=opened', user)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['id']).to eq(issue.id)
      end

      it 'should return an array of all issues' do
        get api('/issues?state=all', user)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(2)
        expect(json_response.first['id']).to eq(issue.id)
        expect(json_response.second['id']).to eq(closed_issue.id)
      end

      it 'should return an array of labeled issues' do
        get api("/issues?labels=#{label.title}", user)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['labels']).to eq([label.title])
      end

      it 'should return an array of labeled issues when at least one label matches' do
        get api("/issues?labels=#{label.title},foo,bar", user)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['labels']).to eq([label.title])
      end

      it 'should return an empty array if no issue matches labels' do
        get api('/issues?labels=foo,bar', user)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(0)
      end

      it 'should return an array of labeled issues matching given state' do
        get api("/issues?labels=#{label.title}&state=opened", user)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first['labels']).to eq([label.title])
        expect(json_response.first['state']).to eq('opened')
      end

      it 'should return an empty array if no issue matches labels and state filters' do
        get api("/issues?labels=#{label.title}&state=closed", user)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(0)
      end
    end
  end

  describe "GET /projects/:id/issues" do
    let(:base_url) { "/projects/#{project.id}" }
    let(:title) { milestone.title }

    it "should return project issues" do
      get api("#{base_url}/issues", user)
      expect(response.status).to eq(200)
      expect(json_response).to be_an Array
      expect(json_response.first['title']).to eq(issue.title)
    end

    it 'should return an array of labeled project issues' do
      get api("#{base_url}/issues?labels=#{label.title}", user)
      expect(response.status).to eq(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['labels']).to eq([label.title])
    end

    it 'should return an array of labeled project issues when at least one label matches' do
      get api("#{base_url}/issues?labels=#{label.title},foo,bar", user)
      expect(response.status).to eq(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['labels']).to eq([label.title])
    end

    it 'should return an empty array if no project issue matches labels' do
      get api("#{base_url}/issues?labels=foo,bar", user)
      expect(response.status).to eq(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(0)
    end

    it 'should return an empty array if no issue matches milestone' do
      get api("#{base_url}/issues?milestone=#{empty_milestone.title}", user)
      expect(response.status).to eq(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(0)
    end

    it 'should return an empty array if milestone does not exist' do
      get api("#{base_url}/issues?milestone=foo", user)
      expect(response.status).to eq(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(0)
    end

    it 'should return an array of issues in given milestone' do
      get api("#{base_url}/issues?milestone=#{title}", user)
      expect(response.status).to eq(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(2)
      expect(json_response.first['id']).to eq(issue.id)
      expect(json_response.second['id']).to eq(closed_issue.id)
    end

    it 'should return an array of issues matching state in milestone' do
      get api("#{base_url}/issues?milestone=#{milestone.title}"\
              '&state=closed', user)
      expect(response.status).to eq(200)
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(1)
      expect(json_response.first['id']).to eq(closed_issue.id)
    end
  end

  describe "GET /projects/:id/issues/:issue_id" do
    it "should return a project issue by id" do
      get api("/projects/#{project.id}/issues/#{issue.id}", user)
      expect(response.status).to eq(200)
      expect(json_response['title']).to eq(issue.title)
      expect(json_response['iid']).to eq(issue.iid)
    end

    it 'should return a project issue by iid' do
      get api("/projects/#{project.id}/issues?iid=#{issue.iid}", user)
      expect(response.status).to eq 200
      expect(json_response.first['title']).to eq issue.title
      expect(json_response.first['id']).to eq issue.id
      expect(json_response.first['iid']).to eq issue.iid
    end

    it "should return 404 if issue id not found" do
      get api("/projects/#{project.id}/issues/54321", user)
      expect(response.status).to eq(404)
    end
  end

  describe "POST /projects/:id/issues" do
    it "should create a new project issue" do
      post api("/projects/#{project.id}/issues", user),
        title: 'new issue', labels: 'label, label2'
      expect(response.status).to eq(201)
      expect(json_response['title']).to eq('new issue')
      expect(json_response['description']).to be_nil
      expect(json_response['labels']).to eq(['label', 'label2'])
    end

    it "should return a 400 bad request if title not given" do
      post api("/projects/#{project.id}/issues", user), labels: 'label, label2'
      expect(response.status).to eq(400)
    end

    it 'should return 400 on invalid label names' do
      post api("/projects/#{project.id}/issues", user),
           title: 'new issue',
           labels: 'label, ?'
      expect(response.status).to eq(400)
      expect(json_response['message']['labels']['?']['title']).to eq(['is invalid'])
    end

    it 'should return 400 if title is too long' do
      post api("/projects/#{project.id}/issues", user),
           title: 'g' * 256
      expect(response.status).to eq(400)
      expect(json_response['message']['title']).to eq([
        'is too long (maximum is 255 characters)'
      ])
    end
  end

  describe 'POST /projects/:id/issues with spam filtering' do
    before do
      Grape::Endpoint.before_each do |endpoint|
        allow(endpoint).to receive(:check_for_spam?).and_return(true)
        allow(endpoint).to receive(:is_spam?).and_return(true)
      end
    end

    let(:params) do
      {
        title: 'new issue',
        description: 'content here',
        labels: 'label, label2'
      }
    end

    it "should not create a new project issue" do
      expect { post api("/projects/#{project.id}/issues", user), params }.not_to change(Issue, :count)
      expect(response.status).to eq(400)
      expect(json_response['message']).to eq({ "error" => "Spam detected" })

      spam_logs = SpamLog.all
      expect(spam_logs.count).to eq(1)
      expect(spam_logs[0].title).to eq('new issue')
      expect(spam_logs[0].description).to eq('content here')
      expect(spam_logs[0].user).to eq(user)
      expect(spam_logs[0].noteable_type).to eq('Issue')
      expect(spam_logs[0].project_id).to eq(project.id)
    end
  end

  describe "PUT /projects/:id/issues/:issue_id to update only title" do
    it "should update a project issue" do
      put api("/projects/#{project.id}/issues/#{issue.id}", user),
        title: 'updated title'
      expect(response.status).to eq(200)

      expect(json_response['title']).to eq('updated title')
    end

    it "should return 404 error if issue id not found" do
      put api("/projects/#{project.id}/issues/44444", user),
        title: 'updated title'
      expect(response.status).to eq(404)
    end

    it 'should return 400 on invalid label names' do
      put api("/projects/#{project.id}/issues/#{issue.id}", user),
          title: 'updated title',
          labels: 'label, ?'
      expect(response.status).to eq(400)
      expect(json_response['message']['labels']['?']['title']).to eq(['is invalid'])
    end
  end

  describe 'PUT /projects/:id/issues/:issue_id to update labels' do
    let!(:label) { create(:label, title: 'dummy', project: project) }
    let!(:label_link) { create(:label_link, label: label, target: issue) }

    it 'should not update labels if not present' do
      put api("/projects/#{project.id}/issues/#{issue.id}", user),
          title: 'updated title'
      expect(response.status).to eq(200)
      expect(json_response['labels']).to eq([label.title])
    end

    it 'should remove all labels' do
      put api("/projects/#{project.id}/issues/#{issue.id}", user),
          labels: ''
      expect(response.status).to eq(200)
      expect(json_response['labels']).to eq([])
    end

    it 'should update labels' do
      put api("/projects/#{project.id}/issues/#{issue.id}", user),
          labels: 'foo,bar'
      expect(response.status).to eq(200)
      expect(json_response['labels']).to include 'foo'
      expect(json_response['labels']).to include 'bar'
    end

    it 'should return 400 on invalid label names' do
      put api("/projects/#{project.id}/issues/#{issue.id}", user),
          labels: 'label, ?'
      expect(response.status).to eq(400)
      expect(json_response['message']['labels']['?']['title']).to eq(['is invalid'])
    end

    it 'should allow special label names' do
      put api("/projects/#{project.id}/issues/#{issue.id}", user),
          labels: 'label:foo, label-bar,label_bar,label/bar'
      expect(response.status).to eq(200)
      expect(json_response['labels']).to include 'label:foo'
      expect(json_response['labels']).to include 'label-bar'
      expect(json_response['labels']).to include 'label_bar'
      expect(json_response['labels']).to include 'label/bar'
    end

    it 'should return 400 if title is too long' do
      put api("/projects/#{project.id}/issues/#{issue.id}", user),
          title: 'g' * 256
      expect(response.status).to eq(400)
      expect(json_response['message']['title']).to eq([
        'is too long (maximum is 255 characters)'
      ])
    end
  end

  describe "PUT /projects/:id/issues/:issue_id to update state and label" do
    it "should update a project issue" do
      put api("/projects/#{project.id}/issues/#{issue.id}", user),
        labels: 'label2', state_event: "close"
      expect(response.status).to eq(200)

      expect(json_response['labels']).to include 'label2'
      expect(json_response['state']).to eq "closed"
    end
  end

  describe "DELETE /projects/:id/issues/:issue_id" do
    it "should delete a project issue" do
      delete api("/projects/#{project.id}/issues/#{issue.id}", user)
      expect(response.status).to eq(405)
    end
  end
end
