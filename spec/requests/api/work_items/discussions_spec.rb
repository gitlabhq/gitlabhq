# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::WorkItems::Discussions, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:non_member) { create(:user) }
  let_it_be(:project) { create(:project, :private, reporters: user) }
  let_it_be(:work_item, reload: true) { create(:work_item, :issue, project: project) }

  let_it_be(:comment) { create(:note, project: project, noteable: work_item, author: user, note: 'A user comment') }
  let_it_be(:system_note) do
    create(:note, :system, project: project, noteable: work_item, author: user, note: 'changed the title')
  end

  let(:container) { project }
  let(:note_params) { { project: project } }

  before do
    stub_feature_flags(work_item_rest_api: true)
  end

  describe 'GET /projects/:id/-/work_items/:work_item_iid/discussions' do
    let(:api_request_path) { "/projects/#{project.id}/-/work_items/#{work_item.iid}/discussions" }

    it_behaves_like 'a work item discussions endpoint'

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api(api_request_path, personal_access_token: pat)
      end
    end

    it 'returns not_found when the user cannot read the work item' do
      get api(api_request_path, non_member)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET /namespaces/:id/-/work_items/:work_item_iid/discussions' do
    let(:api_request_path) do
      "/namespaces/#{CGI.escape(project.project_namespace.full_path)}/-/work_items/#{work_item.iid}/discussions"
    end

    it_behaves_like 'a work item discussions endpoint'

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api(api_request_path, personal_access_token: pat)
      end
    end

    it 'returns not_found when the user cannot read the work item' do
      get api(api_request_path, non_member)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET /projects/:id/-/work_items/:work_item_iid/discussions/:discussion_id' do
    let(:api_request_path) do
      "/projects/#{project.id}/-/work_items/#{work_item.iid}/discussions/#{comment.discussion_id}"
    end

    it_behaves_like 'a work item single discussion endpoint'

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api(api_request_path, personal_access_token: pat)
      end
    end

    it 'returns not_found when the user cannot read the work item' do
      get api(api_request_path, non_member)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET /namespaces/:id/-/work_items/:work_item_iid/discussions/:discussion_id' do
    let(:api_request_path) do
      "/namespaces/#{CGI.escape(project.project_namespace.full_path)}/-/work_items/#{work_item.iid}/discussions/" \
        "#{comment.discussion_id}"
    end

    it_behaves_like 'a work item single discussion endpoint'

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api(api_request_path, personal_access_token: pat)
      end
    end

    it 'returns not_found when the user cannot read the work item' do
      get api(api_request_path, non_member)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
