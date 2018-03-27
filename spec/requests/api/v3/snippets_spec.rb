require 'rails_helper'

describe API::V3::Snippets do
  let!(:user) { create(:user) }

  describe 'GET /snippets/' do
    it 'returns snippets available' do
      public_snippet = create(:personal_snippet, :public, author: user)
      private_snippet = create(:personal_snippet, :private, author: user)
      internal_snippet = create(:personal_snippet, :internal, author: user)

      get v3_api("/snippets/", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response.map { |snippet| snippet['id']} ).to contain_exactly(
        public_snippet.id,
        internal_snippet.id,
        private_snippet.id)
      expect(json_response.last).to have_key('web_url')
      expect(json_response.last).to have_key('raw_url')
    end

    it 'hides private snippets from regular user' do
      create(:personal_snippet, :private)

      get v3_api("/snippets/", user)
      expect(response).to have_gitlab_http_status(200)
      expect(json_response.size).to eq(0)
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

    it 'returns all snippets with public visibility from all users' do
      get v3_api("/snippets/public", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response.map { |snippet| snippet['id']} ).to contain_exactly(
        public_snippet.id,
        public_snippet_other.id)
      expect(json_response.map { |snippet| snippet['web_url']} ).to include(
        "http://localhost/snippets/#{public_snippet.id}",
        "http://localhost/snippets/#{public_snippet_other.id}")
      expect(json_response.map { |snippet| snippet['raw_url']} ).to include(
        "http://localhost/snippets/#{public_snippet.id}/raw",
        "http://localhost/snippets/#{public_snippet_other.id}/raw")
    end
  end

  describe 'GET /snippets/:id/raw' do
    let(:snippet) { create(:personal_snippet, author: user) }

    it 'returns raw text' do
      get v3_api("/snippets/#{snippet.id}/raw", user)

      expect(response).to have_gitlab_http_status(200)
      expect(response.content_type).to eq 'text/plain'
      expect(response.body).to eq(snippet.content)
    end

    it 'returns 404 for invalid snippet id' do
      delete v3_api("/snippets/1234", user)

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 Snippet Not Found')
    end
  end

  describe 'POST /snippets/' do
    let(:params) do
      {
        title: 'Test Title',
        file_name: 'test.rb',
        content: 'puts "hello world"',
        visibility_level: Snippet::PUBLIC
      }
    end

    it 'creates a new snippet' do
      expect do
        post v3_api("/snippets/", user), params
      end.to change { PersonalSnippet.count }.by(1)

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['title']).to eq(params[:title])
      expect(json_response['file_name']).to eq(params[:file_name])
    end

    it 'returns 400 for missing parameters' do
      params.delete(:title)

      post v3_api("/snippets/", user), params

      expect(response).to have_gitlab_http_status(400)
    end

    context 'when the snippet is spam' do
      def create_snippet(snippet_params = {})
        post v3_api('/snippets', user), params.merge(snippet_params)
      end

      before do
        allow_any_instance_of(AkismetService).to receive(:spam?).and_return(true)
      end

      context 'when the snippet is private' do
        it 'creates the snippet' do
          expect { create_snippet(visibility_level: Snippet::PRIVATE) }
            .to change { Snippet.count }.by(1)
        end
      end

      context 'when the snippet is public' do
        it 'rejects the shippet' do
          expect { create_snippet(visibility_level: Snippet::PUBLIC) }
            .not_to change { Snippet.count }
          expect(response).to have_gitlab_http_status(400)
        end

        it 'creates a spam log' do
          expect { create_snippet(visibility_level: Snippet::PUBLIC) }
            .to change { SpamLog.count }.by(1)
        end
      end
    end
  end

  describe 'PUT /snippets/:id' do
    let(:other_user) { create(:user) }
    let(:public_snippet) { create(:personal_snippet, :public, author: user) }
    it 'updates snippet' do
      new_content = 'New content'

      put v3_api("/snippets/#{public_snippet.id}", user), content: new_content

      expect(response).to have_gitlab_http_status(200)
      public_snippet.reload
      expect(public_snippet.content).to eq(new_content)
    end

    it 'returns 404 for invalid snippet id' do
      put v3_api("/snippets/1234", user), title: 'foo'

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 Snippet Not Found')
    end

    it "returns 404 for another user's snippet" do
      put v3_api("/snippets/#{public_snippet.id}", other_user), title: 'fubar'

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 Snippet Not Found')
    end

    it 'returns 400 for missing parameters' do
      put v3_api("/snippets/1234", user)

      expect(response).to have_gitlab_http_status(400)
    end
  end

  describe 'DELETE /snippets/:id' do
    let!(:public_snippet) { create(:personal_snippet, :public, author: user) }
    it 'deletes snippet' do
      expect do
        delete v3_api("/snippets/#{public_snippet.id}", user)

        expect(response).to have_gitlab_http_status(204)
      end.to change { PersonalSnippet.count }.by(-1)
    end

    it 'returns 404 for invalid snippet id' do
      delete v3_api("/snippets/1234", user)

      expect(response).to have_gitlab_http_status(404)
      expect(json_response['message']).to eq('404 Snippet Not Found')
    end
  end
end
