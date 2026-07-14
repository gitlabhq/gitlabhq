# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::WorkItems::CurrentUserTodos, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private, reporters: user) }
  let_it_be(:work_item) { create(:work_item, :issue, project: project) }

  let_it_be(:pending_todo) do
    create(:todo, :pending, user: user, project: project, target: work_item, target_type: 'WorkItem')
  end

  let_it_be(:done_todo) do
    create(:todo, :done, user: user, project: project, target: work_item, target_type: 'WorkItem')
  end

  shared_examples 'current_user_todos endpoint' do
    it 'returns the current user to-do items on the work item', :aggregate_failures do
      get api(api_request_path, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to contain_exactly(pending_todo.id, done_todo.id)
      expect(json_response).to all(include('id', 'state', 'target_type', 'action_name'))
    end

    it 'only returns to-do items belonging to the requesting user', :aggregate_failures do
      other_user = create(:user, reporter_of: project)
      create(:todo, :pending, user: other_user, project: project, target: work_item, target_type: 'WorkItem')

      get api(api_request_path, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to contain_exactly(pending_todo.id, done_todo.id)
    end

    context 'with state filter' do
      it 'returns only pending to-do items when state=pending', :aggregate_failures do
        get api(api_request_path, user), params: { state: 'pending' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck('id')).to contain_exactly(pending_todo.id)
      end

      it 'returns only done to-do items when state=done', :aggregate_failures do
        get api(api_request_path, user), params: { state: 'done' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck('id')).to contain_exactly(done_todo.id)
      end

      it 'rejects an invalid state value' do
        get api(api_request_path, user), params: { state: 'invalid' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    it 'returns 404 when the work item does not exist' do
      get api(api_request_path.sub("/#{work_item.iid}/", "/#{non_existing_record_iid}/"), user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns forbidden when the feature flag is disabled' do
      stub_feature_flags(work_item_rest_api: false)

      get api(api_request_path, user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'returns unauthorized when no token is provided' do
      get api(api_request_path)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'paginates the response', :aggregate_failures do
      get api(api_request_path, user), params: { per_page: 1 }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.size).to eq(1)
      expect(response.headers['X-Total']).to eq('2')
    end

    it 'does not cause N+1 queries' do
      author = create(:user)
      create(:todo, :pending, user: user, project: project, target: work_item, target_type: 'WorkItem', author: author)

      control = ActiveRecord::QueryRecorder.new { get api(api_request_path, user) }

      new_author = create(:user)
      create(:todo, :pending, user: user, project: project, target: work_item, target_type: 'WorkItem',
        author: new_author)

      expect { get api(api_request_path, user) }.not_to exceed_query_limit(control)
    end
  end

  describe 'GET /projects/:id/-/work_items/:work_item_iid/current_user_todos' do
    let(:api_request_path) { "/projects/#{project.id}/-/work_items/#{work_item.iid}/current_user_todos" }

    it_behaves_like 'current_user_todos endpoint'

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api(api_request_path, personal_access_token: pat)
      end
    end

    it 'returns not_found when the user cannot read the work item' do
      other_user = create(:user)

      get api(api_request_path, other_user)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET /namespaces/:id/-/work_items/:work_item_iid/current_user_todos' do
    let(:api_request_path) do
      "/namespaces/#{CGI.escape(project.project_namespace.full_path)}/-/work_items/#{work_item.iid}/current_user_todos"
    end

    it_behaves_like 'current_user_todos endpoint'

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api(api_request_path, personal_access_token: pat)
      end
    end
  end
end
