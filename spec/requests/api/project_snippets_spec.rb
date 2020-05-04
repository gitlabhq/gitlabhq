# frozen_string_literal: true

require 'spec_helper'

describe API::ProjectSnippets do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:project_no_snippets) { create(:project, :snippets_disabled) }

  before do
    project_no_snippets.add_developer(admin)
    project_no_snippets.add_developer(user)
  end

  describe "GET /projects/:project_id/snippets/:id/user_agent_detail" do
    let(:snippet) { create(:project_snippet, :public, project: project) }
    let!(:user_agent_detail) { create(:user_agent_detail, subject: snippet) }

    it 'exposes known attributes' do
      get api("/projects/#{project.id}/snippets/#{snippet.id}/user_agent_detail", admin)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['user_agent']).to eq(user_agent_detail.user_agent)
      expect(json_response['ip_address']).to eq(user_agent_detail.ip_address)
      expect(json_response['akismet_submitted']).to eq(user_agent_detail.submitted)
    end

    it 'respects project scoping' do
      other_project = create(:project)

      get api("/projects/#{other_project.id}/snippets/#{snippet.id}/user_agent_detail", admin)
      expect(response).to have_gitlab_http_status(:not_found)
    end

    it "returns unauthorized for non-admin users" do
      get api("/projects/#{snippet.project.id}/snippets/#{snippet.id}/user_agent_detail", user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    context 'with snippets disabled' do
      it_behaves_like '403 response' do
        let(:request) { get api("/projects/#{project_no_snippets.id}/snippets/123/user_agent_detail", admin) }
      end
    end
  end

  describe 'GET /projects/:project_id/snippets/' do
    let(:user) { create(:user) }

    it 'returns all snippets available to team member' do
      project.add_developer(user)
      public_snippet = create(:project_snippet, :public, project: project)
      internal_snippet = create(:project_snippet, :internal, project: project)
      private_snippet = create(:project_snippet, :private, project: project)

      get api("/projects/#{project.id}/snippets", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(3)
      expect(json_response.map { |snippet| snippet['id'] }).to include(public_snippet.id, internal_snippet.id, private_snippet.id)
      expect(json_response.last).to have_key('web_url')
    end

    it 'hides private snippets from regular user' do
      create(:project_snippet, :private, project: project)

      get api("/projects/#{project.id}/snippets/", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(0)
    end

    context 'with snippets disabled' do
      it_behaves_like '403 response' do
        let(:request) { get api("/projects/#{project_no_snippets.id}/snippets", user) }
      end
    end
  end

  describe 'GET /projects/:project_id/snippets/:id' do
    let(:user) { create(:user) }
    let(:snippet) { create(:project_snippet, :public, :repository, project: project) }

    it 'returns snippet json' do
      get api("/projects/#{project.id}/snippets/#{snippet.id}", user)

      expect(response).to have_gitlab_http_status(:ok)

      expect(json_response['title']).to eq(snippet.title)
      expect(json_response['description']).to eq(snippet.description)
      expect(json_response['file_name']).to eq(snippet.file_name_on_repo)
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
        let(:request) { get api("/projects/#{project_no_snippets.id}/snippets/123", user) }
      end
    end
  end

  describe 'POST /projects/:project_id/snippets/' do
    let(:params) do
      {
        title: 'Test Title',
        file_name: 'test.rb',
        description: 'test description',
        content: 'puts "hello world"',
        visibility: 'public'
      }
    end

    shared_examples 'project snippet repository actions' do
      let(:snippet) { ProjectSnippet.find(json_response['id']) }

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

    context 'with an external user' do
      let(:user) { create(:user, :external) }

      context 'that belongs to the project' do
        before do
          project.add_developer(user)
        end

        it 'creates a new snippet' do
          post api("/projects/#{project.id}/snippets/", user), params: params

          expect(response).to have_gitlab_http_status(:created)
        end
      end

      context 'that does not belong to the project' do
        it 'does not create a new snippet' do
          post api("/projects/#{project.id}/snippets/", user), params: params

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'with a regular user' do
      let(:user) { create(:user) }

      before do
        project.add_developer(user)
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC, Gitlab::VisibilityLevel::PRIVATE])
        params['visibility'] = 'internal'
      end

      it 'creates a new snippet' do
        post api("/projects/#{project.id}/snippets/", user), params: params

        expect(response).to have_gitlab_http_status(:created)
        snippet = ProjectSnippet.find(json_response['id'])
        expect(snippet.content).to eq(params[:content])
        expect(snippet.description).to eq(params[:description])
        expect(snippet.title).to eq(params[:title])
        expect(snippet.file_name).to eq(params[:file_name])
        expect(snippet.visibility_level).to eq(Snippet::INTERNAL)
      end

      it_behaves_like 'project snippet repository actions' do
        subject { post api("/projects/#{project.id}/snippets/", user), params: params }
      end
    end

    it 'creates a new snippet' do
      post api("/projects/#{project.id}/snippets/", admin), params: params

      expect(response).to have_gitlab_http_status(:created)
      snippet = ProjectSnippet.find(json_response['id'])
      expect(snippet.content).to eq(params[:content])
      expect(snippet.description).to eq(params[:description])
      expect(snippet.title).to eq(params[:title])
      expect(snippet.file_name).to eq(params[:file_name])
      expect(snippet.visibility_level).to eq(Snippet::PUBLIC)
    end

    it_behaves_like 'project snippet repository actions' do
      subject { post api("/projects/#{project.id}/snippets/", admin), params: params }
    end

    it 'returns 400 for missing parameters' do
      params.delete(:title)

      post api("/projects/#{project.id}/snippets/", admin), params: params

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns 400 for empty content field' do
      params[:content] = ''

      post api("/projects/#{project.id}/snippets/", admin), params: params

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    context 'when the snippet is spam' do
      def create_snippet(project, snippet_params = {})
        project.add_developer(user)

        post api("/projects/#{project.id}/snippets", user), params: params.merge(snippet_params)
      end

      before do
        allow_next_instance_of(Spam::AkismetService) do |instance|
          allow(instance).to receive(:spam?).and_return(true)
        end
      end

      context 'when the snippet is private' do
        it 'creates the snippet' do
          expect { create_snippet(project, visibility: 'private') }
            .to change { Snippet.count }.by(1)
        end
      end

      context 'when the snippet is public' do
        it 'rejects the snippet' do
          expect { create_snippet(project, visibility: 'public') }
            .not_to change { Snippet.count }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq({ "error" => "Spam detected" })
        end

        it 'creates a spam log' do
          expect { create_snippet(project, visibility: 'public') }
            .to log_spam(title: 'Test Title', user_id: user.id, noteable_type: 'ProjectSnippet')
        end
      end
    end

    context 'with snippets disabled' do
      it_behaves_like '403 response' do
        let(:request) { post api("/projects/#{project_no_snippets.id}/snippets", user), params: params }
      end
    end
  end

  describe 'PUT /projects/:project_id/snippets/:id/' do
    let(:visibility_level) { Snippet::PUBLIC }
    let(:snippet) { create(:project_snippet, :repository, author: admin, visibility_level: visibility_level, project: project) }

    it 'updates snippet' do
      new_content = 'New content'
      new_description = 'New description'

      update_snippet(params: { content: new_content, description: new_description, visibility: 'private' })

      expect(response).to have_gitlab_http_status(:ok)
      snippet.reload
      expect(snippet.content).to eq(new_content)
      expect(snippet.description).to eq(new_description)
      expect(snippet.visibility).to eq('private')
    end

    it 'updates snippet with content parameter' do
      new_content = 'New content'
      new_description = 'New description'

      update_snippet(params: { content: new_content, description: new_description })

      expect(response).to have_gitlab_http_status(:ok)
      snippet.reload
      expect(snippet.content).to eq(new_content)
      expect(snippet.description).to eq(new_description)
    end

    it 'returns 404 for invalid snippet id' do
      update_snippet(snippet_id: non_existing_record_id, params: { title: 'foo' })

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Snippet Not Found')
    end

    it 'returns 400 for missing parameters' do
      update_snippet

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns 400 for empty content field' do
      update_snippet(params: { content: '' })

      expect(response).to have_gitlab_http_status(:bad_request)
    end

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
          expect { update_snippet(params: { title: 'Foo' }) }
            .to change { snippet.reload.title }.to('Foo')
        end
      end

      context 'when the snippet is public' do
        let(:visibility_level) { Snippet::PUBLIC }

        it 'rejects the snippet' do
          expect { update_snippet(params: { title: 'Foo' }) }
            .not_to change { snippet.reload.title }
        end

        it 'creates a spam log' do
          expect { update_snippet(params: { title: 'Foo' }) }
            .to log_spam(title: 'Foo', user_id: admin.id, noteable_type: 'ProjectSnippet')
        end
      end

      context 'when the private snippet is made public' do
        let(:visibility_level) { Snippet::PRIVATE }

        it 'rejects the snippet' do
          expect { update_snippet(params: { title: 'Foo', visibility: 'public' }) }
            .not_to change { snippet.reload.title }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq({ "error" => "Spam detected" })
        end

        it 'creates a spam log' do
          expect { update_snippet(params: { title: 'Foo', visibility: 'public' }) }
            .to log_spam(title: 'Foo', user_id: admin.id, noteable_type: 'ProjectSnippet')
        end
      end
    end

    context 'with snippets disabled' do
      it_behaves_like '403 response' do
        let(:request) { put api("/projects/#{project_no_snippets.id}/snippets/123", admin), params: { description: 'foo' } }
      end
    end

    def update_snippet(snippet_id: snippet.id, params: {})
      put api("/projects/#{snippet.project.id}/snippets/#{snippet_id}", admin), params: params
    end
  end

  describe 'DELETE /projects/:project_id/snippets/:id/' do
    let(:snippet) { create(:project_snippet, author: admin, project: project) }

    it 'deletes snippet' do
      delete api("/projects/#{snippet.project.id}/snippets/#{snippet.id}/", admin)

      expect(response).to have_gitlab_http_status(:no_content)
    end

    it 'returns 404 for invalid snippet id' do
      delete api("/projects/#{snippet.project.id}/snippets/#{non_existing_record_id}", admin)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Snippet Not Found')
    end

    it_behaves_like '412 response' do
      let(:request) { api("/projects/#{snippet.project.id}/snippets/#{snippet.id}/", admin) }
    end

    context 'with snippets disabled' do
      it_behaves_like '403 response' do
        let(:request) { delete api("/projects/#{project_no_snippets.id}/snippets/123", admin) }
      end
    end
  end

  describe 'GET /projects/:project_id/snippets/:id/raw' do
    let_it_be(:snippet) { create(:project_snippet, :repository, author: admin, project: project) }

    it 'returns raw text' do
      get api("/projects/#{snippet.project.id}/snippets/#{snippet.id}/raw", admin)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.content_type).to eq 'text/plain'
    end

    it 'returns 404 for invalid snippet id' do
      get api("/projects/#{snippet.project.id}/snippets/#{non_existing_record_id}/raw", admin)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Snippet Not Found')
    end

    context 'with snippets disabled' do
      it_behaves_like '403 response' do
        let(:request) { get api("/projects/#{project_no_snippets.id}/snippets/123/raw", admin) }
      end
    end

    it_behaves_like 'snippet blob content' do
      let_it_be(:snippet_with_empty_repo) { create(:project_snippet, :empty_repo, author: admin, project: project) }

      subject { get api("/projects/#{snippet.project.id}/snippets/#{snippet.id}/raw", snippet.author) }
    end
  end
end
