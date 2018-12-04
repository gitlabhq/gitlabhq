require 'spec_helper'

describe API::ProjectTemplates do
  let(:public_project) { create(:project, :public) }
  let(:private_project) { create(:project, :private) }
  let(:developer) { create(:user) }

  before do
    private_project.add_developer(developer)
  end

  describe 'GET /projects/:id/templates/:type' do
    it 'returns dockerfiles' do
      get api("/projects/#{public_project.id}/templates/dockerfiles")

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(response).to match_response_schema('public_api/v4/template_list')
      expect(json_response).to satisfy_one { |template| template['key'] == 'Binary' }
    end

    it 'returns gitignores' do
      get api("/projects/#{public_project.id}/templates/gitignores")

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(response).to match_response_schema('public_api/v4/template_list')
      expect(json_response).to satisfy_one { |template| template['key'] == 'Actionscript' }
    end

    it 'returns gitlab_ci_ymls' do
      get api("/projects/#{public_project.id}/templates/gitlab_ci_ymls")

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(response).to match_response_schema('public_api/v4/template_list')
      expect(json_response).to satisfy_one { |template| template['key'] == 'Android' }
    end

    it 'returns licenses' do
      get api("/projects/#{public_project.id}/templates/licenses")

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(response).to match_response_schema('public_api/v4/template_list')
      expect(json_response).to satisfy_one { |template| template['key'] == 'mit' }
    end

    it 'returns 400 for an unknown template type' do
      get api("/projects/#{public_project.id}/templates/unknown")

      expect(response).to have_gitlab_http_status(400)
    end

    it 'denies access to an anonymous user on a private project' do
      get api("/projects/#{private_project.id}/templates/licenses")

      expect(response).to have_gitlab_http_status(404)
    end

    it 'permits access to a developer on a private project' do
      get api("/projects/#{private_project.id}/templates/licenses", developer)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to match_response_schema('public_api/v4/template_list')
    end
  end

  describe 'GET /projects/:id/templates/licenses' do
    it 'returns key and name for the listed licenses' do
      get api("/projects/#{public_project.id}/templates/licenses")

      expect(response).to have_gitlab_http_status(200)
      expect(response).to match_response_schema('public_api/v4/template_list')
    end
  end

  describe 'GET /projects/:id/templates/:type/:key' do
    it 'returns a specific dockerfile' do
      get api("/projects/#{public_project.id}/templates/dockerfiles/Binary")

      expect(response).to have_gitlab_http_status(200)
      expect(response).to match_response_schema('public_api/v4/template')
      expect(json_response['name']).to eq('Binary')
    end

    it 'returns a specific gitignore' do
      get api("/projects/#{public_project.id}/templates/gitignores/Actionscript")

      expect(response).to have_gitlab_http_status(200)
      expect(response).to match_response_schema('public_api/v4/template')
      expect(json_response['name']).to eq('Actionscript')
    end

    it 'returns a specific gitlab_ci_yml' do
      get api("/projects/#{public_project.id}/templates/gitlab_ci_ymls/Android")

      expect(response).to have_gitlab_http_status(200)
      expect(response).to match_response_schema('public_api/v4/template')
      expect(json_response['name']).to eq('Android')
    end

    it 'returns a specific license' do
      get api("/projects/#{public_project.id}/templates/licenses/mit")

      expect(response).to have_gitlab_http_status(200)
      expect(response).to match_response_schema('public_api/v4/license')
    end

    it 'returns 404 for an unknown specific template' do
      get api("/projects/#{public_project.id}/templates/licenses/unknown")

      expect(response).to have_gitlab_http_status(404)
    end

    it 'denies access to an anonymous user on a private project' do
      get api("/projects/#{private_project.id}/templates/licenses/mit")

      expect(response).to have_gitlab_http_status(404)
    end

    it 'permits access to a developer on a private project' do
      get api("/projects/#{private_project.id}/templates/licenses/mit", developer)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to match_response_schema('public_api/v4/license')
    end
  end

  describe 'GET /projects/:id/templates/licenses/:key' do
    it 'fills placeholders in the license' do
      get api("/projects/#{public_project.id}/templates/licenses/agpl-3.0"),
          project: 'Project Placeholder',
          fullname: 'Fullname Placeholder'

      expect(response).to have_gitlab_http_status(200)
      expect(response).to match_response_schema('public_api/v4/license')

      content = json_response['content']

      expect(content).to include('Project Placeholder')
      expect(content).to include("Copyright (C) #{Time.now.year}  Fullname Placeholder")
    end
  end
end
