# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::WorkItems::Create, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :private, reporters: user) }
  let_it_be(:project) { create(:project, :private, :repository, group: group, reporters: user) }

  let_it_be(:task_type) { ::WorkItems::TypesFramework::Provider.new.find_by_base_type(:task) }
  let_it_be(:issue_type) { ::WorkItems::TypesFramework::Provider.new.find_by_base_type(:issue) }

  before do
    stub_feature_flags(work_item_rest_api: user)
  end

  shared_examples 'work item create endpoint' do
    context 'with minimum required params' do
      it 'creates a work item and returns 201' do
        post api(api_request_path, user), params: {
          title: 'New task',
          work_item_type_name: 'task'
        }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['title']).to eq('New task')
        expect(json_response['id']).to be_present
        expect(json_response['iid']).to be_present
        expect(json_response['global_id']).to be_present
      end
    end

    context 'with work_item_type_id' do
      it 'creates a work item by type numeric ID' do
        post api(api_request_path, user), params: {
          title: 'Task by type id',
          work_item_type_id: task_type.id
        }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['title']).to eq('Task by type id')
      end
    end

    context 'with description feature' do
      it 'creates a work item with description and returns it in the response' do
        post api(api_request_path, user), params: {
          title: 'Described task',
          work_item_type_name: 'task',
          features: { description: { description: 'Some description text' } }
        }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response.dig('features', 'description', 'description')).to eq('Some description text')
        expect(WorkItem.find(json_response['id']).description).to eq('Some description text')
      end
    end

    context 'with assignees feature' do
      it 'creates a work item with assignees and returns them in the response' do
        post api(api_request_path, user), params: {
          title: 'Assigned task',
          work_item_type_name: 'task',
          features: { assignees: { assignee_ids: [user.id] } }
        }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response.dig('features', 'assignees')).to contain_exactly(
          a_hash_including('id' => user.id)
        )
        expect(WorkItem.find(json_response['id']).assignee_ids).to contain_exactly(user.id)
      end
    end

    context 'with labels feature' do
      it 'creates a work item with labels and returns them in the response' do
        post api(api_request_path, user), params: {
          title: 'Labelled task',
          work_item_type_name: 'task',
          features: { labels: { label_ids: [label.id] } }
        }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response.dig('features', 'labels', 'labels')).to contain_exactly(
          a_hash_including('title' => label.title)
        )
        expect(WorkItem.find(json_response['id']).label_ids).to contain_exactly(label.id)
      end
    end

    context 'with milestone feature' do
      it 'creates a work item with milestone and returns it in the response' do
        post api(api_request_path, user), params: {
          title: 'Milestone task',
          work_item_type_name: 'task',
          features: { milestone: { milestone_id: milestone.id } }
        }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response.dig('features', 'milestone', 'title')).to eq(milestone.title)
        expect(WorkItem.find(json_response['id']).milestone).to eq(milestone)
      end
    end

    context 'with start_and_due_date feature' do
      it 'creates a work item with dates and returns them in the response' do
        post api(api_request_path, user), params: {
          title: 'Dated task',
          work_item_type_name: 'task',
          features: { start_and_due_date: { start_date: '2026-03-20', due_date: '2026-04-01' } }
        }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response.dig('features', 'start_and_due_date')).to include(
          'start_date' => '2026-03-20',
          'due_date' => '2026-04-01'
        )
        work_item = WorkItem.find(json_response['id'])
        expect(work_item.start_date.to_s).to eq('2026-03-20')
        expect(work_item.due_date.to_s).to eq('2026-04-01')
      end
    end

    context 'with confidential param' do
      it 'creates a confidential work item' do
        post api(api_request_path, user), params: {
          title: 'Secret task',
          work_item_type_name: 'task',
          confidential: true
        }

        expect(response).to have_gitlab_http_status(:created)
        expect(WorkItem.find(json_response['id'])).to be_confidential
      end
    end

    context 'with hierarchy feature (parent work item)' do
      it 'creates a work item with a parent using the parent ID' do
        post api(api_request_path, user), params: {
          title: 'Child task',
          work_item_type_name: 'task',
          features: { hierarchy: { parent_id: parent_work_item.id } }
        }

        expect(response).to have_gitlab_http_status(:created)
        expect(parent_work_item.reload.work_item_children).to include(WorkItem.find(json_response['id']))
      end
    end

    context 'with linked_items feature' do
      it 'creates a work item with linked items' do
        post api(api_request_path, user), params: {
          title: 'Linked task',
          work_item_type_name: 'task',
          features: { linked_items: { work_items_ids: [linked_work_item.id], link_type: 'relates_to' } }
        }

        expect(response).to have_gitlab_http_status(:created)
        new_work_item = WorkItem.find(json_response['id'])
        expect(new_work_item.related_issues(user)).to include(linked_work_item)
      end
    end

    context 'with crm_contacts feature' do
      it 'creates a work item with CRM contacts' do
        contact = create(:contact, group: project.group)

        post api(api_request_path, user), params: {
          title: 'CRM task',
          work_item_type_name: 'task',
          features: { crm_contacts: { contact_ids: [contact.id] } }
        }

        expect(response).to have_gitlab_http_status(:created)
        new_work_item = WorkItem.find(json_response['id'])
        expect(new_work_item.customer_relations_contacts).to include(contact)
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(work_item_rest_api: false)
      end

      it 'returns 403' do
        post api(api_request_path, user), params: { title: 'New task', work_item_type_name: 'task' }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when unauthenticated' do
      it 'returns 401' do
        post api(api_request_path), params: { title: 'New task', work_item_type_name: 'task' }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when user does not have permission' do
      let_it_be(:other_user) { create(:user) }

      before do
        stub_feature_flags(work_item_rest_api: other_user)
      end

      it 'returns 404 for private resources' do
        post api(api_request_path, other_user), params: { title: 'New task', work_item_type_name: 'task' }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with missing title' do
      it 'returns 400' do
        post api(api_request_path, user), params: { work_item_type_name: 'task' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'with missing work item type' do
      it 'returns 400' do
        post api(api_request_path, user), params: { title: 'New task' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'with nonexistent work item type name' do
      it 'returns 400 due to invalid type name value' do
        post api(api_request_path, user), params: {
          title: 'New task',
          work_item_type_name: 'nonexistent_type'
        }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'with nonexistent work item type id' do
      it 'returns 404' do
        post api(api_request_path, user), params: {
          title: 'New task',
          work_item_type_id: non_existing_record_id
        }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST /namespaces/:id/-/work_items' do
    context 'when namespace is a project namespace' do
      let(:api_request_path) { "/namespaces/#{CGI.escape(project.project_namespace.full_path)}/-/work_items" }
      let(:label) { create(:label, project: project) }
      let(:milestone) { create(:milestone, project: project) }
      let(:parent_work_item) { create(:work_item, :issue, project: project) }
      let(:linked_work_item) { create(:work_item, project: project) }

      it_behaves_like 'work item create endpoint'

      it_behaves_like 'authorizing granular token permissions', :create_work_item do
        let(:boundary_object) { project }
        let(:request) do
          post api("/namespaces/#{CGI.escape(project.project_namespace.full_path)}/-/work_items",
            personal_access_token: pat),
            params: { title: 'New task', work_item_type_name: 'task' }
        end
      end
    end

    context 'when namespace is a group namespace' do
      it 'delegates to group work item creation' do
        post api("/namespaces/#{CGI.escape(group.full_path)}/-/work_items", user), params: {
          title: 'Group task',
          work_item_type_name: 'task'
        }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when namespace is a user namespace' do
      let_it_be(:user_namespace) { create(:namespace, owner: user) }

      it 'returns 404' do
        post api("/namespaces/#{CGI.escape(user_namespace.full_path)}/-/work_items", user), params: {
          title: 'New task',
          work_item_type_name: 'task'
        }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST /projects/:id/-/work_items' do
    let(:api_request_path) { "/projects/#{project.id}/-/work_items" }
    let(:label) { create(:label, project: project) }
    let(:milestone) { create(:milestone, project: project) }
    let(:parent_work_item) { create(:work_item, :issue, project: project) }
    let(:linked_work_item) { create(:work_item, project: project) }

    it_behaves_like 'work item create endpoint'

    it_behaves_like 'authorizing granular token permissions', :create_work_item do
      let(:boundary_object) { project }
      let(:request) do
        post api("/projects/#{project.id}/-/work_items", personal_access_token: pat),
          params: { title: 'New task', work_item_type_name: 'task' }
      end
    end

    context 'with created_at param' do
      let_it_be(:owner) { create(:user) }

      before_all do
        project.add_owner(owner)
      end

      before do
        stub_feature_flags(work_item_rest_api: owner)
      end

      it 'creates a work item with the specified created_at timestamp' do
        post api(api_request_path, owner), params: {
          title: 'Timestamped task',
          work_item_type_name: 'task',
          created_at: '2026-01-01T00:00:00Z',
          fields: 'created_at'
        }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['created_at']).to start_with('2026-01-01')
      end
    end

    it 'supports URL-encoded project full paths' do
      post api("/projects/#{CGI.escape(project.full_path)}/-/work_items", user), params: {
        title: 'Full path task',
        work_item_type_name: 'task'
      }

      expect(response).to have_gitlab_http_status(:created)
    end

    context 'with hierarchy feature (parent work item)' do
      it 'returns unprocessable_entity when the parent work item belongs to a different resource' do
        other_project = create(:project, :private)
        other_parent = create(:work_item, :issue, project: other_project)

        post api(api_request_path, user), params: {
          title: 'Child task',
          work_item_type_name: 'task',
          features: { hierarchy: { parent_id: other_parent.id } }
        }

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end

      it 'returns not_found when the parent work item does not exist' do
        post api(api_request_path, user), params: {
          title: 'Child task',
          work_item_type_name: 'task',
          features: { hierarchy: { parent_id: non_existing_record_id } }
        }

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to include("Parent work item #{non_existing_record_id}")
      end
    end

    context 'when feature is not supported by the work item type' do
      it 'returns 400' do
        type_double = instance_double(
          WorkItems::TypesFramework::SystemDefined::Type,
          name: 'Task',
          widget_classes: []
        )
        allow_next_instance_of(WorkItems::TypesFramework::Provider) do |provider|
          allow(provider).to receive(:find_by_base_type).and_return(type_double)
        end

        post api(api_request_path, user), params: {
          title: 'Task',
          work_item_type_name: 'task',
          features: { description: { description: 'Some text' } }
        }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to include('not supported')
        expect(json_response['unsupported_widgets']).to match_array(['description_widget'])
      end
    end

    context 'with assignees feature' do
      it 'returns a validation error when more than 30 assignee IDs are provided' do
        post api(api_request_path, user), params: {
          title: 'Assigned task',
          work_item_type_name: 'task',
          features: { assignees: { assignee_ids: Array.new(31, user.id) } }
        }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to include('must contain at most 30 items')
      end
    end

    context 'with labels feature' do
      it 'returns a validation error when more than 30 label IDs are provided' do
        post api(api_request_path, user), params: {
          title: 'Labelled task',
          work_item_type_name: 'task',
          features: { labels: { label_ids: Array.new(31, label.id) } }
        }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to include('must contain at most 30 items')
      end
    end

    context 'with linked_items feature' do
      it 'returns a validation error when more than 30 work item IDs are provided' do
        post api(api_request_path, user), params: {
          title: 'Linked task',
          work_item_type_name: 'task',
          features: { linked_items: { work_items_ids: Array.new(31, linked_work_item.id) } }
        }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to include('must contain at most 30 items')
      end
    end
  end

  describe 'POST /groups/:id/-/work_items' do
    let(:api_request_path) { "/groups/#{group.id}/-/work_items" }
    let(:label) { create(:group_label, group: group) }
    let(:milestone) { create(:milestone, group: group) }

    context 'when epics license is not enabled' do
      # We need to move just definitions of EE system defined types to CE and
      # keep the implementations EE
      let_it_be(:epic_type_id) { 8 }

      it 'returns forbidden for epic type' do
        post api(api_request_path, user), params: {
          title: 'Group epic',
          work_item_type_id: epic_type_id
        }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when work item type is not allowed for groups' do
      it 'returns an error for task type in groups' do
        post api(api_request_path, user), params: {
          title: 'Group task',
          work_item_type_name: 'task'
        }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
