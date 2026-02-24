# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::WorkItems, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:editor) { create(:user) }

  let_it_be(:group) { create(:group, :private, reporters: user) }

  let_it_be(:project) do
    create(:project, :private, group: group, reporters: user, skip_disk_validation: true)
  end

  let_it_be(:project_label) { create(:label, project: project, title: 'project-label') }
  let_it_be(:project_milestone) { create(:milestone, project: project, title: 'project-milestone') }
  let_it_be(:project_work_item) do
    create(
      :work_item,
      project: project,
      labels: [project_label],
      milestone: project_milestone,
      description: 'Project work item description'
    )
  end

  let_it_be(:project_work_item2) { create(:work_item, project: project) }

  before do
    stub_feature_flags(work_item_rest_api: user)
  end

  include_context 'with API work items shared helpers'

  describe 'GET /namespaces/:id/-/work_items' do
    context 'when listing project work items' do
      let(:namespace_record) { project.project_namespace }
      let(:primary_work_item) { project_work_item }
      let(:secondary_work_item) { project_work_item2 }
      let(:label) { project_label }
      let(:milestone) { project_milestone }

      it_behaves_like 'work item listing endpoint'

      it_behaves_like 'authorizing granular token permissions', :read_work_item do
        let(:boundary_object) { project }
        let(:request) do
          get api("/namespaces/#{CGI.escape(namespace_record.full_path)}/-/work_items",
            personal_access_token: pat)
        end
      end
    end

    context 'when namespace is not a group or project' do
      let_it_be(:user_namespace) { create(:namespace, owner: user) }

      it 'returns not found' do
        get api("/namespaces/#{CGI.escape(user_namespace.full_path)}/-/work_items", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /projects/:id/-/work_items' do
    let(:namespace_record) { project.project_namespace }
    let(:primary_work_item) { project_work_item }
    let(:secondary_work_item) { project_work_item2 }
    let(:label) { project_label }
    let(:milestone) { project_milestone }

    it_behaves_like 'work item listing endpoint'

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api("/projects/#{project.id}/-/work_items", personal_access_token: pat)
      end
    end
  end

  describe 'GET /groups/:id/-/work_items' do
    it 'returns an empty list' do
      get api("/groups/#{group.id}/-/work_items", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_empty
    end
  end
end
