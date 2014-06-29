require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
  let!(:project) { create(:project, namespace: user.namespace ) }
  let!(:issue) { create(:issue, author: user, assignee: user, project: project) }
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

      it "should add pagination headers" do
        get api("/issues?per_page=3", user)
        expect(response.headers['Link']).to eq(
          '<http://www.example.com/api/v3/issues?page=1&per_page=3>; rel="first", <http://www.example.com/api/v3/issues?page=1&per_page=3>; rel="last"'
        )
      end
    end
  end

  describe "GET /projects/:id/issues" do
    it "should return project issues" do
      get api("/projects/#{project.id}/issues", user)
      expect(response.status).to eq(200)
      expect(json_response).to be_an Array
      expect(json_response.first['title']).to eq(issue.title)
    end
  end

  describe "GET /projects/:id/issues/:issue_id" do
    it "should return a project issue by id" do
      get api("/projects/#{project.id}/issues/#{issue.id}", user)
      expect(response.status).to eq(200)
      expect(json_response['title']).to eq(issue.title)
      expect(json_response['iid']).to eq(issue.iid)
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
  end

  describe "PUT /projects/:id/issues/:issue_id to update state and label" do
    it "should update a project issue" do
      put api("/projects/#{project.id}/issues/#{issue.id}", user),
        labels: 'label2', state_event: "close"
      expect(response.status).to eq(200)

      expect(json_response['labels']).to eq(['label2'])
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
