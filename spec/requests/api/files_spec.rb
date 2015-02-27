require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
  let!(:project) { create(:project, namespace: user.namespace ) }
  let(:file_path) { 'files/ruby/popen.rb' }

  before { project.team << [user, :developer] }

  describe "GET /projects/:id/repository/files" do
    it "should return file info" do
      params = {
        file_path: file_path,
        ref: 'master',
      }

      get api("/projects/#{project.id}/repository/files", user), params
      expect(response.status).to eq(200)
      expect(json_response['file_path']).to eq(file_path)
      expect(json_response['file_name']).to eq('popen.rb')
      expect(Base64.decode64(json_response['content']).lines.first).to eq("require 'fileutils'\n")
    end

    it "should return a 400 bad request if no params given" do
      get api("/projects/#{project.id}/repository/files", user)
      expect(response.status).to eq(400)
    end

    it "should return a 404 if such file does not exist" do
      params = {
        file_path: 'app/models/application.rb',
        ref: 'master',
      }

      get api("/projects/#{project.id}/repository/files", user), params
      expect(response.status).to eq(404)
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
      expect(response.status).to eq(201)
      expect(json_response['file_path']).to eq('newfile.rb')
    end

    it "should return a 400 bad request if no params given" do
      post api("/projects/#{project.id}/repository/files", user)
      expect(response.status).to eq(400)
    end

    it "should return a 400 if satellite fails to create file" do
      Gitlab::Satellite::NewFileAction.any_instance.stub(
        commit!: false,
      )

      post api("/projects/#{project.id}/repository/files", user), valid_params
      expect(response.status).to eq(400)
    end
  end

  describe "PUT /projects/:id/repository/files" do
    let(:valid_params) {
      {
        file_path: file_path,
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
      expect(response.status).to eq(200)
      expect(json_response['file_path']).to eq(file_path)
    end

    it "should return a 400 bad request if no params given" do
      put api("/projects/#{project.id}/repository/files", user)
      expect(response.status).to eq(400)
    end

    it 'should return a 400 if the checkout fails' do
      Gitlab::Satellite::EditFileAction.any_instance.stub(:commit!)
        .and_raise(Gitlab::Satellite::CheckoutFailed)

      put api("/projects/#{project.id}/repository/files", user), valid_params
      expect(response.status).to eq(400)

      ref = valid_params[:branch_name]
      expect(response.body).to match("ref '#{ref}' could not be checked out")
    end

    it 'should return a 409 if the file was not modified' do
      Gitlab::Satellite::EditFileAction.any_instance.stub(:commit!)
        .and_raise(Gitlab::Satellite::CommitFailed)

      put api("/projects/#{project.id}/repository/files", user), valid_params
      expect(response.status).to eq(409)
      expect(response.body).to match("Maybe there was nothing to commit?")
    end

    it 'should return a 409 if the push fails' do
      Gitlab::Satellite::EditFileAction.any_instance.stub(:commit!)
        .and_raise(Gitlab::Satellite::PushFailed)

      put api("/projects/#{project.id}/repository/files", user), valid_params
      expect(response.status).to eq(409)
      expect(response.body).to match("Maybe the file was changed by another process?")
    end
  end

  describe "DELETE /projects/:id/repository/files" do
    let(:valid_params) {
      {
        file_path: file_path,
        branch_name: 'master',
        commit_message: 'Changed file'
      }
    }

    it "should delete existing file in project repo" do
      Gitlab::Satellite::DeleteFileAction.any_instance.stub(
        commit!: true,
      )

      delete api("/projects/#{project.id}/repository/files", user), valid_params
      expect(response.status).to eq(200)
      expect(json_response['file_path']).to eq(file_path)
    end

    it "should return a 400 bad request if no params given" do
      delete api("/projects/#{project.id}/repository/files", user)
      expect(response.status).to eq(400)
    end

    it "should return a 400 if satellite fails to create file" do
      Gitlab::Satellite::DeleteFileAction.any_instance.stub(
        commit!: false,
      )

      delete api("/projects/#{project.id}/repository/files", user), valid_params
      expect(response.status).to eq(400)
    end
  end
end
