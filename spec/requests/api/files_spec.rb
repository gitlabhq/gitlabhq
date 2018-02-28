require 'spec_helper'

describe API::Files do
  let(:user) { create(:user) }
  let!(:project) { create(:project, :repository, namespace: user.namespace ) }
  let(:guest) { create(:user) { |u| project.add_guest(u) } }
  let(:file_path) { "files%2Fruby%2Fpopen%2Erb" }
  let(:params) do
    {
      ref: 'master'
    }
  end
  let(:author_email) { 'user@example.org' }
  let(:author_name) { 'John Doe' }

  before do
    project.add_developer(user)
  end

  def route(file_path = nil)
    "/projects/#{project.id}/repository/files/#{file_path}"
  end

  describe "GET /projects/:id/repository/files/:file_path" do
    shared_examples_for 'repository files' do
      it 'returns file attributes as json' do
        get api(route(file_path), current_user), params

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['file_path']).to eq(CGI.unescape(file_path))
        expect(json_response['file_name']).to eq('popen.rb')
        expect(json_response['last_commit_id']).to eq('570e7b2abdd848b95f2f578043fc23bd6f6fd24d')
        expect(Base64.decode64(json_response['content']).lines.first).to eq("require 'fileutils'\n")
      end

      it 'returns json when file has txt extension' do
        file_path = "bar%2Fbranch-test.txt"

        get api(route(file_path), current_user), params

        expect(response).to have_gitlab_http_status(200)
        expect(response.content_type).to eq('application/json')
      end

      it 'returns file by commit sha' do
        # This file is deleted on HEAD
        file_path = "files%2Fjs%2Fcommit%2Ejs%2Ecoffee"
        params[:ref] = "6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9"

        get api(route(file_path), current_user), params

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['file_name']).to eq('commit.js.coffee')
        expect(Base64.decode64(json_response['content']).lines.first).to eq("class Commit\n")
      end

      it 'returns raw file info' do
        url = route(file_path) + "/raw"
        expect(Gitlab::Workhorse).to receive(:send_git_blob)

        get api(url, current_user), params

        expect(response).to have_gitlab_http_status(200)
      end

      context 'when mandatory params are not given' do
        it_behaves_like '400 response' do
          let(:request) { get api(route("any%2Ffile"), current_user) }
        end
      end

      context 'when file_path does not exist' do
        let(:params) { { ref: 'master' } }

        it_behaves_like '404 response' do
          let(:request) { get api(route('app%2Fmodels%2Fapplication%2Erb'), current_user), params }
          let(:message) { '404 File Not Found' }
        end
      end

      context 'when repository is disabled' do
        include_context 'disabled repository'

        it_behaves_like '403 response' do
          let(:request) { get api(route(file_path), current_user), params }
        end
      end
    end

    context 'when unauthenticated', 'and project is public' do
      it_behaves_like 'repository files' do
        let(:project) { create(:project, :public, :repository) }
        let(:current_user) { nil }
      end
    end

    context 'when unauthenticated', 'and project is private' do
      it_behaves_like '404 response' do
        let(:request) { get api(route(file_path)), params }
        let(:message) { '404 Project Not Found' }
      end
    end

    context 'when authenticated', 'as a developer' do
      it_behaves_like 'repository files' do
        let(:current_user) { user }
      end
    end

    context 'when authenticated', 'as a guest' do
      it_behaves_like '403 response' do
        let(:request) { get api(route(file_path), guest), params }
      end
    end
  end

  describe "GET /projects/:id/repository/files/:file_path/raw" do
    shared_examples_for 'repository raw files' do
      it 'returns raw file info' do
        url = route(file_path) + "/raw"
        expect(Gitlab::Workhorse).to receive(:send_git_blob)

        get api(url, current_user), params

        expect(response).to have_gitlab_http_status(200)
      end

      it 'returns raw file info for files with dots' do
        url = route('.gitignore') + "/raw"
        expect(Gitlab::Workhorse).to receive(:send_git_blob)

        get api(url, current_user), params

        expect(response).to have_gitlab_http_status(200)
      end

      it 'returns file by commit sha' do
        # This file is deleted on HEAD
        file_path = "files%2Fjs%2Fcommit%2Ejs%2Ecoffee"
        params[:ref] = "6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9"
        expect(Gitlab::Workhorse).to receive(:send_git_blob)

        get api(route(file_path) + "/raw", current_user), params

        expect(response).to have_gitlab_http_status(200)
      end

      context 'when mandatory params are not given' do
        it_behaves_like '400 response' do
          let(:request) { get api(route("any%2Ffile"), current_user) }
        end
      end

      context 'when file_path does not exist' do
        let(:params) { { ref: 'master' } }

        it_behaves_like '404 response' do
          let(:request) { get api(route('app%2Fmodels%2Fapplication%2Erb'), current_user), params }
          let(:message) { '404 File Not Found' }
        end
      end

      context 'when repository is disabled' do
        include_context 'disabled repository'

        it_behaves_like '403 response' do
          let(:request) { get api(route(file_path), current_user), params }
        end
      end
    end

    context 'when unauthenticated', 'and project is public' do
      it_behaves_like 'repository raw files' do
        let(:project) { create(:project, :public, :repository) }
        let(:current_user) { nil }
      end
    end

    context 'when unauthenticated', 'and project is private' do
      it_behaves_like '404 response' do
        let(:request) { get api(route(file_path)), params }
        let(:message) { '404 Project Not Found' }
      end
    end

    context 'when authenticated', 'as a developer' do
      it_behaves_like 'repository raw files' do
        let(:current_user) { user }
      end
    end

    context 'when authenticated', 'as a guest' do
      it_behaves_like '403 response' do
        let(:request) { get api(route(file_path), guest), params }
      end
    end
  end

  describe "POST /projects/:id/repository/files/:file_path" do
    let!(:file_path) { "new_subfolder%2Fnewfile%2Erb" }
    let(:valid_params) do
      {
        branch: "master",
        content: "puts 8",
        commit_message: "Added newfile"
      }
    end

    it "creates a new file in project repo" do
      post api(route(file_path), user), valid_params

      expect(response).to have_gitlab_http_status(201)
      expect(json_response["file_path"]).to eq(CGI.unescape(file_path))
      last_commit = project.repository.commit.raw
      expect(last_commit.author_email).to eq(user.email)
      expect(last_commit.author_name).to eq(user.name)
    end

    it "returns a 400 bad request if no mandatory params given" do
      post api(route("any%2Etxt"), user)

      expect(response).to have_gitlab_http_status(400)
    end

    it "returns a 400 if editor fails to create file" do
      allow_any_instance_of(Repository).to receive(:create_file)
        .and_raise(Gitlab::Git::CommitError, 'Cannot create file')

      post api(route("any%2Etxt"), user), valid_params

      expect(response).to have_gitlab_http_status(400)
    end

    context "when specifying an author" do
      it "creates a new file with the specified author" do
        valid_params.merge!(author_email: author_email, author_name: author_name)

        post api(route("new_file_with_author%2Etxt"), user), valid_params

        expect(response).to have_gitlab_http_status(201)
        expect(response.content_type).to eq('application/json')
        last_commit = project.repository.commit.raw
        expect(last_commit.author_email).to eq(author_email)
        expect(last_commit.author_name).to eq(author_name)
      end
    end

    context 'when the repo is empty' do
      let!(:project) { create(:project_empty_repo, namespace: user.namespace ) }

      it "creates a new file in project repo" do
        post api(route("newfile%2Erb"), user), valid_params

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['file_path']).to eq('newfile.rb')
        last_commit = project.repository.commit.raw
        expect(last_commit.author_email).to eq(user.email)
        expect(last_commit.author_name).to eq(user.name)
      end
    end
  end

  describe "PUT /projects/:id/repository/files" do
    let(:valid_params) do
      {
        branch: 'master',
        content: 'puts 8',
        commit_message: 'Changed file'
      }
    end

    it "updates existing file in project repo" do
      put api(route(file_path), user), valid_params

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['file_path']).to eq(CGI.unescape(file_path))
      last_commit = project.repository.commit.raw
      expect(last_commit.author_email).to eq(user.email)
      expect(last_commit.author_name).to eq(user.name)
    end

    it "returns a 400 bad request if update existing file with stale last commit id" do
      params_with_stale_id = valid_params.merge(last_commit_id: 'stale')

      put api(route(file_path), user), params_with_stale_id

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']).to eq('You are attempting to update a file that has changed since you started editing it.')
    end

    it "updates existing file in project repo with accepts correct last commit id" do
      last_commit = Gitlab::Git::Commit
                        .last_for_path(project.repository, 'master', URI.unescape(file_path))
      params_with_correct_id = valid_params.merge(last_commit_id: last_commit.id)

      put api(route(file_path), user), params_with_correct_id

      expect(response).to have_gitlab_http_status(200)
    end

    it "returns a 400 bad request if no params given" do
      put api(route(file_path), user)

      expect(response).to have_gitlab_http_status(400)
    end

    context "when specifying an author" do
      it "updates a file with the specified author" do
        valid_params.merge!(author_email: author_email, author_name: author_name, content: "New content")

        put api(route(file_path), user), valid_params

        expect(response).to have_gitlab_http_status(200)
        last_commit = project.repository.commit.raw
        expect(last_commit.author_email).to eq(author_email)
        expect(last_commit.author_name).to eq(author_name)
      end
    end
  end

  describe "DELETE /projects/:id/repository/files" do
    let(:valid_params) do
      {
        branch: 'master',
        commit_message: 'Changed file'
      }
    end

    it "deletes existing file in project repo" do
      delete api(route(file_path), user), valid_params

      expect(response).to have_gitlab_http_status(204)
    end

    it "returns a 400 bad request if no params given" do
      delete api(route(file_path), user)

      expect(response).to have_gitlab_http_status(400)
    end

    it "returns a 400 if fails to delete file" do
      allow_any_instance_of(Repository).to receive(:delete_file).and_raise(Gitlab::Git::CommitError, 'Cannot delete file')

      delete api(route(file_path), user), valid_params

      expect(response).to have_gitlab_http_status(400)
    end

    context "when specifying an author" do
      it "removes a file with the specified author" do
        valid_params.merge!(author_email: author_email, author_name: author_name)

        delete api(route(file_path), user), valid_params

        expect(response).to have_gitlab_http_status(204)
      end
    end
  end

  describe "POST /projects/:id/repository/files with binary file" do
    let(:file_path) { 'test%2Ebin' }
    let(:put_params) do
      {
        branch: 'master',
        content: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABAQMAAAAl21bKAAAAA1BMVEUAAACnej3aAAAAAXRSTlMAQObYZgAAAApJREFUCNdjYAAAAAIAAeIhvDMAAAAASUVORK5CYII=',
        commit_message: 'Binary file with a \n should not be touched',
        encoding: 'base64'
      }
    end
    let(:get_params) do
      {
        ref: 'master'
      }
    end

    before do
      post api(route(file_path), user), put_params
    end

    it "remains unchanged" do
      get api(route(file_path), user), get_params

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['file_path']).to eq(CGI.unescape(file_path))
      expect(json_response['file_name']).to eq(CGI.unescape(file_path))
      expect(json_response['content']).to eq(put_params[:content])
    end
  end
end
