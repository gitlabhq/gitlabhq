require 'spec_helper'

describe API::API do
  include ApiHelpers
  before(:each) { ActiveRecord::Base.observers.enable(:user_observer) }
  after(:each) { ActiveRecord::Base.observers.disable(:user_observer) }

  let(:user) { create(:user) }
  let!(:project) { create(:project, namespace: user.namespace ) }
  before { project.team << [user, :developer] }

  describe "GET /projects/:id/repository/files" do
    it "should return file info" do
      params = {
        file_path: 'app/models/key.rb',
        ref: 'master',
      }

      get api("/projects/#{project.id}/repository/files", user), params
      response.status.should == 200
      json_response['file_path'].should == 'app/models/key.rb'
      json_response['file_name'].should == 'key.rb'
      Base64.decode64(json_response['content']).lines.first.should == "class Key < ActiveRecord::Base\n"
    end

    it "should return a 400 bad request if no params given" do
      get api("/projects/#{project.id}/repository/files", user)
      response.status.should == 400
    end

    it "should return a 404 if such file does not exist" do
      params = {
        file_path: 'app/models/application.rb',
        ref: 'master',
      }

      get api("/projects/#{project.id}/repository/files", user), params
      response.status.should == 404
    end
  end

  describe "POST /projects/:id/repository/files" do
    let(:valid_params) {
      {
        file_path: 'newfile.rb',
        branch_name: 'master',
        content: 'puts 8',
        commit_message: 'Added newfile'
      }
    }

    it "should create a new file in project repo" do
      Gitlab::Satellite::NewFileAction.any_instance.stub(
        commit!: true,
      )

      post api("/projects/#{project.id}/repository/files", user), valid_params
      response.status.should == 201
      json_response['file_path'].should == 'newfile.rb'
    end

    it "should return a 400 bad request if no params given" do
      post api("/projects/#{project.id}/repository/files", user)
      response.status.should == 400
    end

    it "should return a 400 if satellite fails to create file" do
      Gitlab::Satellite::NewFileAction.any_instance.stub(
        commit!: false,
      )

      post api("/projects/#{project.id}/repository/files", user), valid_params
      response.status.should == 400
    end
  end

  describe "PUT /projects/:id/repository/files" do
    let(:valid_params) {
      {
        file_path: 'spec/spec_helper.rb',
        branch_name: 'master',
        content: 'puts 8',
        commit_message: 'Changed file'
      }
    }

    it "should update existing file in project repo" do
      Gitlab::Satellite::EditFileAction.any_instance.stub(
        commit!: true,
      )

      put api("/projects/#{project.id}/repository/files", user), valid_params
      response.status.should == 200
      json_response['file_path'].should == 'spec/spec_helper.rb'
    end

    it "should return a 400 bad request if no params given" do
      put api("/projects/#{project.id}/repository/files", user)
      response.status.should == 400
    end

    it "should return a 400 if satellite fails to create file" do
      Gitlab::Satellite::EditFileAction.any_instance.stub(
        commit!: false,
      )

      put api("/projects/#{project.id}/repository/files", user), valid_params
      response.status.should == 400
    end
  end

  describe "DELETE /projects/:id/repository/files" do
    let(:valid_params) {
      {
        file_path: 'spec/spec_helper.rb',
        branch_name: 'master',
        commit_message: 'Changed file'
      }
    }

    it "should delete existing file in project repo" do
      Gitlab::Satellite::DeleteFileAction.any_instance.stub(
        commit!: true,
      )

      delete api("/projects/#{project.id}/repository/files", user), valid_params
      response.status.should == 200
      json_response['file_path'].should == 'spec/spec_helper.rb'
    end

    it "should return a 400 bad request if no params given" do
      delete api("/projects/#{project.id}/repository/files", user)
      response.status.should == 400
    end

    it "should return a 400 if satellite fails to create file" do
      Gitlab::Satellite::DeleteFileAction.any_instance.stub(
        commit!: false,
      )

      delete api("/projects/#{project.id}/repository/files", user), valid_params
      response.status.should == 400
    end
  end
end
