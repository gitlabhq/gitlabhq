require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
  let!(:project) { create(:project, namespace: user.namespace ) }
  let(:file_path) { 'files/ruby/popen.rb' }
  let(:author_email) { FFaker::Internet.email }

  # I have to remove periods from the end of the name
  # This happened when the user's name had a suffix (i.e. "Sr.")
  # This seems to be what git does under the hood. For example, this commit:
  #
  # $ git commit --author='Foo Sr. <foo@example.com>' -m 'Where's my trailing period?'
  #
  # results in this:
  #
  # $ git show --pretty
  # ...
  # Author: Foo Sr <foo@example.com>
  # ...
  let(:author_name) { FFaker::Name.name.chomp("\.") }

  before { project.team << [user, :developer] }

  describe "GET /projects/:id/repository/files" do
    it "returns file info" do
      params = {
        file_path: file_path,
        ref: 'master',
      }

      get api("/projects/#{project.id}/repository/files", user), params

      expect(response).to have_http_status(200)
      expect(json_response['file_path']).to eq(file_path)
      expect(json_response['file_name']).to eq('popen.rb')
      expect(json_response['last_commit_id']).to eq('570e7b2abdd848b95f2f578043fc23bd6f6fd24d')
      expect(Base64.decode64(json_response['content']).lines.first).to eq("require 'fileutils'\n")
    end

    it "returns a 400 bad request if no params given" do
      get api("/projects/#{project.id}/repository/files", user)

      expect(response).to have_http_status(400)
    end

    it "returns a 404 if such file does not exist" do
      params = {
        file_path: 'app/models/application.rb',
        ref: 'master',
      }

      get api("/projects/#{project.id}/repository/files", user), params

      expect(response).to have_http_status(404)
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

    it "creates a new file in project repo" do
      post api("/projects/#{project.id}/repository/files", user), valid_params

      expect(response).to have_http_status(201)
      expect(json_response['file_path']).to eq('newfile.rb')
      last_commit = project.repository.commit.raw
      expect(last_commit.author_email).to eq(user.email)
      expect(last_commit.author_name).to eq(user.name)
    end

    it "returns a 400 bad request if no params given" do
      post api("/projects/#{project.id}/repository/files", user)

      expect(response).to have_http_status(400)
    end

    it "returns a 400 if editor fails to create file" do
      allow_any_instance_of(Repository).to receive(:commit_file).
        and_return(false)

      post api("/projects/#{project.id}/repository/files", user), valid_params

      expect(response).to have_http_status(400)
    end

    context "when specifying an author" do
      it "creates a new file with the specified author" do
        valid_params.merge!(author_email: author_email, author_name: author_name)

        post api("/projects/#{project.id}/repository/files", user), valid_params

        expect(response).to have_http_status(201)
        last_commit = project.repository.commit.raw
        expect(last_commit.author_email).to eq(author_email)
        expect(last_commit.author_name).to eq(author_name)
      end
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

    it "updates existing file in project repo" do
      put api("/projects/#{project.id}/repository/files", user), valid_params

      expect(response).to have_http_status(200)
      expect(json_response['file_path']).to eq(file_path)
      last_commit = project.repository.commit.raw
      expect(last_commit.author_email).to eq(user.email)
      expect(last_commit.author_name).to eq(user.name)
    end

    it "returns a 400 bad request if no params given" do
      put api("/projects/#{project.id}/repository/files", user)

      expect(response).to have_http_status(400)
    end

    context "when specifying an author" do
      it "updates a file with the specified author" do
        valid_params.merge!(author_email: author_email, author_name: author_name, content: "New content")

        put api("/projects/#{project.id}/repository/files", user), valid_params

        expect(response).to have_http_status(200)
        last_commit = project.repository.commit.raw
        expect(last_commit.author_email).to eq(author_email)
        expect(last_commit.author_name).to eq(author_name)
      end
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

    it "deletes existing file in project repo" do
      delete api("/projects/#{project.id}/repository/files", user), valid_params

      expect(response).to have_http_status(200)
      expect(json_response['file_path']).to eq(file_path)
      last_commit = project.repository.commit.raw
      expect(last_commit.author_email).to eq(user.email)
      expect(last_commit.author_name).to eq(user.name)
    end

    it "returns a 400 bad request if no params given" do
      delete api("/projects/#{project.id}/repository/files", user)

      expect(response).to have_http_status(400)
    end

    it "returns a 400 if fails to create file" do
      allow_any_instance_of(Repository).to receive(:remove_file).and_return(false)

      delete api("/projects/#{project.id}/repository/files", user), valid_params

      expect(response).to have_http_status(400)
    end

    context "when specifying an author" do
      it "removes a file with the specified author" do
        valid_params.merge!(author_email: author_email, author_name: author_name)

        delete api("/projects/#{project.id}/repository/files", user), valid_params

        expect(response).to have_http_status(200)
        last_commit = project.repository.commit.raw
        expect(last_commit.author_email).to eq(author_email)
        expect(last_commit.author_name).to eq(author_name)
      end
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

      expect(response).to have_http_status(200)
      expect(json_response['file_path']).to eq(file_path)
      expect(json_response['file_name']).to eq(file_path)
      expect(json_response['content']).to eq(put_params[:content])
    end
  end
end
