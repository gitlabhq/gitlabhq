require 'spec_helper'

describe Gitlab::API do
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
  end

  describe "GET /projects/:id/milestones/:milestone_id" do
    it "should return a project milestone by id" do
      get api("/projects/#{project.id}/milestones/#{milestone.id}", user)
      response.status.should == 200
      json_response['title'].should == milestone.title
    end
  end

  describe "POST /projects/:id/milestones" do
    it "should create a new project milestone" do
      post api("/projects/#{project.id}/milestones", user),
        title: 'new milestone'
      response.status.should == 201
      json_response['title'].should == 'new milestone'
      json_response['description'].should be_nil
    end
  end

  describe "PUT /projects/:id/milestones/:milestone_id" do
    it "should update a project milestone" do
      put api("/projects/#{project.id}/milestones/#{milestone.id}", user),
        title: 'updated title'
      response.status.should == 200
      json_response['title'].should == 'updated title'
    end
  end
end
