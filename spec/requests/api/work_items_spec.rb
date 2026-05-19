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
    context 'when listing group work items' do
      it 'returns an empty array for groups without epics license' do
        get api("/namespaces/#{CGI.escape(group.full_path)}/-/work_items", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq([])
      end
    end

    context 'when listing project work items' do
      let_it_be(:namespace_record) { project.project_namespace }
      let(:primary_work_item) { project_work_item }
      let(:secondary_work_item) { project_work_item2 }
      let(:label) { project_label }
      let(:milestone) { project_milestone }
      let(:expected_work_item_ids) { [primary_work_item.id, secondary_work_item.id].uniq }
      let(:api_request_path) { "/namespaces/#{CGI.escape(namespace_record.full_path)}/-/work_items" }

      it_behaves_like 'work item listing endpoint'
      it_behaves_like 'work item listing filters'
      it_behaves_like 'work item listing sorting'

      it 'supports unescaped namespace full paths' do
        get api("/namespaces/#{namespace_record.full_path}/-/work_items", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck('id')).to match_array(expected_work_item_ids)
      end

      it_behaves_like 'authorizing granular token permissions', :read_work_item do
        let(:boundary_object) { project }
        let(:request) do
          get api("/namespaces/#{CGI.escape(namespace_record.full_path)}/-/work_items",
            personal_access_token: pat)
        end
      end

      describe 'hierarchy feature N+1 prevention' do
        let_it_be(:hierarchy_parent) { create(:work_item, project: project) }
        let_it_be(:child_task) { create(:work_item, :task, project: project) }

        # Pair hierarchy with web_url so the project / namespace preloads are also active,
        # isolating the assertion to the hierarchy preload rather than unrelated lookups
        let(:request_params) { { features: 'hierarchy', fields: 'web_url' } }

        before do
          create(:parent_link, work_item: child_task, work_item_parent: hierarchy_parent)
        end

        it 'preloads the parent association so adding children does not cause N+1 queries' do
          api_path = "/namespaces/#{CGI.escape(namespace_record.full_path)}/-/work_items"

          # Warmup so first-request lazy writes don't skew the baseline.
          get api(api_path, user), params: request_params

          baseline = ActiveRecord::QueryRecorder.new(skip_cached: false) do
            get api(api_path, user), params: request_params
          end

          extra_parent = create(:work_item, project: project)
          extra_child = create(:work_item, :task, project: project)
          create(:parent_link, work_item: extra_child, work_item_parent: extra_parent)

          expect { get api(api_path, user), params: request_params }.to issue_same_number_of_queries_as(baseline)

          expect(response).to have_gitlab_http_status(:ok)
          expect(features_json_for(child_task)).to include(
            'hierarchy' => a_hash_including('parent' => a_hash_including('id' => hierarchy_parent.id))
          )
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

  describe 'GET /namespaces/:id/-/work_items/:work_item_iid' do
    context 'when fetching a group work item' do
      it 'returns not found for groups without epics license' do
        get api("/namespaces/#{CGI.escape(group.full_path)}/-/work_items/1", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when fetching a project work item' do
      let(:namespace_record) { project.project_namespace }
      let(:api_request_path) { "/namespaces/#{CGI.escape(namespace_record.full_path)}/-/work_items" }
      let(:primary_work_item) { project_work_item }
      let(:label) { project_label }

      it_behaves_like 'work item show endpoint'

      it_behaves_like 'authorizing granular token permissions', :read_work_item do
        let(:boundary_object) { project }
        let(:request) do
          get api("#{api_request_path}/#{primary_work_item.iid}", personal_access_token: pat)
        end
      end
    end

    context 'when namespace is not a group or project' do
      let_it_be(:user_namespace) { create(:namespace, owner: user) }

      it 'returns not found' do
        get api("/namespaces/#{CGI.escape(user_namespace.full_path)}/-/work_items/1", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /projects/:id/-/work_items' do
    let_it_be(:namespace_record) { project.project_namespace }
    let(:primary_work_item) { project_work_item }
    let(:secondary_work_item) { project_work_item2 }
    let(:label) { project_label }
    let(:milestone) { project_milestone }
    let(:api_request_path) { "/projects/#{project.id}/-/work_items" }
    let(:expected_work_item_ids) { [primary_work_item.id, secondary_work_item.id].uniq }

    it_behaves_like 'work item listing endpoint'
    it_behaves_like 'work item listing filters'
    it_behaves_like 'work item listing sorting'

    it 'supports unescaped project full paths' do
      get api("/projects/#{project.full_path}/-/work_items", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to match_array(expected_work_item_ids)
    end

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api("/projects/#{project.id}/-/work_items", personal_access_token: pat)
      end
    end

    context 'with N+1 query prevention' do
      let(:api_request_path) { "/projects/#{project.id}/-/work_items" }

      it_behaves_like 'work item N+1 query prevention'
    end
  end

  describe 'GET /projects/:id/-/work_items/:work_item_iid' do
    let(:api_request_path) { "/projects/#{project.id}/-/work_items" }
    let(:primary_work_item) { project_work_item }
    let(:label) { project_label }

    it_behaves_like 'work item show endpoint'

    context 'when authenticated with a token that has the ai_workflows scope' do
      let_it_be(:oauth_token) { create(:oauth_access_token, user: user, scopes: [:ai_workflows]) }

      it 'returns the work item successfully' do
        get api("#{api_request_path}/#{primary_work_item.iid}", oauth_access_token: oauth_token)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api("#{api_request_path}/#{primary_work_item.iid}", personal_access_token: pat)
      end
    end

    context 'when accessing a confidential work item' do
      let_it_be(:public_project) { create(:project, :public) }
      let_it_be(:confidential_work_item) { create(:work_item, :confidential, project: public_project) }
      let_it_be(:non_member_user) { create(:user) }

      before do
        stub_feature_flags(work_item_rest_api: non_member_user)
      end

      it 'returns not found for a user without access' do
        get api("/projects/#{public_project.id}/-/work_items/#{confidential_work_item.iid}", non_member_user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the hierarchy feature is requested' do
      let_it_be(:other_project) { create(:project, :private) }

      context 'with a parent the user cannot read' do
        let_it_be(:hidden_parent) { create(:work_item, project: other_project) }
        let_it_be(:visible_task) { create(:work_item, :task, project: project) }

        before_all do
          create(:parent_link, work_item: visible_task, work_item_parent: hidden_parent)
        end

        it 'hides parent details' do
          get api("/projects/#{project.id}/-/work_items/#{visible_task.iid}", user),
            params: { features: 'hierarchy' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['features']['hierarchy']).to include('parent' => nil)
        end

        it 'exposes parent details once the user gains read access' do
          other_project.add_reporter(user)

          get api("/projects/#{project.id}/-/work_items/#{visible_task.iid}", user),
            params: { features: 'hierarchy' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['features']['hierarchy']['parent']).to include('id' => hidden_parent.id)
        end
      end
    end

    context 'when requesting title_html' do
      context 'when the title contains a cross-project reference to a private project' do
        let_it_be(:private_project) { create(:project, :private) }
        let_it_be(:private_work_item) { create(:work_item, project: private_project, title: 'Secret') }
        let_it_be(:work_item_with_reference) do
          create(:work_item, project: project, title: "#{private_project.full_path}##{private_work_item.iid}")
        end

        it 'does not expose the private work item title in title_html to a user without access' do
          # Banzai renders cross-project references at write time without a user context, so the
          # raw cached column contains the private title in an <a title="..."> attribute.
          expect(work_item_with_reference.title_html).to include('Secret')

          get api("/projects/#{project.id}/-/work_items/#{work_item_with_reference.iid}", user),
            params: { fields: 'title_html' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['title_html']).not_to include('Secret')
        end
      end
    end
  end

  describe 'GET /groups/:id/-/work_items' do
    it 'returns an empty array for groups without epics license' do
      get api("/groups/#{group.id}/-/work_items", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq([])
    end
  end

  describe 'GET /groups/:id/-/work_items/:work_item_iid' do
    it 'returns not found for groups without epics license' do
      get api("/groups/#{group.id}/-/work_items/1", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
