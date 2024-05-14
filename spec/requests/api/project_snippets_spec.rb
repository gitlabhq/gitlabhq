# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectSnippets, :aggregate_failures, feature_category: :source_code_management do
  include SnippetHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:project_no_snippets) { create(:project, :snippets_disabled) }
  let_it_be(:user) { create(:user, developer_of: project_no_snippets) }
  let_it_be(:admin) { create(:admin, developer_of: project_no_snippets) }
  let_it_be(:public_snippet, reload: true) { create(:project_snippet, :public, :repository, project: project) }

  describe "GET /projects/:project_id/snippets/:id/user_agent_detail" do
    let_it_be(:user_agent_detail) { create(:user_agent_detail, subject: public_snippet) }

    it_behaves_like 'GET request permissions for admin mode' do
      let(:path) { "/projects/#{public_snippet.project.id}/snippets/#{public_snippet.id}/user_agent_detail" }
    end

    it 'exposes known attributes' do
      get api("/projects/#{project.id}/snippets/#{public_snippet.id}/user_agent_detail", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['user_agent']).to eq(user_agent_detail.user_agent)
      expect(json_response['ip_address']).to eq(user_agent_detail.ip_address)
      expect(json_response['akismet_submitted']).to eq(user_agent_detail.submitted)
    end

    it 'respects project scoping' do
      other_project = create(:project)

      get api("/projects/#{other_project.id}/snippets/#{public_snippet.id}/user_agent_detail", admin, admin_mode: true)
      expect(response).to have_gitlab_http_status(:not_found)
    end

    it "returns unauthorized for non-admin users" do
      get api("/projects/#{public_snippet.project.id}/snippets/#{public_snippet.id}/user_agent_detail", user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    context 'with snippets disabled' do
      it_behaves_like '403 response' do
        subject(:request) { get api("/projects/#{project_no_snippets.id}/snippets/#{non_existing_record_id}/user_agent_detail", admin, admin_mode: true) }
      end
    end
  end

  describe 'GET /projects/:project_id/snippets/' do
    it 'returns all snippets available to team member' do
      project.add_developer(user)

      internal_snippet = create(:project_snippet, :internal, project: project)
      private_snippet = create(:project_snippet, :private, project: project)

      get api("/projects/#{project.id}/snippets", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.map { |snippet| snippet['id'] }).to contain_exactly(public_snippet.id, internal_snippet.id, private_snippet.id)
      expect(json_response.last).to have_key('web_url')
    end

    it 'hides private snippets from regular user' do
      create(:project_snippet, :private, project: project)

      get api("/projects/#{project.id}/snippets/", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.map { |snippet| snippet['id'] }).to contain_exactly(public_snippet.id)
    end

    context 'with snippets disabled' do
      it_behaves_like '403 response' do
        subject(:request) { get api("/projects/#{project_no_snippets.id}/snippets", user) }
      end
    end
  end

  describe 'GET /projects/:project_id/snippets/:id' do
    let(:snippet) { public_snippet }

    it 'returns snippet json' do
      get api("/projects/#{project.id}/snippets/#{snippet.id}", user)

      expect(response).to have_gitlab_http_status(:ok)

      expect(json_response['title']).to eq(snippet.title)
      expect(json_response['description']).to eq(snippet.description)
      expect(json_response['file_name']).to eq(snippet.file_name_on_repo)
      expect(json_response['files']).to eq(snippet.blobs.map { |blob| snippet_blob_file(blob) })
      expect(json_response['ssh_url_to_repo']).to eq(snippet.ssh_url_to_repo)
      expect(json_response['http_url_to_repo']).to eq(snippet.http_url_to_repo)
    end

    it 'returns 404 for invalid snippet id' do
      get api("/projects/#{project.id}/snippets/#{non_existing_record_id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Not found')
    end

    context 'with snippets disabled' do
      it_behaves_like '403 response' do
        subject(:request) { get api("/projects/#{project_no_snippets.id}/snippets/#{non_existing_record_id}", user) }
      end
    end

    it_behaves_like 'project snippet access levels' do
      let(:path) { "/projects/#{snippet.project.id}/snippets/#{snippet.id}" }
    end
  end

  describe 'POST /projects/:project_id/snippets/' do
    let(:base_params) do
      {
        title: 'Test Title',
        description: 'test description',
        visibility: 'public'
      }
    end

    let(:file_path) { 'file_1.rb' }
    let(:file_content) { 'puts "hello world"' }
    let(:file_params) { { files: [{ file_path: file_path, content: file_content }] } }
    let(:params) { base_params.merge(file_params) }
    let(:admin_mode) { false }

    subject(:request) { post api("/projects/#{project.id}/snippets/", actor, admin_mode: admin_mode), params: params }

    it_behaves_like 'POST request permissions for admin mode' do
      let(:path) { "/projects/#{project.id}/snippets/" }
    end

    shared_examples 'project snippet repository actions' do
      let(:snippet) { ProjectSnippet.find(json_response['id']) }

      it 'commit the files to the repository' do
        request

        expect(snippet.repository.exists?).to be_truthy

        blob = snippet.repository.blob_at(snippet.default_branch, file_path)

        expect(blob.data).to eq file_content
      end
    end

    context 'with an external user' do
      let(:actor) { create(:user, :external) }

      context 'that belongs to the project' do
        it 'creates a new snippet' do
          project.add_developer(actor)

          request

          expect(response).to have_gitlab_http_status(:created)
        end
      end

      context 'that does not belong to the project' do
        it 'does not create a new snippet' do
          request

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'with a regular user' do
      let(:actor) { user }

      before_all do
        project.add_developer(user)
      end

      before do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC, Gitlab::VisibilityLevel::PRIVATE])
        params['visibility'] = 'internal'
      end

      it 'creates a new snippet' do
        request

        expect(response).to have_gitlab_http_status(:created)
        snippet = ProjectSnippet.find(json_response['id'])
        expect(snippet.content).to eq(file_content)
        expect(snippet.description).to eq(params[:description])
        expect(snippet.title).to eq(params[:title])
        expect(snippet.file_name).to eq(file_path)
        expect(snippet.visibility_level).to eq(Snippet::INTERNAL)
      end

      it_behaves_like 'project snippet repository actions'
    end

    context 'with an admin' do
      let(:actor) { admin }
      let(:admin_mode) { true }

      it 'creates a new snippet' do
        request

        expect(response).to have_gitlab_http_status(:created)
        snippet = ProjectSnippet.find(json_response['id'])
        expect(snippet.content).to eq(file_content)
        expect(snippet.description).to eq(params[:description])
        expect(snippet.title).to eq(params[:title])
        expect(snippet.file_name).to eq(file_path)
        expect(snippet.visibility_level).to eq(Snippet::PUBLIC)
      end

      it_behaves_like 'project snippet repository actions'

      it 'returns 400 for missing parameters' do
        params.delete(:title)

        request

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it_behaves_like 'snippet creation with files parameter'

      it_behaves_like 'snippet creation without files parameter'

      it 'returns 400 if title is blank' do
        params[:title] = ''

        request

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq 'title is empty'
      end
    end

    context 'when save fails because the repository could not be created' do
      let(:actor) { admin }
      let(:admin_mode) { true }

      before do
        allow_next_instance_of(Snippets::CreateService) do |instance|
          allow(instance).to receive(:create_repository).and_raise(Snippets::CreateService::CreateRepositoryError)
        end
      end

      it 'returns 400' do
        request

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when the snippet is spam' do
      let(:actor) { user }

      before do
        allow_next_instance_of(Spam::AkismetService) do |instance|
          allow(instance).to receive(:spam?).and_return(true)
        end

        project.add_developer(user)
      end

      context 'when the snippet is private' do
        it 'creates the snippet' do
          params['visibility'] = 'private'

          expect { request }.to change { Snippet.count }.by(1)
        end
      end

      context 'when the snippet is public' do
        before do
          params['visibility'] = 'public'
        end

        it 'rejects the snippet' do
          expect { request }.not_to change { Snippet.count }
          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']['error']).to match(/snippet has been recognized as spam/)
        end

        it 'creates a spam log' do
          expect { request }
            .to log_spam(title: 'Test Title', user_id: user.id, noteable_type: 'ProjectSnippet')
        end
      end
    end

    context 'with snippets disabled' do
      it_behaves_like '403 response' do
        subject(:request) { post api("/projects/#{project_no_snippets.id}/snippets", user), params: params }
      end
    end
  end

  describe 'PUT /projects/:project_id/snippets/:id/' do
    let(:visibility_level) { Snippet::PUBLIC }
    let(:snippet) { create(:project_snippet, :repository, author: admin, visibility_level: visibility_level, project: project) }
    let(:params) { { title: 'Foo' } }

    it_behaves_like 'PUT request permissions for admin mode' do
      let(:path) { "/projects/#{snippet.project.id}/snippets/#{snippet.id}" }
    end

    it_behaves_like 'snippet file updates'
    it_behaves_like 'snippet non-file updates'
    it_behaves_like 'snippet individual non-file updates'
    it_behaves_like 'invalid snippet updates'

    it_behaves_like 'update with repository actions' do
      let(:snippet_without_repo) { create(:project_snippet, author: admin, project: project, visibility_level: visibility_level) }
    end

    context 'when the snippet is spam' do
      before do
        allow_next_instance_of(Spam::AkismetService) do |instance|
          allow(instance).to receive(:spam?).and_return(true)
        end
      end

      context 'when the snippet is private' do
        let(:visibility_level) { Snippet::PRIVATE }

        it 'creates the snippet' do
          expect { update_snippet(admin_mode: true, params: params) }
            .to change { snippet.reload.title }.to('Foo')
        end
      end

      context 'when the snippet is public' do
        let(:visibility_level) { Snippet::PUBLIC }

        it 'rejects the snippet' do
          expect { update_snippet(params: params) }
            .not_to change { snippet.reload.title }
        end

        it 'creates a spam log' do
          expect { update_snippet(params: params) }
            .to log_spam(title: 'Foo', user_id: admin.id, noteable_type: 'ProjectSnippet')
        end
      end

      context 'when the private snippet is made public' do
        let(:visibility_level) { Snippet::PRIVATE }

        it 'rejects the snippet' do
          expect { update_snippet(admin_mode: true, params: { title: 'Foo', visibility: 'public' }) }
            .not_to change { snippet.reload.title }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']['error']).to match(/snippet has been recognized as spam/)
        end

        it 'creates a spam log' do
          expect { update_snippet(admin_mode: true, params: { title: 'Foo', visibility: 'public' }) }
            .to log_spam(title: 'Foo', user_id: admin.id, noteable_type: 'ProjectSnippet')
        end
      end
    end

    context 'with snippets disabled' do
      it_behaves_like '403 response' do
        subject(:request) { put api("/projects/#{project_no_snippets.id}/snippets/#{non_existing_record_id}", admin, admin_mode: true), params: { description: 'foo' } }
      end
    end

    def update_snippet(snippet_id: snippet.id, admin_mode: false, params: {})
      put api("/projects/#{snippet.project.id}/snippets/#{snippet_id}", admin, admin_mode: admin_mode), params: params
    end
  end

  describe 'DELETE /projects/:project_id/snippets/:id/' do
    let_it_be(:snippet, refind: true) { public_snippet }
    let(:path) { "/projects/#{snippet.project.id}/snippets/#{snippet.id}/" }

    it_behaves_like 'DELETE request permissions for admin mode'

    it 'deletes snippet' do
      delete api(path, admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:no_content)
    end

    it 'returns 404 for invalid snippet id' do
      delete api("/projects/#{snippet.project.id}/snippets/#{non_existing_record_id}", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Snippet Not Found')
    end

    it_behaves_like '412 response' do
      subject(:request) { api(path, admin, admin_mode: true) }
    end

    context 'with snippets disabled' do
      it_behaves_like '403 response' do
        subject(:request) { delete api("/projects/#{project_no_snippets.id}/snippets/#{non_existing_record_id}", admin, admin_mode: true) }
      end
    end
  end

  describe 'GET /projects/:project_id/snippets/:id/raw' do
    let_it_be(:snippet) { create(:project_snippet, :repository, :public, author: admin, project: project) }
    let(:path) { "/projects/#{snippet.project.id}/snippets/#{snippet.id}/raw" }

    it_behaves_like 'GET request permissions for admin mode' do
      let_it_be(:snippet_with_empty_repo) { create(:project_snippet, :empty_repo, author: admin, project: project) }

      let(:snippet) { snippet_with_empty_repo }
      let(:failed_status_code) { :not_found }
    end

    it 'returns raw text' do
      get api(path, admin)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.media_type).to eq 'text/plain'
      expect(response.parsed_body).to be_empty
    end

    it 'returns 404 for invalid snippet id' do
      get api("/projects/#{snippet.project.id}/snippets/#{non_existing_record_id}/raw", admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Snippet Not Found')
    end

    it_behaves_like 'project snippet access levels'

    context 'with snippets disabled' do
      it_behaves_like '403 response' do
        subject(:request) { get api("/projects/#{project_no_snippets.id}/snippets/#{non_existing_record_id}/raw", admin, admin_mode: true) }
      end
    end

    it_behaves_like 'snippet blob content' do
      let_it_be(:snippet_with_empty_repo) { create(:project_snippet, :empty_repo, author: admin, project: project) }
      let_it_be(:admin_mode) { snippet.author.admin? }

      subject { get api(path, snippet.author, admin_mode: admin_mode) }
    end
  end

  describe 'GET /projects/:project_id/snippets/:id/files/:ref/:file_path/raw' do
    let_it_be(:snippet) { create(:project_snippet, :repository, author: admin, project: project) }

    let(:path) { "/projects/#{snippet.project.id}/snippets/#{snippet.id}/files/master/%2Egitattributes/raw" }

    it_behaves_like 'GET request permissions for admin mode' do
      let(:failed_status_code) { :not_found }
    end

    it_behaves_like 'raw snippet files' do
      let(:api_path) { "/projects/#{snippet.project.id}/snippets/#{snippet_id}/files/#{ref}/#{file_path}/raw" }
    end

    it_behaves_like 'project snippet access levels'
  end
end
