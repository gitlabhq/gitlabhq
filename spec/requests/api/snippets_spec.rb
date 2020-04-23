# frozen_string_literal: true

require 'spec_helper'

describe API::Snippets do
  let!(:user) { create(:user) }

  describe 'GET /snippets/' do
    it 'returns snippets available' do
      public_snippet = create(:personal_snippet, :public, author: user)
      private_snippet = create(:personal_snippet, :private, author: user)
      internal_snippet = create(:personal_snippet, :internal, author: user)

      get api("/snippets/", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.map { |snippet| snippet['id']} ).to contain_exactly(
        public_snippet.id,
        internal_snippet.id,
        private_snippet.id)
      expect(json_response.last).to have_key('web_url')
      expect(json_response.last).to have_key('raw_url')
      expect(json_response.last).to have_key('visibility')
    end

    it 'hides private snippets from regular user' do
      create(:personal_snippet, :private)

      get api("/snippets/", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(0)
    end

    it 'returns 404 for non-authenticated' do
      create(:personal_snippet, :internal)

      get api("/snippets/")

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'does not return snippets related to a project with disable feature visibility' do
      project = create(:project)
      create(:project_member, project: project, user: user)
      public_snippet = create(:personal_snippet, :public, author: user, project: project)
      project.project_feature.update_attribute(:snippets_access_level, 0)

      get api("/snippets/", user)

      json_response.each do |snippet|
        expect(snippet["id"]).not_to eq(public_snippet.id)
      end
    end
  end

  describe 'GET /snippets/public' do
    let!(:other_user) { create(:user) }
    let!(:public_snippet) { create(:personal_snippet, :public, author: user) }
    let!(:private_snippet) { create(:personal_snippet, :private, author: user) }
    let!(:internal_snippet) { create(:personal_snippet, :internal, author: user) }
    let!(:public_snippet_other) { create(:personal_snippet, :public, author: other_user) }
    let!(:private_snippet_other) { create(:personal_snippet, :private, author: other_user) }
    let!(:internal_snippet_other) { create(:personal_snippet, :internal, author: other_user) }
    let!(:public_snippet_project) { create(:project_snippet, :public, author: user) }
    let!(:private_snippet_project) { create(:project_snippet, :private, author: user) }
    let!(:internal_snippet_project) { create(:project_snippet, :internal, author: user) }

    it 'returns all snippets with public visibility from all users' do
      get api("/snippets/public", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.map { |snippet| snippet['id']} ).to contain_exactly(
        public_snippet.id,
        public_snippet_other.id)
      expect(json_response.map { |snippet| snippet['web_url']} ).to contain_exactly(
        "http://localhost/snippets/#{public_snippet.id}",
        "http://localhost/snippets/#{public_snippet_other.id}")
      expect(json_response.map { |snippet| snippet['raw_url']} ).to contain_exactly(
        "http://localhost/snippets/#{public_snippet.id}/raw",
        "http://localhost/snippets/#{public_snippet_other.id}/raw")
    end
  end

  describe 'GET /snippets/:id/raw' do
    let_it_be(:author) { create(:user) }
    let_it_be(:snippet) { create(:personal_snippet, :repository, :private, author: author) }

    it 'requires authentication' do
      get api("/snippets/#{snippet.id}", nil)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns raw text' do
      get api("/snippets/#{snippet.id}/raw", author)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.content_type).to eq 'text/plain'
    end

    it 'forces attachment content disposition' do
      get api("/snippets/#{snippet.id}/raw", author)

      expect(headers['Content-Disposition']).to match(/^attachment/)
    end

    it 'returns 404 for invalid snippet id' do
      snippet.destroy

      get api("/snippets/#{snippet.id}/raw", author)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Snippet Not Found')
    end

    it 'hides private snippets from ordinary users' do
      get api("/snippets/#{snippet.id}/raw", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'shows internal snippets to ordinary users' do
      internal_snippet = create(:personal_snippet, :internal, author: author)

      get api("/snippets/#{internal_snippet.id}/raw", user)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it_behaves_like 'snippet blob content' do
      let_it_be(:snippet_with_empty_repo) { create(:personal_snippet, :empty_repo, :private, author: author) }

      subject { get api("/snippets/#{snippet.id}/raw", snippet.author) }
    end
  end

  describe 'GET /snippets/:id' do
    let_it_be(:admin) { create(:user, :admin) }
    let_it_be(:author) { create(:user) }
    let_it_be(:private_snippet) { create(:personal_snippet, :repository, :private, author: author) }
    let_it_be(:internal_snippet) { create(:personal_snippet, :repository, :internal, author: author) }

    it 'requires authentication' do
      get api("/snippets/#{private_snippet.id}", nil)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns snippet json' do
      get api("/snippets/#{private_snippet.id}", author)

      expect(response).to have_gitlab_http_status(:ok)

      expect(json_response['title']).to eq(private_snippet.title)
      expect(json_response['description']).to eq(private_snippet.description)
      expect(json_response['file_name']).to eq(private_snippet.file_name_on_repo)
      expect(json_response['visibility']).to eq(private_snippet.visibility)
      expect(json_response['ssh_url_to_repo']).to eq(private_snippet.ssh_url_to_repo)
      expect(json_response['http_url_to_repo']).to eq(private_snippet.http_url_to_repo)
    end

    it 'shows private snippets to an admin' do
      get api("/snippets/#{private_snippet.id}", admin)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'hides private snippets from an ordinary user' do
      get api("/snippets/#{private_snippet.id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'shows internal snippets to an ordinary user' do
      get api("/snippets/#{internal_snippet.id}", user)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'returns 404 for invalid snippet id' do
      private_snippet.destroy

      get api("/snippets/#{private_snippet.id}", admin)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Snippet Not Found')
    end
  end

  describe 'POST /snippets/' do
    let(:params) do
      {
        title: 'Test Title',
        file_name: 'test.rb',
        description: 'test description',
        content: 'puts "hello world"',
        visibility: 'public'
      }
    end

    shared_examples 'snippet creation' do
      let(:snippet) { Snippet.find(json_response["id"]) }

      subject { post api("/snippets/", user), params: params }

      it 'creates a new snippet' do
        expect do
          subject
        end.to change { PersonalSnippet.count }.by(1)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['title']).to eq(params[:title])
        expect(json_response['description']).to eq(params[:description])
        expect(json_response['file_name']).to eq(params[:file_name])
        expect(json_response['visibility']).to eq(params[:visibility])
      end

      it 'creates repository' do
        subject

        expect(snippet.repository.exists?).to be_truthy
      end

      it 'commit the files to the repository' do
        subject

        blob = snippet.repository.blob_at('master', params[:file_name])

        expect(blob.data).to eq params[:content]
      end
    end

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

      it 'does not create a new snippet' do
        post api("/snippets/", user), params: params

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    it 'returns 400 for missing parameters' do
      params.delete(:title)

      post api("/snippets/", user), params: params

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    context 'when the snippet is spam' do
      def create_snippet(snippet_params = {})
        post api('/snippets', user), params: params.merge(snippet_params)
      end

      before do
        allow_next_instance_of(Spam::AkismetService) do |instance|
          allow(instance).to receive(:spam?).and_return(true)
        end
      end

      context 'when the snippet is private' do
        it 'creates the snippet' do
          expect { create_snippet(visibility: 'private') }
            .to change { Snippet.count }.by(1)
        end
      end

      context 'when the snippet is public' do
        it 'rejects the shippet' do
          expect { create_snippet(visibility: 'public') }
            .not_to change { Snippet.count }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq({ "error" => "Spam detected" })
        end

        it 'creates a spam log' do
          expect { create_snippet(visibility: 'public') }
            .to log_spam(title: 'Test Title', user_id: user.id, noteable_type: 'PersonalSnippet')
        end
      end
    end
  end

  describe 'PUT /snippets/:id' do
    let(:visibility_level) { Snippet::PUBLIC }
    let(:other_user) { create(:user) }
    let(:snippet) do
      create(:personal_snippet, :repository, author: user, visibility_level: visibility_level)
    end

    shared_examples 'snippet updates' do
      it 'updates a snippet' do
        new_content = 'New content'
        new_description = 'New description'

        update_snippet(params: { content: new_content, description: new_description, visibility: 'internal' })

        expect(response).to have_gitlab_http_status(:ok)
        snippet.reload
        expect(snippet.content).to eq(new_content)
        expect(snippet.description).to eq(new_description)
        expect(snippet.visibility).to eq('internal')
      end
    end

    context 'with restricted visibility settings' do
      before do
        stub_application_setting(restricted_visibility_levels:
                                   [Gitlab::VisibilityLevel::PUBLIC,
                                    Gitlab::VisibilityLevel::PRIVATE])
      end

      it_behaves_like 'snippet updates'
    end

    it_behaves_like 'snippet updates'

    it 'returns 404 for invalid snippet id' do
      update_snippet(snippet_id: non_existing_record_id, params: { title: 'Foo' })

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Snippet Not Found')
    end

    it "returns 404 for another user's snippet" do
      update_snippet(requester: other_user, params: { title: 'foobar' })

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Snippet Not Found')
    end

    it 'returns 400 for missing parameters' do
      update_snippet

      expect(response).to have_gitlab_http_status(:bad_request)
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

        it 'rejects the shippet' do
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
      let(:admin) { create(:admin) }
      let(:token) { create(:personal_access_token, user: admin, scopes: [:sudo]) }

      subject do
        put api("/snippets/#{snippet.id}", admin, personal_access_token: token), params: { visibility: 'private', sudo: user.id }
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
    let!(:public_snippet) { create(:personal_snippet, :public, author: user) }

    it 'deletes snippet' do
      expect do
        delete api("/snippets/#{public_snippet.id}", user)

        expect(response).to have_gitlab_http_status(:no_content)
      end.to change { PersonalSnippet.count }.by(-1)
    end

    it 'returns 404 for invalid snippet id' do
      delete api("/snippets/#{non_existing_record_id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Snippet Not Found')
    end

    it_behaves_like '412 response' do
      let(:request) { api("/snippets/#{public_snippet.id}", user) }
    end
  end

  describe "GET /snippets/:id/user_agent_detail" do
    let(:admin) { create(:admin) }
    let(:snippet) { create(:personal_snippet, :public, author: user) }
    let!(:user_agent_detail) { create(:user_agent_detail, subject: snippet) }

    it 'exposes known attributes' do
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
