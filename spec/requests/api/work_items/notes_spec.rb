# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::WorkItems::Notes, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:non_member) { create(:user) }
  let_it_be(:project) { create(:project, :private, reporters: user) }
  let_it_be(:work_item) { create(:work_item, :issue, project: project) }

  let_it_be(:comment) { create(:note, project: project, noteable: work_item, author: user, note: 'A user comment') }
  let_it_be(:system_note) do
    create(:note, :system, project: project, noteable: work_item, author: user, note: 'changed the title')
  end

  before do
    stub_feature_flags(work_item_rest_api: true)
  end

  shared_examples 'notes endpoint' do
    it 'returns all notes on the work item', :aggregate_failures do
      get api(api_request_path, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to contain_exactly(comment.id, system_note.id)
      expect(json_response).to all(include('id', 'body', 'author', 'system', 'noteable_id', 'noteable_type'))
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

    context 'with activity_filter' do
      it 'returns only user comments when activity_filter=only_comments', :aggregate_failures do
        get api(api_request_path, user), params: { activity_filter: 'only_comments' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck('id')).to contain_exactly(comment.id)
      end

      it 'returns only system notes when activity_filter=only_activity', :aggregate_failures do
        get api(api_request_path, user), params: { activity_filter: 'only_activity' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck('id')).to contain_exactly(system_note.id)
      end

      it 'returns all notes when activity_filter=all_notes', :aggregate_failures do
        get api(api_request_path, user), params: { activity_filter: 'all_notes' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck('id')).to contain_exactly(comment.id, system_note.id)
      end

      it 'rejects an invalid activity_filter value' do
        get api(api_request_path, user), params: { activity_filter: 'invalid' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'with order_by and sort' do
      let_it_be(:later_comment) do
        create(:note, project: project, noteable: work_item, author: user, created_at: 1.hour.from_now)
      end

      it 'orders by created_at asc by default', :aggregate_failures do
        get api(api_request_path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.last['id']).to eq(later_comment.id)
      end

      it 'orders by created_at desc when sort=desc', :aggregate_failures do
        get api(api_request_path, user), params: { sort: 'desc' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.first['id']).to eq(later_comment.id)
      end

      it 'rejects an invalid order_by' do
        get api(api_request_path, user), params: { order_by: 'invalid' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'with pagination' do
      let_it_be(:extra_notes) do
        create_list(:note, 3, project: project, noteable: work_item, author: user)
      end

      it 'paginates the response and returns a cursor for the next page', :aggregate_failures do
        get api(api_request_path, user), params: { per_page: 2 }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.size).to eq(2)
        expect(response.headers['X-Next-Cursor']).to be_present
      end
    end

    it 'does not issue N+1 queries when more notes are added', :aggregate_failures do
      other_author = create(:user, developer_of: project)
      create(:note, project: project, noteable: work_item, author: other_author)

      get api(api_request_path, user)

      baseline = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        get api(api_request_path, user)
      end

      extra_author = create(:user, developer_of: project)
      extra_note = create(:note, project: project, noteable: work_item, author: extra_author)

      get api(api_request_path, user)

      expect { get api(api_request_path, user) }.to issue_same_number_of_queries_as(baseline)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to include(extra_note.id)
    end

    context 'when a note is not readable by the current user' do
      let_it_be(:guest) { create(:user, guest_of: project) }
      let_it_be(:internal_note) do
        create(:note, :confidential, project: project, noteable: work_item, author: user, note: 'Internal-only note')
      end

      it 'omits notes the user cannot read', :aggregate_failures do
        get api(api_request_path, guest)

        expect(response).to have_gitlab_http_status(:ok)
        ids = json_response.pluck('id')
        expect(ids).not_to include(internal_note.id)
        expect(ids).to include(comment.id, system_note.id)
      end
    end
  end

  describe 'GET /projects/:id/-/work_items/:work_item_iid/notes' do
    let(:api_request_path) { "/projects/#{project.id}/-/work_items/#{work_item.iid}/notes" }

    it_behaves_like 'notes endpoint'

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

  describe 'GET /namespaces/:id/-/work_items/:work_item_iid/notes' do
    let(:api_request_path) do
      "/namespaces/#{CGI.escape(project.project_namespace.full_path)}/-/work_items/#{work_item.iid}/notes"
    end

    it_behaves_like 'notes endpoint'

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api(api_request_path, personal_access_token: pat)
      end
    end
  end
end
