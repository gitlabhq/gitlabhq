require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
  let!(:project) { create(:project, namespace: user.namespace ) }
  let!(:milestone) { create(:milestone, project: project) }

  before { project.team << [user, :developer] }

  describe "GET /projects/:id/milestones" do
    it "should return project milestones" do
      get api("/projects/#{project.id}/milestones", user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.first['title'].should == milestone.title
    end

    it "should return a 401 error if user not authenticated" do
      get api("/projects/#{project.id}/milestones")
      response.status.should == 401
    end
  end

  describe "GET /projects/:id/milestones/:milestone_id" do
    it "should return a project milestone by id" do
      get api("/projects/#{project.id}/milestones/#{milestone.id}", user)
      response.status.should == 200
      json_response['title'].should == milestone.title
      json_response['iid'].should == milestone.iid
    end

    it "should return 401 error if user not authenticated" do
      get api("/projects/#{project.id}/milestones/#{milestone.id}")
      response.status.should == 401
    end

    it "should return a 404 error if milestone id not found" do
      get api("/projects/#{project.id}/milestones/1234", user)
      response.status.should == 404
    end
  end

  describe "POST /projects/:id/milestones" do
    it "should create a new project milestone" do
      post api("/projects/#{project.id}/milestones", user), title: 'new milestone'
      response.status.should == 201
      json_response['title'].should == 'new milestone'
      json_response['description'].should be_nil
    end

    it "should create a new project milestone with description and due date" do
      post api("/projects/#{project.id}/milestones", user),
        title: 'new milestone', description: 'release', due_date: '2013-03-02'
      response.status.should == 201
      json_response['description'].should == 'release'
      json_response['due_date'].should == '2013-03-02'
    end

    it "should return a 400 error if title is missing" do
      post api("/projects/#{project.id}/milestones", user)
      response.status.should == 400
    end
  end

  describe "PUT /projects/:id/milestones/:milestone_id" do
    it "should update a project milestone" do
      put api("/projects/#{project.id}/milestones/#{milestone.id}", user),
        title: 'updated title'
      response.status.should == 200
      json_response['title'].should == 'updated title'
    end

    it "should return a 404 error if milestone id not found" do
      put api("/projects/#{project.id}/milestones/1234", user),
        title: 'updated title'
      response.status.should == 404
    end
  end

  describe "PUT /projects/:id/milestones/:milestone_id to close milestone" do
    it "should update a project milestone" do
      put api("/projects/#{project.id}/milestones/#{milestone.id}", user),
        state_event: 'close'
      response.status.should == 200

      json_response['state'].should == 'closed'
    end
  end

  describe "PUT /projects/:id/milestones/:milestone_id to test observer on close" do
    it "should create an activity event when an milestone is closed" do
      Event.should_receive(:create)

      put api("/projects/#{project.id}/milestones/#{milestone.id}", user),
          state_event: 'close'
    end
  end
end
