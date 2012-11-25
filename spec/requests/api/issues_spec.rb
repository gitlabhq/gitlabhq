require 'spec_helper'

describe Gitlab::API do
  include ApiHelpers

  let(:user) { create(:user) }
  let!(:project) { create(:project, owner: user) }
  let!(:issue) { create(:issue, author: user, assignee: user, project: project) }
  before { project.add_access(user, :read) }

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
    end
  end

  describe "GET /projects/:id/issues" do
    it "should return project issues" do
      get api("/projects/#{project.path}/issues", user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.first['title'].should == issue.title
    end
  end

  describe "GET /projects/:id/issues/:issue_id" do
    it "should return a project issue by id" do
      get api("/projects/#{project.path}/issues/#{issue.id}", user)
      response.status.should == 200
      json_response['title'].should == issue.title
    end
  end

  describe "POST /projects/:id/issues" do
    it "should create a new project issue" do
      post api("/projects/#{project.path}/issues", user),
        title: 'new issue', labels: 'label, label2'
      response.status.should == 201
      json_response['title'].should == 'new issue'
      json_response['description'].should be_nil
      json_response['labels'].should == ['label', 'label2']
    end
  end

  describe "PUT /projects/:id/issues/:issue_id" do
    it "should update a project issue" do
      put api("/projects/#{project.path}/issues/#{issue.id}", user),
        title: 'updated title', labels: 'label2', closed: 1
      response.status.should == 200
      json_response['title'].should == 'updated title'
      json_response['labels'].should == ['label2']
      json_response['closed'].should be_true
    end
  end

  describe "DELETE /projects/:id/issues/:issue_id" do
    it "should delete a project issue" do
      delete api("/projects/#{project.path}/issues/#{issue.id}", user)
      response.status.should == 405
    end
  end
end
