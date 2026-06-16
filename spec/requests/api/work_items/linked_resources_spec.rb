# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::WorkItems::LinkedResources, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private, reporters: user) }
  let_it_be(:work_item) { create(:work_item, :issue, project: project) }

  # A unique index on (issue_id, issue_status) allows at most one added meeting per work item.
  let_it_be(:added_meeting) do
    create(:zoom_meeting, issue: work_item, project: project, url: 'https://zoom.us/j/111')
  end

  let_it_be(:removed_meeting) do
    create(:zoom_meeting, :removed_from_issue, issue: work_item, project: project, url: 'https://zoom.us/j/333')
  end

  before do
    stub_feature_flags(work_item_rest_api: user)
  end

  shared_examples 'linked_resources endpoint' do
    it 'returns only the resources added to the work item', :aggregate_failures do
      get api(api_request_path, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to all(include('url'))
      expect(json_response.pluck('url')).to contain_exactly(added_meeting.url)
    end

    it 'returns 404 when the work item does not exist' do
      get api(api_request_path.sub("/#{work_item.iid}/", "/#{non_existing_record_iid}/"), user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns not_found when the user cannot read the work item' do
      get api(api_request_path, create(:user))

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns forbidden when the feature flag is disabled' do
      stub_feature_flags(work_item_rest_api: false)

      get api(api_request_path, user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'paginates the response', :aggregate_failures do
      get api(api_request_path, user), params: { per_page: 1 }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.size).to eq(1)
      expect(response.headers['X-Total']).to eq('1')
    end
  end

  describe 'GET /projects/:id/-/work_items/:work_item_iid/linked_resources' do
    let(:api_request_path) { "/projects/#{project.id}/-/work_items/#{work_item.iid}/linked_resources" }

    it_behaves_like 'linked_resources endpoint'

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api(api_request_path, personal_access_token: pat)
      end
    end
  end

  describe 'GET /namespaces/:id/-/work_items/:work_item_iid/linked_resources' do
    let(:api_request_path) do
      "/namespaces/#{CGI.escape(project.project_namespace.full_path)}/-/work_items/#{work_item.iid}/linked_resources"
    end

    it_behaves_like 'linked_resources endpoint'

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api(api_request_path, personal_access_token: pat)
      end
    end
  end
end
