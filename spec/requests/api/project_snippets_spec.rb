require 'rails_helper'

describe API::ProjectSnippets do
  set(:project) { create(:project, :public) }
  set(:user) { create(:user) }
  set(:admin) { create(:admin) }

  describe "GET /projects/:project_id/snippets/:id/user_agent_detail" do
    let(:snippet) { create(:project_snippet, :public, project: project) }
    let!(:user_agent_detail) { create(:user_agent_detail, subject: snippet) }

    it 'exposes known attributes' do
      get api("/projects/#{project.id}/snippets/#{snippet.id}/user_agent_detail", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['user_agent']).to eq(user_agent_detail.user_agent)
      expect(json_response['ip_address']).to eq(user_agent_detail.ip_address)
      expect(json_response['akismet_submitted']).to eq(user_agent_detail.submitted)
    end

    it 'respects project scoping' do
      other_project = create(:project)

      get api("/projects/#{other_project.id}/snippets/#{snippet.id}/user_agent_detail", admin)
      expect(response).to have_gitlab_http_status(404)
    end

    it "returns unautorized for non-admin users" do
      get api("/projects/#{snippet.project.id}/snippets/#{snippet.id}/user_agent_detail", user)

      expect(response).to have_gitlab_http_status(403)
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

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(3)
      expect(json_response.map { |snippet| snippet['id'] }).to include(public_snippet.id, internal_snippet.id, private_snippet.id)
      expect(json_response.last).to have_key('web_url')
    end

    it 'hides private snippets from regular user' do
      create(:project_snippet, :private, project: project)

      get api("/projects/#{project.id}/snippets/", user)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.size).to eq(0)
    end
  end

  describe 'GET /projects/:project_id/snippets/:id' do
    let(:user) { create(:user) }
    let(:snippet) { create(:project_snippet, :public, project: project) }

    it 'returns snippet json' do
      get api("/projects/#{project.id}/snippets/#{snippet.id}", user)

      expect(response).to have_gitlab_http_status(200)

      expect(json_response['title']).to eq(snippet.title)
      expect(json_response['description']).to eq(snippet.description)
      expect(json_response['file_name']).to eq(snippet.file_name)
    end

    it 'returns 404 for invalid snippet id' do
      get api("/projects/#{project.id}/snippets/1234", user)

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 Not found')
    end
  end

  describe 'POST /projects/:project_id/snippets/' do
    let(:params) do
      {
        title: 'Test Title',
        file_name: 'test.rb',
        description: 'test description',
        code: 'puts "hello world"',
        visibility: 'public'
      }
    end

    it 'creates a new snippet' do
      post api("/projects/#{project.id}/snippets/", admin), params

      expect(response).to have_gitlab_http_status(201)
      snippet = ProjectSnippet.find(json_response['id'])
      expect(snippet.content).to eq(params[:code])
      expect(snippet.description).to eq(params[:description])
      expect(snippet.title).to eq(params[:title])
      expect(snippet.file_name).to eq(params[:file_name])
      expect(snippet.visibility_level).to eq(Snippet::PUBLIC)
    end

    it 'returns 400 for missing parameters' do
      params.delete(:title)

      post api("/projects/#{project.id}/snippets/", admin), params

      expect(response).to have_gitlab_http_status(400)
    end

    context 'when the snippet is spam' do
      def create_snippet(project, snippet_params = {})
        project.add_developer(user)

        post api("/projects/#{project.id}/snippets", user), params.merge(snippet_params)
      end

      before do
        allow_any_instance_of(AkismetService).to receive(:spam?).and_return(true)
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

          expect(response).to have_gitlab_http_status(400)
          expect(json_response['message']).to eq({ "error" => "Spam detected" })
        end

        it 'creates a spam log' do
          expect { create_snippet(project, visibility: 'public') }
            .to change { SpamLog.count }.by(1)
        end
      end
    end
  end

  describe 'PUT /projects/:project_id/snippets/:id/' do
    let(:visibility_level) { Snippet::PUBLIC }
    let(:snippet) { create(:project_snippet, author: admin, visibility_level: visibility_level) }

    it 'updates snippet' do
      new_content = 'New content'
      new_description = 'New description'

      put api("/projects/#{snippet.project.id}/snippets/#{snippet.id}/", admin), code: new_content, description: new_description

      expect(response).to have_gitlab_http_status(200)
      snippet.reload
      expect(snippet.content).to eq(new_content)
      expect(snippet.description).to eq(new_description)
    end

    it 'returns 404 for invalid snippet id' do
      put api("/projects/#{snippet.project.id}/snippets/1234", admin), title: 'foo'

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 Snippet Not Found')
    end

    it 'returns 400 for missing parameters' do
      put api("/projects/#{project.id}/snippets/1234", admin)

      expect(response).to have_gitlab_http_status(400)
    end

    context 'when the snippet is spam' do
      def update_snippet(snippet_params = {})
        put api("/projects/#{snippet.project.id}/snippets/#{snippet.id}", admin), snippet_params
      end

      before do
        allow_any_instance_of(AkismetService).to receive(:spam?).and_return(true)
      end

      context 'when the snippet is private' do
        let(:visibility_level) { Snippet::PRIVATE }

        it 'creates the snippet' do
          expect { update_snippet(title: 'Foo') }
            .to change { snippet.reload.title }.to('Foo')
        end
      end

      context 'when the snippet is public' do
        let(:visibility_level) { Snippet::PUBLIC }

        it 'rejects the snippet' do
          expect { update_snippet(title: 'Foo') }
            .not_to change { snippet.reload.title }
        end

        it 'creates a spam log' do
          expect { update_snippet(title: 'Foo') }
            .to change { SpamLog.count }.by(1)
        end
      end

      context 'when the private snippet is made public' do
        let(:visibility_level) { Snippet::PRIVATE }

        it 'rejects the snippet' do
          expect { update_snippet(title: 'Foo', visibility: 'public') }
            .not_to change { snippet.reload.title }

          expect(response).to have_gitlab_http_status(400)
          expect(json_response['message']).to eq({ "error" => "Spam detected" })
        end

        it 'creates a spam log' do
          expect { update_snippet(title: 'Foo', visibility: 'public') }
            .to change { SpamLog.count }.by(1)
        end
      end
    end
  end

  describe 'DELETE /projects/:project_id/snippets/:id/' do
    let(:snippet) { create(:project_snippet, author: admin) }

    it 'deletes snippet' do
      delete api("/projects/#{snippet.project.id}/snippets/#{snippet.id}/", admin)

      expect(response).to have_gitlab_http_status(204)
    end

    it 'returns 404 for invalid snippet id' do
      delete api("/projects/#{snippet.project.id}/snippets/1234", admin)

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 Snippet Not Found')
    end

    it_behaves_like '412 response' do
      let(:request) { api("/projects/#{snippet.project.id}/snippets/#{snippet.id}/", admin) }
    end
  end

  describe 'GET /projects/:project_id/snippets/:id/raw' do
    let(:snippet) { create(:project_snippet, author: admin) }

    it 'returns raw text' do
      get api("/projects/#{snippet.project.id}/snippets/#{snippet.id}/raw", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(response.content_type).to eq 'text/plain'
      expect(response.body).to eq(snippet.content)
    end

    it 'returns 404 for invalid snippet id' do
      get api("/projects/#{snippet.project.id}/snippets/1234/raw", admin)

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 Snippet Not Found')
    end
  end
end
