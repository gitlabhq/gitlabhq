require 'rails_helper'

describe API::API, api: true do
  include ApiHelpers

  describe 'GET /projects/:project_id/snippets/' do
    it 'all snippets available to team member' do
      project = create(:project, :public)
      user = create(:user)
      project.team << [user, :developer]
      public_snippet = create(:project_snippet, :public, project: project)
      internal_snippet = create(:project_snippet, :internal, project: project)
      private_snippet = create(:project_snippet, :private, project: project)

      get api("/projects/#{project.id}/snippets/", user)

      expect(response.status).to eq(200)
      expect(json_response.size).to eq(3)
      expect(json_response.map{ |snippet| snippet['id']} ).to include(public_snippet.id, internal_snippet.id, private_snippet.id)
    end

    it 'hides private snippets from regular user' do
      project = create(:project, :public)
      user = create(:user)
      create(:project_snippet, :private, project: project)

      get api("/projects/#{project.id}/snippets/", user)
      expect(response.status).to eq(200)
      expect(json_response.size).to eq(0)
    end
  end

  describe 'POST /projects/:project_id/snippets/' do
    it 'creates a new snippet' do
      admin = create(:admin)
      project = create(:project)
      params = {
        title: 'Test Title',
        file_name: 'test.rb',
        code: 'puts "hello world"',
        visibility_level: Gitlab::VisibilityLevel::PUBLIC
      }

      post api("/projects/#{project.id}/snippets/", admin), params

      expect(response.status).to eq(201)
      snippet = ProjectSnippet.find(json_response['id'])
      expect(snippet.content).to eq(params[:code])
      expect(snippet.title).to eq(params[:title])
      expect(snippet.file_name).to eq(params[:file_name])
      expect(snippet.visibility_level).to eq(params[:visibility_level])
    end
  end

  describe 'PUT /projects/:project_id/snippets/:id/' do
    it 'updates snippet' do
      admin = create(:admin)
      snippet = create(:project_snippet, author: admin)
      new_content = 'New content'

      put api("/projects/#{snippet.project.id}/snippets/#{snippet.id}/", admin), code: new_content

      expect(response.status).to eq(200)
      snippet.reload
      expect(snippet.content).to eq(new_content)
    end
  end

  describe 'DELETE /projects/:project_id/snippets/:id/' do
    it 'deletes snippet' do
      admin = create(:admin)
      snippet = create(:project_snippet, author: admin)

      delete api("/projects/#{snippet.project.id}/snippets/#{snippet.id}/", admin)

      expect(response.status).to eq(200)
    end
  end

  describe 'GET /projects/:project_id/snippets/:id/raw' do
    it 'returns raw text' do
      admin = create(:admin)
      snippet = create(:project_snippet, author: admin)

      get api("/projects/#{snippet.project.id}/snippets/#{snippet.id}/raw", admin)

      expect(response.status).to eq(200)
      expect(response.content_type).to eq 'text/plain'
      expect(response.body).to eq(snippet.content)
    end
  end
end
