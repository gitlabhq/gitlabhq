# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectTemplates, feature_category: :source_code_management do
  let_it_be(:public_project) { create(:project, :public, :repository, create_templates: :merge_request, path: 'path.with.dot') }
  let_it_be(:private_project) { create(:project, :private, :repository, create_templates: :issue) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:guest) { create(:user) }

  let(:url_encoded_path) { "#{public_project.namespace.path}%2F#{public_project.path}" }

  before do
    stub_feature_flags(remove_monitor_metrics: false)
    private_project.add_developer(reporter)
    private_project.add_guest(guest)
  end

  shared_examples 'accepts project paths with dots' do
    it do
      subject

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe 'GET /projects/:id/templates/:type' do
    using RSpec::Parameterized::TableSyntax

    where(:type, :key) do
      'dockerfiles' | 'Binary'
      'gitignores' | 'Actionscript'
      'gitlab_ci_ymls' | 'Android'
      'licenses' | '0bsd'
    end

    with_them do
      it "return the response" do
        get api("/projects/#{public_project.id}/templates/#{type}")
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(response).to match_response_schema('public_api/v4/template_list')
        expect(json_response).to satisfy_one { |template| template['key'] == key }
      end
    end

    it_behaves_like 'accepts project paths with dots' do
      subject { get api("/projects/#{url_encoded_path}/templates/dockerfiles") }
    end

    it 'returns issue templates' do
      get api("/projects/#{private_project.id}/templates/issues", reporter)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(response).to match_response_schema('public_api/v4/template_list')
      expect(json_response.map { |t| t['key'] }).to match_array(%w[bug feature_proposal template_test (test)])
    end

    it 'returns merge request templates' do
      get api("/projects/#{public_project.id}/templates/merge_requests")

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(response).to match_response_schema('public_api/v4/template_list')
      expect(json_response.map { |t| t['key'] }).to match_array(%w[bug feature_proposal template_test (test)])
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
      get api("/projects/#{private_project.id}/templates/licenses", reporter)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/template_list')
    end

    context 'when a guest has no permission to a template' do
      it 'denies access to the dockerfile' do
        get api("/projects/#{private_project.id}/templates/dockerfiles", guest)

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to eq("403 Forbidden - Your current role does not have the required permissions to access the dockerfiles template. Contact your project administrator for assistance.")
      end

      it 'denies access to the gitignore' do
        get api("/projects/#{private_project.id}/templates/gitignores", guest)

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to eq("403 Forbidden - Your current role does not have the required permissions to access the gitignores template. Contact your project administrator for assistance.")
      end

      it 'denies access to the gitlab_ci_yml' do
        get api("/projects/#{private_project.id}/templates/gitlab_ci_ymls", guest)

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to eq("403 Forbidden - Your current role does not have the required permissions to access the gitlab_ci_ymls template. Contact your project administrator for assistance.")
      end

      it 'denies access to the license' do
        get api("/projects/#{private_project.id}/templates/licenses", guest)

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to eq("403 Forbidden - Your current role does not have the required permissions to access the licenses template. Contact your project administrator for assistance.")
      end

      it 'denies access to the merge request' do
        get api("/projects/#{private_project.id}/templates/merge_requests", guest)

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to eq("403 Forbidden - Your current role does not have the required permissions to access the merge_requests template. Contact your project administrator for assistance.")
      end
    end

    context 'when a guest has permission to an issues template' do
      it 'returns an issue template' do
        get api("/projects/#{private_project.id}/templates/issues", guest)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(response).to match_response_schema('public_api/v4/template_list')
        expect(json_response.map { |t| t['key'] }).to match_array(%w[bug feature_proposal template_test (test)])
      end
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

    it 'returns a specific license' do
      get api("/projects/#{public_project.id}/templates/licenses/mit")

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/license')
    end

    it 'returns a specific issue template' do
      get api("/projects/#{private_project.id}/templates/issues/bug", reporter)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/template')
      expect(json_response['name']).to eq('bug')
      expect(json_response['content']).to eq('something valid')
    end

    context 'when issue template uses parentheses' do
      it 'returns a specific issue template' do
        get api("/projects/#{private_project.id}/templates/issues/(test)", reporter)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/template')
        expect(json_response['name']).to eq('(test)')
        expect(json_response['content']).to eq('parentheses')
      end
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
      get api("/projects/#{private_project.id}/templates/licenses/mit", reporter)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/license')
    end

    it_behaves_like 'accepts project paths with dots' do
      subject { get api("/projects/#{url_encoded_path}/templates/gitlab_ci_ymls/Android") }
    end

    shared_examples 'path traversal attempt' do |template_type|
      before do
        # TODO: remove spec once the feature flag is removed
        # https://gitlab.com/gitlab-org/gitlab/-/issues/415460
        stub_feature_flags(check_path_traversal_middleware_reject_requests: false)
      end

      it 'rejects invalid filenames' do
        get api("/projects/#{public_project.id}/templates/#{template_type}/%2e%2e%2fPython%2ea")

        expect(response).to have_gitlab_http_status(:internal_server_error)
      end
    end

    TemplateFinder::VENDORED_TEMPLATES.each do |template_type, _|
      it_behaves_like 'path traversal attempt', template_type
    end

    context 'when a guest has no permission to a template' do
      it 'denies access to the dockerfile' do
        get api("/projects/#{private_project.id}/templates/dockerfiles/Binary", guest)

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to eq("403 Forbidden - Your current role does not have the required permissions to access the dockerfiles template. Contact your project administrator for assistance.")
      end

      it 'denies access to the gitignore' do
        get api("/projects/#{private_project.id}/templates/gitignores/Actionscript", guest)

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to eq("403 Forbidden - Your current role does not have the required permissions to access the gitignores template. Contact your project administrator for assistance.")
      end

      it 'denies access to the gitlab_ci_yml' do
        get api("/projects/#{private_project.id}/templates/gitlab_ci_ymls/Android", guest)

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to eq("403 Forbidden - Your current role does not have the required permissions to access the gitlab_ci_ymls template. Contact your project administrator for assistance.")
      end

      it 'denies access to the license' do
        get api("/projects/#{private_project.id}/templates/licenses/mit", guest)

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to eq("403 Forbidden - Your current role does not have the required permissions to access the licenses template. Contact your project administrator for assistance.")
      end

      it 'denies access to the merge request' do
        get api("/projects/#{private_project.id}/templates/merge_requests/feature_proposal", guest)

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to eq("403 Forbidden - Your current role does not have the required permissions to access the merge_requests template. Contact your project administrator for assistance.")
      end
    end

    context 'when a guest has permission to an issues template' do
      it 'returns an issue template' do
        get api("/projects/#{private_project.id}/templates/issues/bug", guest)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/template')
        expect(json_response['name']).to eq('bug')
        expect(json_response['content']).to eq('something valid')
      end
    end
  end

  describe 'GET /projects/:id/templates/licenses/:key' do
    it 'fills placeholders in the license' do
      get api("/projects/#{public_project.id}/templates/licenses/agpl-3.0"),
        params: { project: 'Project Placeholder', fullname: 'Fullname Placeholder' }

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
