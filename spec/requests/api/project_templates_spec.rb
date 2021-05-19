# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectTemplates do
  let_it_be(:public_project) { create(:project, :public, :repository, create_templates: :merge_request, path: 'path.with.dot') }
  let_it_be(:private_project) { create(:project, :private, :repository, create_templates: :issue) }
  let_it_be(:developer) { create(:user) }

  let(:url_encoded_path) { "#{public_project.namespace.path}%2F#{public_project.path}" }

  before do
    private_project.add_developer(developer)
  end

  shared_examples 'accepts project paths with dots' do
    it do
      subject

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe 'GET /projects/:id/templates/:type' do
    it_behaves_like 'accepts project paths with dots' do
      subject { get api("/projects/#{url_encoded_path}/templates/dockerfiles") }
    end

    it 'returns dockerfiles' do
      get api("/projects/#{public_project.id}/templates/dockerfiles")

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(response).to match_response_schema('public_api/v4/template_list')
      expect(json_response).to satisfy_one { |template| template['key'] == 'Binary' }
    end

    it 'returns gitignores' do
      get api("/projects/#{public_project.id}/templates/gitignores")

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(response).to match_response_schema('public_api/v4/template_list')
      expect(json_response).to satisfy_one { |template| template['key'] == 'Actionscript' }
    end

    it 'returns gitlab_ci_ymls' do
      get api("/projects/#{public_project.id}/templates/gitlab_ci_ymls")

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(response).to match_response_schema('public_api/v4/template_list')
      expect(json_response).to satisfy_one { |template| template['key'] == 'Android' }
    end

    it 'returns licenses' do
      get api("/projects/#{public_project.id}/templates/licenses")

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(response).to match_response_schema('public_api/v4/template_list')
      expect(json_response).to satisfy_one { |template| template['key'] == 'mit' }
    end

    it 'returns metrics_dashboard_ymls' do
      get api("/projects/#{public_project.id}/templates/metrics_dashboard_ymls")

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(response).to match_response_schema('public_api/v4/template_list')
      expect(json_response).to satisfy_one { |template| template['key'] == 'Default' }
    end

    it 'returns issue templates' do
      get api("/projects/#{private_project.id}/templates/issues", developer)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(response).to match_response_schema('public_api/v4/template_list')
      expect(json_response.map {|t| t['key']}).to match_array(%w(bug feature_proposal template_test))
    end

    it 'returns merge request templates' do
      get api("/projects/#{public_project.id}/templates/merge_requests")

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(response).to match_response_schema('public_api/v4/template_list')
      expect(json_response.map {|t| t['key']}).to match_array(%w(bug feature_proposal template_test))
    end

    it 'returns 400 for an unknown template type' do
      get api("/projects/#{public_project.id}/templates/unknown")

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'denies access to an anonymous user on a private project' do
      get api("/projects/#{private_project.id}/templates/licenses")

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'permits access to a developer on a private project' do
      get api("/projects/#{private_project.id}/templates/licenses", developer)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/template_list')
    end
  end

  describe 'GET /projects/:id/templates/licenses' do
    it 'returns key and name for the listed licenses' do
      get api("/projects/#{public_project.id}/templates/licenses")

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/template_list')
    end

    it_behaves_like 'accepts project paths with dots' do
      subject { get api("/projects/#{url_encoded_path}/templates/licenses") }
    end
  end

  describe 'GET /projects/:id/templates/:type/:name' do
    it 'returns a specific dockerfile' do
      get api("/projects/#{public_project.id}/templates/dockerfiles/Binary")

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/template')
      expect(json_response['name']).to eq('Binary')
    end

    it 'returns a specific gitignore' do
      get api("/projects/#{public_project.id}/templates/gitignores/Actionscript")

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/template')
      expect(json_response['name']).to eq('Actionscript')
    end

    it 'returns C++ gitignore' do
      get api("/projects/#{public_project.id}/templates/gitignores/C++")

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/template')
      expect(json_response['name']).to eq('C++')
    end

    it 'returns C++ gitignore for URL-encoded names' do
      get api("/projects/#{public_project.id}/templates/gitignores/C%2B%2B")

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/template')
      expect(json_response['name']).to eq('C++')
    end

    it 'returns a specific gitlab_ci_yml' do
      get api("/projects/#{public_project.id}/templates/gitlab_ci_ymls/Android")

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/template')
      expect(json_response['name']).to eq('Android')
    end

    it 'returns a specific metrics_dashboard_yml' do
      get api("/projects/#{public_project.id}/templates/metrics_dashboard_ymls/Default")

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/template')
      expect(json_response['name']).to eq('Default')
    end

    it 'returns a specific license' do
      get api("/projects/#{public_project.id}/templates/licenses/mit")

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/license')
    end

    it 'returns a specific issue template' do
      get api("/projects/#{private_project.id}/templates/issues/bug", developer)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/template')
      expect(json_response['name']).to eq('bug')
      expect(json_response['content']).to eq('something valid')
    end

    it 'returns a specific merge request template' do
      get api("/projects/#{public_project.id}/templates/merge_requests/feature_proposal")

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/template')
      expect(json_response['name']).to eq('feature_proposal')
      expect(json_response['content']).to eq('feature_proposal') # Content is identical to filename here
    end

    it 'returns 404 for an unknown specific template' do
      get api("/projects/#{public_project.id}/templates/licenses/unknown")

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 404 for an unknown issue template' do
      get api("/projects/#{public_project.id}/templates/issues/unknown")

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 404 for an unknown merge request template' do
      get api("/projects/#{public_project.id}/templates/merge_requests/unknown")

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'denies access to an anonymous user on a private project' do
      get api("/projects/#{private_project.id}/templates/licenses/mit")

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'permits access to a developer on a private project' do
      get api("/projects/#{private_project.id}/templates/licenses/mit", developer)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/license')
    end

    it_behaves_like 'accepts project paths with dots' do
      subject { get api("/projects/#{url_encoded_path}/templates/gitlab_ci_ymls/Android") }
    end

    it_behaves_like 'accepts project paths with dots' do
      subject { get api("/projects/#{url_encoded_path}/templates/metrics_dashboard_ymls/Default") }
    end

    shared_examples 'path traversal attempt' do |template_type|
      it 'rejects invalid filenames' do
        get api("/projects/#{public_project.id}/templates/#{template_type}/%2e%2e%2fPython%2ea")

        expect(response).to have_gitlab_http_status(:internal_server_error)
      end
    end

    TemplateFinder::VENDORED_TEMPLATES.each do |template_type, _|
      it_behaves_like 'path traversal attempt', template_type
    end
  end

  describe 'GET /projects/:id/templates/licenses/:key' do
    it 'fills placeholders in the license' do
      get api("/projects/#{public_project.id}/templates/licenses/agpl-3.0"),
          params: {
            project: 'Project Placeholder',
            fullname: 'Fullname Placeholder'
          }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/license')

      content = json_response['content']

      expect(content).to include('Project Placeholder')
      expect(content).to include("Copyright (C) #{Time.now.year}  Fullname Placeholder")
    end

    it_behaves_like 'accepts project paths with dots' do
      subject { get api("/projects/#{url_encoded_path}/templates/licenses/mit") }
    end
  end
end
