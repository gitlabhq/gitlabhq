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
    let(:valid_params) do
      {
        file_path: 'newfile.rb',
        branch_name: 'master',
        content: 'puts 8',
        commit_message: 'Added newfile'
      }
    end

    it "should create a new file in project repo" do
      expect_any_instance_of(Gitlab::Satellite::NewFileAction).to receive(:commit!).and_return(true)

      post api("/projects/#{project.id}/repository/files", user), valid_params
      expect(response.status).to eq(201)
      expect(json_response['file_path']).to eq('newfile.rb')
    end

    it "should return a 400 bad request if no params given" do
      post api("/projects/#{project.id}/repository/files", user)
      expect(response.status).to eq(400)
    end

    it "should return a 400 if satellite fails to create file" do
      expect_any_instance_of(Gitlab::Satellite::NewFileAction).to receive(:commit!).and_return(false)

      post api("/projects/#{project.id}/repository/files", user), valid_params
      expect(response.status).to eq(400)
    end
  end

  describe "PUT /projects/:id/repository/files" do
    let(:valid_params) do
      {
        file_path: file_path,
        branch_name: 'master',
        content: 'puts 8',
        commit_message: 'Changed file'
      }
    end

    it "should update existing file in project repo" do
      expect_any_instance_of(Gitlab::Satellite::EditFileAction).to receive(:commit!).and_return(true)

      put api("/projects/#{project.id}/repository/files", user), valid_params
      expect(response.status).to eq(200)
      expect(json_response['file_path']).to eq(file_path)
    end

    it "should return a 400 bad request if no params given" do
      put api("/projects/#{project.id}/repository/files", user)
      expect(response.status).to eq(400)
    end

    it 'should return a 400 if the checkout fails' do
      expect_any_instance_of(Gitlab::Satellite::EditFileAction).to receive(:commit!).and_raise(Gitlab::Satellite::CheckoutFailed)

      put api("/projects/#{project.id}/repository/files", user), valid_params
      expect(response.status).to eq(400)

      ref = valid_params[:branch_name]
      expect(response.body).to match("ref '#{ref}' could not be checked out")
    end

    it 'should return a 409 if the file was not modified' do
      expect_any_instance_of(Gitlab::Satellite::EditFileAction).to receive(:commit!).and_raise(Gitlab::Satellite::CommitFailed)

      put api("/projects/#{project.id}/repository/files", user), valid_params
      expect(response.status).to eq(409)
      expect(response.body).to match("Maybe there was nothing to commit?")
    end

    it 'should return a 409 if the push fails' do
      expect_any_instance_of(Gitlab::Satellite::EditFileAction).to receive(:commit!).and_raise(Gitlab::Satellite::PushFailed)

      put api("/projects/#{project.id}/repository/files", user), valid_params
      expect(response.status).to eq(409)
      expect(response.body).to match("Maybe the file was changed by another process?")
    end
  end

  describe "DELETE /projects/:id/repository/files" do
    let(:valid_params) do
      {
        file_path: file_path,
        branch_name: 'master',
        commit_message: 'Changed file'
      }
    end

    it "should delete existing file in project repo" do
      expect_any_instance_of(Gitlab::Satellite::DeleteFileAction).to receive(:commit!).and_return(true)
      delete api("/projects/#{project.id}/repository/files", user), valid_params
      expect(response.status).to eq(200)
      expect(json_response['file_path']).to eq(file_path)
    end

    it "should return a 400 bad request if no params given" do
      delete api("/projects/#{project.id}/repository/files", user)
      expect(response.status).to eq(400)
    end

    it "should return a 400 if satellite fails to create file" do
      expect_any_instance_of(Gitlab::Satellite::DeleteFileAction).to receive(:commit!).and_return(false)

      delete api("/projects/#{project.id}/repository/files", user), valid_params
      expect(response.status).to eq(400)
    end
  end

  describe "POST /projects/:id/repository/files with binary file" do
    let(:file_path) { 'test.bin' }
    let(:put_params) do
      {
        file_path: file_path,
        branch_name: 'master',
        content: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABAQMAAAAl21bKAAAAA1BMVEUAAACnej3aAAAAAXRSTlMAQObYZgAAAApJREFUCNdjYAAAAAIAAeIhvDMAAAAASUVORK5CYII=',
        commit_message: 'Binary file with a \n should not be touched',
        encoding: 'base64'
      }
    end
    let(:get_params) do
      {
        file_path: file_path,
        ref: 'master',
      }
    end

    before do
      post api("/projects/#{project.id}/repository/files", user), put_params
    end

    it "remains unchanged" do
      get api("/projects/#{project.id}/repository/files", user), get_params
      expect(response.status).to eq(200)
      expect(json_response['file_path']).to eq(file_path)
      expect(json_response['file_name']).to eq(file_path)
      expect(json_response['content']).to eq(put_params[:content])
    end
  end
end
