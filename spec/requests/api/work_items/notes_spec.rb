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
      get api(api_request_path.sub("/#{work_item.iid}/notes", "/#{non_existing_record_iid}/notes"), user)

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

  shared_examples 'single note endpoint' do
    # Scoped to this group so the list examples above keep their exact expected note set.
    let_it_be(:internal_note) do
      create(:note, :confidential, project: project, noteable: work_item, author: user, note: 'Internal-only note')
    end

    let_it_be(:other_work_item) { create(:work_item, :issue, project: project) }
    let_it_be(:other_note) do
      create(:note, project: project, noteable: other_work_item, author: user, note: 'Note on another work item')
    end

    it 'returns the note', :aggregate_failures do
      get api(api_request_path, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to include('id' => comment.id, 'body' => 'A user comment', 'system' => false)
      expect(json_response).to include('author', 'noteable_id', 'noteable_type')
    end

    it 'returns a system note', :aggregate_failures do
      get api(note_path.call(system_note.id), user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to include('id' => system_note.id, 'system' => true)
    end

    it 'returns 404 when the work item does not exist' do
      get api(note_path.call(comment.id, work_item_iid: non_existing_record_iid), user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 404 when the note does not exist' do
      get api(note_path.call(non_existing_record_id), user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 404 when the note belongs to a different work item' do
      get api(note_path.call(other_note.id), user)

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

    context 'with a note the user cannot read' do
      let_it_be(:guest) { create(:user, guest_of: project) }

      it 'returns 404 for a user who cannot read the note' do
        get api(note_path.call(internal_note.id), guest)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns the note for a user who can read it', :aggregate_failures do
        get api(note_path.call(internal_note.id), user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(internal_note.id)
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

  describe 'GET /projects/:id/-/work_items/:work_item_iid/notes/:note_id' do
    # Built explicitly rather than by substituting into api_request_path: note ids are small in a
    # fresh database and a substring replace can hit the project id or the iid instead.
    let(:note_path) do
      ->(note_id, work_item_iid: work_item.iid) do
        "/projects/#{project.id}/-/work_items/#{work_item_iid}/notes/#{note_id}"
      end
    end

    let(:api_request_path) { note_path.call(comment.id) }

    it_behaves_like 'single note endpoint'

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

  describe 'GET /namespaces/:id/-/work_items/:work_item_iid/notes/:note_id' do
    let(:note_path) do
      ->(note_id, work_item_iid: work_item.iid) do
        "/namespaces/#{CGI.escape(project.project_namespace.full_path)}/-/work_items/#{work_item_iid}/" \
          "notes/#{note_id}"
      end
    end

    let(:api_request_path) { note_path.call(comment.id) }

    it_behaves_like 'single note endpoint'

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api(api_request_path, personal_access_token: pat)
      end
    end
  end

  shared_context 'for creating a note' do
    let_it_be(:owner) { project.first_owner }
    let_it_be(:public_project) { create(:project, :public) }
    let_it_be(:locked_work_item) { create(:work_item, :issue, project: public_project, discussion_locked: true) }
    let_it_be(:quick_action_label) { create(:label, project: project, title: 'bug') }
  end

  describe 'POST /projects/:id/-/work_items/:work_item_iid/notes' do
    include_context 'for creating a note'

    let(:path_for) { ->(item) { "/projects/#{item.project.id}/-/work_items/#{item.iid}/notes" } }
    let(:api_request_path) { path_for.call(work_item) }

    it_behaves_like 'a work item endpoint creating a note'

    it_behaves_like 'authorizing granular token permissions', :create_note, expected_success_status: :created do
      let(:boundary_object) { project }
      let(:request) do
        post api(api_request_path, personal_access_token: pat), params: { body: 'hi!' }
      end
    end
  end

  describe 'POST /namespaces/:id/-/work_items/:work_item_iid/notes' do
    include_context 'for creating a note'

    let(:path_for) do
      ->(item) { "/namespaces/#{CGI.escape(item.namespace.full_path)}/-/work_items/#{item.iid}/notes" }
    end

    let(:api_request_path) { path_for.call(work_item) }

    it_behaves_like 'a work item endpoint creating a note'

    it_behaves_like 'authorizing granular token permissions', :create_note, expected_success_status: :created do
      let(:boundary_object) { project }
      let(:request) do
        post api(api_request_path, personal_access_token: pat), params: { body: 'hi!' }
      end
    end
  end
end
