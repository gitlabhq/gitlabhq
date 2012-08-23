require 'spec_helper'

describe Gitlab::API do
  let(:user) { Factory :user }
  let!(:project) { Factory :project, owner: user }
  let!(:snippet) { Factory :snippet, author: user, project: project, title: 'example' }
  before { project.add_access(user, :read) }

  describe "GET /projects" do
    it "should return authentication error" do
      get "#{api_prefix}/projects"
      response.status.should == 401
    end

    describe "authenticated GET /projects" do
      it "should return an array of projects" do
        get "#{api_prefix}/projects?private_token=#{user.private_token}"
        response.status.should == 200
        json_response.should be_an Array
        json_response.first['name'].should == project.name
        json_response.first['owner']['email'].should == user.email
      end
    end
  end

  describe "GET /projects/:id" do
    it "should return a project by id" do
      get "#{api_prefix}/projects/#{project.id}?private_token=#{user.private_token}"
      response.status.should == 200
      json_response['name'].should == project.name
      json_response['owner']['email'].should == user.email
    end

    it "should return a project by code name" do
      get "#{api_prefix}/projects/#{project.code}?private_token=#{user.private_token}"
      response.status.should == 200
      json_response['name'].should == project.name
    end

    it "should return a 404 error if not found" do
      get "#{api_prefix}/projects/42?private_token=#{user.private_token}"
      response.status.should == 404
      json_response['message'].should == '404 Not found'
    end
  end

  describe "GET /projects/:id/repository/branches" do
    it "should return an array of project branches" do
      get "#{api_prefix}/projects/#{project.code}/repository/branches?private_token=#{user.private_token}"
      response.status.should == 200
      json_response.should be_an Array
      json_response.first['name'].should == project.repo.heads.sort_by(&:name).first.name
    end
  end

  describe "GET /projects/:id/repository/branches/:branch" do
    it "should return the branch information for a single branch" do
      get "#{api_prefix}/projects/#{project.code}/repository/branches/new_design?private_token=#{user.private_token}"
      response.status.should == 200

      json_response['name'].should == 'new_design'
      json_response['commit']['id'].should == '621491c677087aa243f165eab467bfdfbee00be1'
    end
  end

  describe "GET /projects/:id/repository/tags" do
    it "should return an array of project tags" do
      get "#{api_prefix}/projects/#{project.code}/repository/tags?private_token=#{user.private_token}"
      response.status.should == 200
      json_response.should be_an Array
      json_response.first['name'].should == project.repo.tags.sort_by(&:name).reverse.first.name
    end
  end

  describe "GET /projects/:id/snippets/:snippet_id" do
    it "should return a project snippet" do
      get "#{api_prefix}/projects/#{project.code}/snippets/#{snippet.id}?private_token=#{user.private_token}"
      response.status.should == 200
      json_response['title'].should == snippet.title
    end
  end

  describe "POST /projects/:id/snippets" do
    it "should create a new project snippet" do
      post "#{api_prefix}/projects/#{project.code}/snippets?private_token=#{user.private_token}",
        title: 'api test', file_name: 'sample.rb', code: 'test'
      response.status.should == 201
      json_response['title'].should == 'api test'
    end
  end

  describe "PUT /projects/:id/snippets" do
    it "should update an existing project snippet" do
      put "#{api_prefix}/projects/#{project.code}/snippets/#{snippet.id}?private_token=#{user.private_token}",
        code: 'updated code'
      response.status.should == 200
      json_response['title'].should == 'example'
      snippet.reload.content.should == 'updated code'
    end
  end

  describe "DELETE /projects/:id/snippets/:snippet_id" do
    it "should delete existing project snippet" do
      expect {
        delete "#{api_prefix}/projects/#{project.code}/snippets/#{snippet.id}?private_token=#{user.private_token}"
      }.to change { Snippet.count }.by(-1)
    end
  end

  describe "GET /projects/:id/snippets/:snippet_id/raw" do
    it "should get a raw project snippet" do
      get "#{api_prefix}/projects/#{project.code}/snippets/#{snippet.id}/raw?private_token=#{user.private_token}"
      response.status.should == 200
    end
  end

  describe "GET /projects/:id/:sha/blob" do
    it "should get the raw file contents" do
      get "#{api_prefix}/projects/#{project.code}/repository/commits/master/blob?filepath=README.md&private_token=#{user.private_token}"
      
      response.status.should == 200
    end

    it "should return 404 for invalid branch_name" do
      get "#{api_prefix}/projects/#{project.code}/repository/commits/invalid_branch_name/blob?filepath=README.md&private_token=#{user.private_token}"
      
      response.status.should == 404
    end

    it "should return 404 for invalid file" do
      get "#{api_prefix}/projects/#{project.code}/repository/commits/master/blob?filepath=README.invalid&private_token=#{user.private_token}"
      
      response.status.should == 404
    end
  end
end
