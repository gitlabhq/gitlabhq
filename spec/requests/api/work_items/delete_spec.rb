# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::WorkItems::Delete, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:owner) { create(:user) }
  let_it_be(:group) { create(:group, :private, reporters: user, owners: owner) }
  let_it_be(:project) { create(:project, :private, group: group) }

  before do
    stub_feature_flags(work_item_rest_api: owner)
  end

  shared_examples 'work item delete endpoint' do
    context 'when the work item exists' do
      it 'deletes the work item and returns 204' do
        delete api(api_request_path, owner)

        expect(response).to have_gitlab_http_status(:no_content)
        expect(WorkItem.find_by_id(work_item.id)).to be_nil
      end
    end

    context 'when the delete service returns an error' do
      it 'returns 422' do
        allow_next_instance_of(::WorkItems::DeleteService) do |service|
          allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'deletion failed'))
        end

        delete api(api_request_path, owner)

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    context 'when the work item does not exist' do
      it 'returns 404' do
        delete api("#{base_path}/#{non_existing_record_iid}", owner)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the user does not have permission to delete' do
      it 'returns 403' do
        stub_feature_flags(work_item_rest_api: user)

        delete api(api_request_path, user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when unauthenticated' do
      it 'returns 401' do
        delete api(api_request_path)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(work_item_rest_api: false)
      end

      it 'returns 403' do
        delete api(api_request_path, owner)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE /namespaces/:id/-/work_items/:work_item_iid' do
    let_it_be(:work_item) { create(:work_item, project: project) }

    let(:base_path) { "/namespaces/#{CGI.escape(project.project_namespace.full_path)}/-/work_items" }
    let(:api_request_path) { "#{base_path}/#{work_item.iid}" }

    it_behaves_like 'work item delete endpoint'

    context 'when the namespace is a user namespace' do
      it 'returns 404' do
        delete api("/namespaces/#{CGI.escape(owner.username)}/-/work_items/1", owner)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the namespace is a group namespace' do
      it 'returns 404 when the work item does not exist' do
        delete api("/namespaces/#{CGI.escape(group.full_path)}/-/work_items/#{non_existing_record_iid}", owner)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /projects/:id/-/work_items/:work_item_iid' do
    let_it_be(:work_item) { create(:work_item, project: project) }

    let(:base_path) { "/projects/#{project.id}/-/work_items" }
    let(:api_request_path) { "#{base_path}/#{work_item.iid}" }

    it_behaves_like 'work item delete endpoint'
  end

  describe 'DELETE /groups/:id/-/work_items/:work_item_iid' do
    it 'returns not found for groups without epics license' do
      delete api("/groups/#{group.id}/-/work_items/1", owner)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
