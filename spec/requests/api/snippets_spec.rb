# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Snippets, factory_default: :keep do
  include SnippetHelpers

  let_it_be(:admin)            { create(:user, :admin) }
  let_it_be(:user)             { create(:user) }
  let_it_be(:other_user)       { create(:user) }

  let_it_be(:public_snippet)   { create(:personal_snippet, :repository, :public, author: user) }
  let_it_be(:private_snippet)  { create(:personal_snippet, :repository, :private, author: user) }
  let_it_be(:internal_snippet) { create(:personal_snippet, :repository, :internal, author: user) }

  let_it_be(:user_token)       { create(:personal_access_token, user: user) }
  let_it_be(:other_user_token) { create(:personal_access_token, user: other_user) }
  let_it_be(:project) do
    create_default(:project, :public).tap do |p|
      p.add_maintainer(user)
    end
  end

  describe 'GET /snippets/' do
    it 'returns snippets available for user' do
      get api("/snippets/", personal_access_token: user_token)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.map { |snippet| snippet['id']} ).to contain_exactly(
        public_snippet.id,
        internal_snippet.id,
        private_snippet.id)
      expect(json_response.last).to have_key('web_url')
      expect(json_response.last).to have_key('raw_url')
      expect(json_response.last).to have_key('files')
      expect(json_response.last).to have_key('visibility')
    end

    it 'hides private snippets from regular user' do
      get api("/snippets/", personal_access_token: other_user_token)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(0)
    end

    it 'returns 401 for non-authenticated' do
      get api("/snippets/")

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'does not return snippets related to a project with disable feature visibility' do
      public_snippet = create(:project_snippet, :public, author: user, project: project)
      project.project_feature.update_attribute(:snippets_access_level, 0)

      get api("/snippets/", personal_access_token: user_token)

      json_response.each do |snippet|
        expect(snippet["id"]).not_to eq(public_snippet.id)
      end
    end
  end

  describe 'GET /snippets/public' do
    let_it_be(:public_snippet_other)     { create(:personal_snippet, :repository, :public, author: other_user) }
    let_it_be(:private_snippet_other)    { create(:personal_snippet, :repository, :private, author: other_user) }
    let_it_be(:internal_snippet_other)   { create(:personal_snippet, :repository, :internal, author: other_user) }
    let_it_be(:public_snippet_project)   { create(:project_snippet, :repository, :public, author: user) }
    let_it_be(:private_snippet_project)  { create(:project_snippet, :repository, :private, author: user) }
    let_it_be(:internal_snippet_project) { create(:project_snippet, :repository, :internal, author: user) }

    let(:path) { "/snippets/public" }

    it 'returns only public snippets from all users when authenticated' do
      get api(path, personal_access_token: user_token)

      aggregate_failures do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.map { |snippet| snippet['id']} ).to contain_exactly(
          public_snippet.id,
          public_snippet_other.id)
        expect(json_response.map { |snippet| snippet['web_url']} ).to contain_exactly(
          "http://localhost/-/snippets/#{public_snippet.id}",
          "http://localhost/-/snippets/#{public_snippet_other.id}")
        expect(json_response[0]['files'].first).to eq snippet_blob_file(public_snippet_other.blobs.first)
        expect(json_response[1]['files'].first).to eq snippet_blob_file(public_snippet.blobs.first)
      end
    end

    it 'requires authentication' do
      get api(path, nil)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  describe 'GET /snippets/:id/raw' do
    let(:snippet) { private_snippet }

    it_behaves_like 'snippet access with different users' do
      let(:path) { "/snippets/#{snippet.id}/raw" }
    end

    it 'returns raw text' do
      get api("/snippets/#{snippet.id}/raw", personal_access_token: user_token)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.media_type).to eq 'text/plain'
      expect(headers['Content-Disposition']).to match(/^inline/)
    end

    it 'returns 404 for invalid snippet id' do
      snippet.destroy!

      get api("/snippets/#{snippet.id}/raw", personal_access_token: user_token)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Snippet Not Found')
    end

    it_behaves_like 'snippet blob content' do
      let_it_be(:snippet_with_empty_repo) { create(:personal_snippet, :empty_repo, :private, author: user) }

      subject { get api("/snippets/#{snippet.id}/raw", snippet.author, personal_access_token: user_token) }
    end
  end

  describe 'GET /snippets/:id/files/:ref/:file_path/raw' do
    let_it_be(:snippet) { private_snippet }

    it_behaves_like 'raw snippet files' do
      let(:api_path) { "/snippets/#{snippet_id}/files/#{ref}/#{file_path}/raw" }
    end

    it_behaves_like 'snippet access with different users' do
      let(:path) { "/snippets/#{snippet.id}/files/master/%2Egitattributes/raw" }
    end
  end

  describe 'GET /snippets/:id' do
    let(:snippet_id) { private_snippet.id }

    subject { get api("/snippets/#{snippet_id}", personal_access_token: user_token) }

    context 'with the author' do
      it 'returns snippet json' do
        subject

        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response['title']).to eq(private_snippet.title)
        expect(json_response['description']).to eq(private_snippet.description)
        expect(json_response['file_name']).to eq(private_snippet.file_name_on_repo)
        expect(json_response['files']).to eq(private_snippet.blobs.map { |blob| snippet_blob_file(blob) })
        expect(json_response['visibility']).to eq(private_snippet.visibility)
        expect(json_response['ssh_url_to_repo']).to eq(private_snippet.ssh_url_to_repo)
        expect(json_response['http_url_to_repo']).to eq(private_snippet.http_url_to_repo)
      end
    end

    context 'with a non-existent snippet ID' do
      let(:snippet_id) { 0 }

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Snippet Not Found')
      end
    end

    it_behaves_like 'snippet access with different users' do
      let(:path) { "/snippets/#{snippet.id}" }
    end
  end

  describe 'POST /snippets/' do
    let(:base_params) do
      {
        title: 'Test Title',
        description: 'test description',
        visibility: 'public'
      }
    end

    let(:file_path) { 'file_1.rb' }
    let(:file_content) { 'puts "hello world"' }

    let(:params) { base_params.merge(file_params, extra_params) }
    let(:file_params) { { files: [{ file_path: file_path, content: file_content }] } }
    let(:extra_params) { {} }

    subject { post api("/snippets/", personal_access_token: user_token), params: params }

    shared_examples 'snippet creation' do
      let(:snippet) { Snippet.find(json_response["id"]) }

      it 'creates a new snippet' do
        expect do
          subject
        end.to change { PersonalSnippet.count }.by(1)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['title']).to eq(params[:title])
        expect(json_response['description']).to eq(params[:description])
        expect(json_response['file_name']).to eq(file_path)
        expect(json_response['files']).to eq(snippet.blobs.map { |blob| snippet_blob_file(blob) })
        expect(json_response['visibility']).to eq(params[:visibility])
      end

      it 'creates repository' do
        subject

        expect(snippet.repository.exists?).to be_truthy
      end

      it 'commit the files to the repository' do
        subject

        blob = snippet.repository.blob_at(snippet.default_branch, file_path)

        expect(blob.data).to eq file_content
      end
    end

    context 'with files parameter' do
      it_behaves_like 'snippet creation with files parameter'

      context 'with multiple files' do
        let(:file_params) do
          {
            files: [
              { file_path: 'file_1.rb', content: 'puts "hello world"' },
              { file_path: 'file_2.rb', content: 'puts "hello world 2"' }
            ]
          }
        end

        it_behaves_like 'snippet creation'
      end
    end

    it_behaves_like 'snippet creation without files parameter'

    context 'with restricted visibility settings' do
      before do
        stub_application_setting(restricted_visibility_levels:
                                   [Gitlab::VisibilityLevel::INTERNAL,
                                    Gitlab::VisibilityLevel::PRIVATE])
      end

      it_behaves_like 'snippet creation'
    end

    it_behaves_like 'snippet creation'

    context 'with an external user' do
      let(:user) { create(:user, :external) }
      let(:user_token) { create(:personal_access_token, user: user) }

      it 'does not create a new snippet' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    it 'returns 400 for missing parameters' do
      params.delete(:title)

      subject

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns 400 if title is blank' do
      params[:title] = ''

      subject

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq 'title is empty'
    end

    context 'when save fails because the repository could not be created' do
      before do
        allow_next_instance_of(Snippets::CreateService) do |instance|
          allow(instance).to receive(:create_repository).and_raise(Snippets::CreateService::CreateRepositoryError)
        end
      end

      it 'returns 400' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when the snippet is spam' do
      before do
        allow_next_instance_of(Spam::AkismetService) do |instance|
          allow(instance).to receive(:spam?).and_return(true)
        end
      end

      context 'when the snippet is private' do
        let(:extra_params) { { visibility: 'private' } }

        it 'creates the snippet' do
          expect { subject }.to change { Snippet.count }.by(1)
        end
      end

      context 'when the snippet is public' do
        let(:extra_params) { { visibility: 'public' } }

        it 'rejects the snippet' do
          expect { subject }.not_to change { Snippet.count }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq({ "error" => "Spam detected" })
        end

        it 'creates a spam log' do
          expect { subject }
            .to log_spam(title: 'Test Title', user_id: user.id, noteable_type: 'PersonalSnippet')
        end
      end
    end
  end

  describe 'PUT /snippets/:id' do
    let(:visibility_level) { Snippet::PUBLIC }
    let(:snippet) do
      create(:personal_snippet, :repository, author: user, visibility_level: visibility_level)
    end

    it_behaves_like 'snippet file updates'
    it_behaves_like 'snippet non-file updates'
    it_behaves_like 'snippet individual non-file updates'
    it_behaves_like 'invalid snippet updates'

    it "returns 404 for another user's snippet" do
      update_snippet(requester: other_user, params: { title: 'foobar' })

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Snippet Not Found')
    end

    context 'with restricted visibility settings' do
      before do
        stub_application_setting(restricted_visibility_levels:
                                   [Gitlab::VisibilityLevel::PUBLIC,
                                    Gitlab::VisibilityLevel::PRIVATE])
      end

      it_behaves_like 'snippet non-file updates'
    end

    it_behaves_like 'update with repository actions' do
      let(:snippet_without_repo) { create(:personal_snippet, author: user, visibility_level: visibility_level) }
    end

    context 'when the snippet is spam' do
      before do
        allow_next_instance_of(Spam::AkismetService) do |instance|
          allow(instance).to receive(:spam?).and_return(true)
        end
      end

      context 'when the snippet is private' do
        let(:visibility_level) { Snippet::PRIVATE }

        it 'updates the snippet' do
          expect { update_snippet(params: { title: 'Foo' }) }
            .to change { snippet.reload.title }.to('Foo')
        end
      end

      context 'when the snippet is public' do
        let(:visibility_level) { Snippet::PUBLIC }

        it 'rejects the snippet' do
          expect { update_snippet(params: { title: 'Foo' }) }
            .not_to change { snippet.reload.title }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq({ "error" => "Spam detected" })
        end

        it 'creates a spam log' do
          expect { update_snippet(params: { title: 'Foo' }) }.to log_spam(title: 'Foo', user_id: user.id, noteable_type: 'PersonalSnippet')
        end
      end

      context 'when a private snippet is made public' do
        let(:visibility_level) { Snippet::PRIVATE }

        it 'rejects the snippet' do
          expect { update_snippet(params: { title: 'Foo', visibility: 'public' }) }
            .not_to change { snippet.reload.title }
        end

        it 'creates a spam log' do
          expect { update_snippet(params: { title: 'Foo', visibility: 'public' }) }
            .to log_spam(title: 'Foo', user_id: user.id, noteable_type: 'PersonalSnippet')
        end
      end
    end

    context "when admin" do
      let_it_be(:token) { create(:personal_access_token, user: admin, scopes: [:sudo]) }

      subject do
        put api("/snippets/#{snippet.id}", personal_access_token: token), params: { visibility: 'private', sudo: user.id }
      end

      context 'when sudo is defined' do
        it 'returns 200 and updates snippet visibility' do
          expect(snippet.visibility).not_to eq('private')

          subject

          expect(response).to have_gitlab_http_status(:success)
          expect(json_response["visibility"]).to eq 'private'
        end

        it 'does not commit data' do
          expect_any_instance_of(SnippetRepository).not_to receive(:multi_files_action)

          subject
        end
      end
    end

    def update_snippet(snippet_id: snippet.id, params: {}, requester: user)
      put api("/snippets/#{snippet_id}", requester), params: params
    end
  end

  describe 'DELETE /snippets/:id' do
    it 'deletes snippet' do
      expect do
        delete api("/snippets/#{public_snippet.id}", personal_access_token: user_token)

        expect(response).to have_gitlab_http_status(:no_content)
      end.to change { PersonalSnippet.count }.by(-1)
    end

    it 'returns 404 for invalid snippet id' do
      delete api("/snippets/#{non_existing_record_id}", personal_access_token: user_token)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Snippet Not Found')
    end

    it_behaves_like '412 response' do
      let(:request) { api("/snippets/#{public_snippet.id}", personal_access_token: user_token) }
    end
  end

  describe "GET /snippets/:id/user_agent_detail" do
    let(:snippet) { public_snippet }

    it 'exposes known attributes' do
      user_agent_detail = create(:user_agent_detail, subject: snippet)

      get api("/snippets/#{snippet.id}/user_agent_detail", admin)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['user_agent']).to eq(user_agent_detail.user_agent)
      expect(json_response['ip_address']).to eq(user_agent_detail.ip_address)
      expect(json_response['akismet_submitted']).to eq(user_agent_detail.submitted)
    end

    it "returns unauthorized for non-admin users" do
      get api("/snippets/#{snippet.id}/user_agent_detail", user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end
end
