# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::WorkItems::LinkedItems, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private, reporters: user) }
  let_it_be(:parent_work_item) { create(:work_item, :issue, project: project) }

  let_it_be(:linked_task_a) { create(:work_item, :task, project: project, title: 'Task A') }
  let_it_be(:linked_task_b) { create(:work_item, :task, project: project, title: 'Task B') }
  let_it_be(:linked_closed_task) do
    create(:work_item, :task, project: project, title: 'Closed task', state: :closed)
  end

  let_it_be(:link_a) { create(:work_item_link, source: parent_work_item, target: linked_task_a) }
  let_it_be(:link_b) { create(:work_item_link, source: parent_work_item, target: linked_task_b) }
  let_it_be(:link_closed) { create(:work_item_link, source: parent_work_item, target: linked_closed_task) }

  before do
    stub_feature_flags(work_item_rest_api: user)
  end

  shared_examples 'linked items endpoint' do
    it 'returns linked items with link metadata, ordered by link id desc', :aggregate_failures do
      get api(api_request_path, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to eq([linked_closed_task.id, linked_task_b.id, linked_task_a.id])
      expect(json_response).to all(include('id', 'iid', 'global_id', 'title',
        'link_id', 'link_type', 'link_created_at', 'link_updated_at'))
      expect(json_response.first).to include(
        'link_id' => link_closed.id,
        'link_type' => 'relates_to'
      )
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
      it 'returns only opened linked items when state=opened' do
        get api(api_request_path, user), params: { state: 'opened' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck('id')).to contain_exactly(linked_task_a.id, linked_task_b.id)
      end

      it 'returns only closed linked items when state=closed' do
        get api(api_request_path, user), params: { state: 'closed' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck('id')).to contain_exactly(linked_closed_task.id)
      end

      it 'rejects invalid state values' do
        get api(api_request_path, user), params: { state: 'invalid' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'with link_type filter' do
      it 'returns relates_to linked items when link_type=relates_to' do
        get api(api_request_path, user), params: { link_type: 'relates_to' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck('id'))
          .to contain_exactly(linked_task_a.id, linked_task_b.id, linked_closed_task.id)
        expect(json_response).to all(include('link_type' => 'relates_to'))
      end

      it 'rejects link types not in the available list' do
        get api(api_request_path, user), params: { link_type: 'invalid' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'with field and feature selection' do
      it 'returns the requested base fields and feature payloads alongside link metadata', :aggregate_failures do
        get api(api_request_path, user), params: { fields: 'reference,namespace', features: 'description' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.first).to include(
          'reference' => an_instance_of(String),
          'namespace' => a_hash_including(
            'id' => project.project_namespace.id,
            'full_path' => project.project_namespace.full_path
          ),
          'features' => a_hash_including('description'),
          'link_id' => an_instance_of(Integer),
          'link_type' => 'relates_to'
        )
      end
    end

    context 'when a linked item is not readable by the current user' do
      let_it_be(:other_project) { create(:project, :private) }
      let_it_be(:hidden_task) { create(:work_item, :task, project: other_project, title: 'Hidden') }
      let_it_be(:hidden_link) { create(:work_item_link, source: parent_work_item, target: hidden_task) }

      it 'omits the unreadable linked item from the response', :aggregate_failures do
        get api(api_request_path, user)

        expect(response).to have_gitlab_http_status(:ok)
        ids = json_response.pluck('id')
        expect(ids).not_to include(hidden_task.id)
        expect(ids).to include(linked_task_a.id, linked_task_b.id, linked_closed_task.id)
      end
    end
  end

  describe 'GET /projects/:id/-/work_items/:work_item_iid/linked_items' do
    let(:api_request_path) { "/projects/#{project.id}/-/work_items/#{parent_work_item.iid}/linked_items" }

    it_behaves_like 'linked items endpoint'

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api(api_request_path, personal_access_token: pat)
      end
    end

    it 'returns not_found when the user cannot read the parent' do
      other_user = create(:user)

      get api(api_request_path, other_user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns the inverse link_type when the parent is the link target', :aggregate_failures do
      target_parent = create(:work_item, :issue, project: project)
      source_task = create(:work_item, :task, project: project)
      inverse_link = create(:work_item_link, source: source_task, target: target_parent)

      get api("/projects/#{project.id}/-/work_items/#{target_parent.iid}/linked_items", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.first).to include(
        'id' => source_task.id,
        'link_id' => inverse_link.id,
        'link_type' => 'relates_to'
      )
    end

    it 'does not issue N+1 queries when more linked items are added' do
      # A baseline link in a sibling project ensures the policy preloader is used once before measurement so
      # per-project policy load doesn't appear as an extra query.
      sibling_project = create(:project, :private, reporters: user)
      baseline_sibling = create(:work_item, :task, project: sibling_project)
      create(:work_item_link, source: parent_work_item, target: baseline_sibling)

      get api(api_request_path, user)

      baseline = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        get api(api_request_path, user)
      end

      extra_target = create(:work_item, :task, project: sibling_project)
      create(:work_item_link, source: parent_work_item, target: extra_target)

      get api(api_request_path, user)

      expect { get api(api_request_path, user) }.to issue_same_number_of_queries_as(baseline)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to include(extra_target.id)
    end
  end

  describe 'GET /namespaces/:id/-/work_items/:work_item_iid/linked_items' do
    let(:api_request_path) do
      "/namespaces/#{CGI.escape(project.project_namespace.full_path)}" \
        "/-/work_items/#{parent_work_item.iid}/linked_items"
    end

    it_behaves_like 'linked items endpoint'

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api(api_request_path, personal_access_token: pat)
      end
    end
  end
end
