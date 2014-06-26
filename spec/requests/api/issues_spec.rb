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
        response.status.should == 401
      end
    end

    context "when authenticated" do
      it "should return an array of issues" do
        get api("/issues", user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.first['title'].should == issue.title
      end

      it "should add pagination headers" do
        get api("/issues?per_page=3", user)
        response.headers['Link'].should ==
          '<http://www.example.com/api/v3/issues?page=1&per_page=3>; rel="first", <http://www.example.com/api/v3/issues?page=1&per_page=3>; rel="last"'
      end
    end
  end

  describe "GET /projects/:id/issues" do
    it "should return project issues" do
      get api("/projects/#{project.id}/issues", user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.first['title'].should == issue.title
    end
  end

  describe "GET /projects/:id/issues/:issue_id" do
    it "should return a project issue by id" do
      get api("/projects/#{project.id}/issues/#{issue.id}", user)
      response.status.should == 200
      json_response['title'].should == issue.title
      json_response['iid'].should == issue.iid
    end

    it "should return 404 if issue id not found" do
      get api("/projects/#{project.id}/issues/54321", user)
      response.status.should == 404
    end
  end

  describe "POST /projects/:id/issues" do
    it "should create a new project issue" do
      post api("/projects/#{project.id}/issues", user),
        title: 'new issue', labels: 'label, label2'
      response.status.should == 201
      json_response['title'].should == 'new issue'
      json_response['description'].should be_nil
      json_response['labels'].should == ['label', 'label2']
    end

    it "should return a 400 bad request if title not given" do
      post api("/projects/#{project.id}/issues", user), labels: 'label, label2'
      response.status.should == 400
    end
  end

  describe "PUT /projects/:id/issues/:issue_id to update only title" do
    it "should update a project issue" do
      put api("/projects/#{project.id}/issues/#{issue.id}", user),
        title: 'updated title'
      response.status.should == 200

      json_response['title'].should == 'updated title'
    end

    it "should return 404 error if issue id not found" do
      put api("/projects/#{project.id}/issues/44444", user),
        title: 'updated title'
      response.status.should == 404
    end
  end

  describe "PUT /projects/:id/issues/:issue_id to update state and label" do
    it "should update a project issue" do
      put api("/projects/#{project.id}/issues/#{issue.id}", user),
        labels: 'label2', state_event: "close"
      response.status.should == 200

      json_response['labels'].should == ['label2']
      json_response['state'].should eq "closed"
    end
  end

  describe "DELETE /projects/:id/issues/:issue_id" do
    it "should delete a project issue" do
      delete api("/projects/#{project.id}/issues/#{issue.id}", user)
      response.status.should == 405
    end
  end
end
