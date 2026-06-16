# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::WorkItems::Children, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private, reporters: user) }
  let_it_be(:parent_work_item) { create(:work_item, :issue, project: project) }

  let_it_be(:first_child) { create(:work_item, :task, project: project, title: 'First child') }
  let_it_be(:second_child) { create(:work_item, :task, project: project, title: 'Second child') }
  let_it_be(:closed_child) do
    create(:work_item, :task, project: project, title: 'Closed child', state: :closed)
  end

  before_all do
    create(:parent_link, work_item: first_child, work_item_parent: parent_work_item, relative_position: 100)
    create(:parent_link, work_item: second_child, work_item_parent: parent_work_item, relative_position: 200)
    create(:parent_link, work_item: closed_child, work_item_parent: parent_work_item, relative_position: 300)
  end

  before do
    stub_feature_flags(work_item_rest_api: true)
  end

  shared_examples 'children endpoint' do
    it 'returns children of the parent work item in relative-position order' do
      get api(api_request_path, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to eq([first_child.id, second_child.id, closed_child.id])
      expect(json_response).to all(include('id', 'iid', 'global_id', 'title'))
    end

    it 'returns 404 when the parent work item does not exist' do
      get api(api_request_path.sub("/#{parent_work_item.iid}/", "/#{non_existing_record_iid}/"), user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns forbidden when the feature flag is disabled' do
      stub_feature_flags(work_item_rest_api: false)

      get api(api_request_path, user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    context 'with state filter' do
      it 'returns only opened children when state=opened' do
        get api(api_request_path, user), params: { state: 'opened' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck('id')).to contain_exactly(first_child.id, second_child.id)
      end

      it 'returns only closed children when state=closed' do
        get api(api_request_path, user), params: { state: 'closed' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck('id')).to contain_exactly(closed_child.id)
      end

      it 'rejects invalid state values' do
        get api(api_request_path, user), params: { state: 'invalid' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'with field and feature selection' do
      it 'returns the requested base fields and feature payloads' do
        get api(api_request_path, user), params: { fields: 'reference', features: 'description' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.first).to include(
          'id' => first_child.id,
          'reference' => first_child.to_reference(full: true),
          'features' => a_hash_including('description')
        )
      end
    end

    context 'when a child is not readable by the current user' do
      let_it_be(:other_project) { create(:project, :private) }
      let_it_be(:hidden_child) { create(:work_item, :task, project: other_project, title: 'Hidden') }

      before_all do
        create(:parent_link, work_item: hidden_child, work_item_parent: parent_work_item, relative_position: 50)
      end

      it 'omits the unreadable child from the response' do
        get api(api_request_path, user)

        expect(response).to have_gitlab_http_status(:ok)
        ids = json_response.pluck('id')
        expect(ids).not_to include(hidden_child.id)
        expect(ids).to include(first_child.id, second_child.id, closed_child.id)
      end
    end
  end

  describe 'GET /projects/:id/-/work_items/:work_item_iid/children' do
    let(:api_request_path) { "/projects/#{project.id}/-/work_items/#{parent_work_item.iid}/children" }

    it_behaves_like 'children endpoint'

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api(api_request_path, personal_access_token: pat)
      end
    end

    it 'returns forbidden when the user cannot read the parent' do
      other_user = create(:user)

      get api(api_request_path, other_user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'does not issue N+1 queries when more children are added' do
      # Have the baseline already include a child in a sibling project. Adding the next child
      # in that same sibling project then doesn't trigger any new project policy loads
      sibling_project = create(:project, :private, reporters: user)
      baseline_sibling_child = create(:work_item, :task, project: sibling_project)
      create(:parent_link, work_item: baseline_sibling_child, work_item_parent: parent_work_item,
        relative_position: 350)

      # First-time lazy writes settle on the warmup so the baseline isn't skewed.
      get api(api_request_path, user)

      baseline = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        get api(api_request_path, user)
      end

      extra_child = create(:work_item, :task, project: sibling_project)
      create(:parent_link, work_item: extra_child, work_item_parent: parent_work_item, relative_position: 400)

      # Settle any first-touch costs for users / preferences materialized above.
      get api(api_request_path, user)

      expect { get api(api_request_path, user) }.to issue_same_number_of_queries_as(baseline)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to include(extra_child.id)
    end
  end

  describe 'GET /namespaces/:id/-/work_items/:work_item_iid/children' do
    let(:api_request_path) do
      "/namespaces/#{CGI.escape(project.project_namespace.full_path)}/-/work_items/#{parent_work_item.iid}/children"
    end

    it_behaves_like 'children endpoint'

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api(api_request_path, personal_access_token: pat)
      end
    end
  end
end
