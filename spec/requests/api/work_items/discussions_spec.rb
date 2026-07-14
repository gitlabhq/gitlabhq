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

  before do
    stub_feature_flags(work_item_rest_api: true)
  end

  shared_examples 'discussions endpoint' do
    it 'returns all discussions on the work item', :aggregate_failures do
      get api(api_request_path, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to all(include('id', 'individual_note', 'notes'))

      note_ids = json_response.flat_map { |discussion| discussion['notes'].pluck('id') }
      expect(note_ids).to contain_exactly(comment.id, system_note.id)
    end

    it 'groups notes that belong to the same discussion thread', :aggregate_failures do
      root = create(:discussion_note_on_work_item, noteable: work_item, project: project, author: user)
      reply = create(:discussion_note_on_work_item, noteable: work_item, project: project, author: user,
        in_reply_to: root)

      get api(api_request_path, user)

      expect(response).to have_gitlab_http_status(:ok)
      thread = json_response.find { |discussion| discussion['id'] == root.discussion_id }
      expect(thread['notes'].pluck('id')).to contain_exactly(root.id, reply.id)
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
        note_ids = json_response.flat_map { |discussion| discussion['notes'].pluck('id') }
        expect(note_ids).to contain_exactly(comment.id)
      end

      it 'returns only system notes when activity_filter=only_activity', :aggregate_failures do
        get api(api_request_path, user), params: { activity_filter: 'only_activity' }

        expect(response).to have_gitlab_http_status(:ok)
        note_ids = json_response.flat_map { |discussion| discussion['notes'].pluck('id') }
        expect(note_ids).to contain_exactly(system_note.id)
      end

      it 'rejects an invalid activity_filter value' do
        get api(api_request_path, user), params: { activity_filter: 'invalid' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'with sort' do
      it 'orders discussions by creation time ascending by default', :aggregate_failures do
        get api(api_request_path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.first['notes'].first['id']).to eq(comment.id)
      end

      it 'orders discussions by creation time descending when sort=desc', :aggregate_failures do
        get api(api_request_path, user), params: { sort: 'desc' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.first['notes'].first['id']).to eq(system_note.id)
      end

      it 'rejects an invalid sort value' do
        get api(api_request_path, user), params: { sort: 'invalid' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'with pagination' do
      it 'paginates the response and returns a cursor for the next page', :aggregate_failures do
        get api(api_request_path, user), params: { per_page: 1 }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.size).to eq(1)
        expect(response.headers['X-Next-Cursor']).to be_present
      end

      it 'rejects a per_page value of 0' do
        get api(api_request_path, user), params: { per_page: 0 }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    it 'does not issue N+1 queries when more discussions are added', :aggregate_failures do
      other_author = create(:user, developer_of: project)
      create(:note, project: project, noteable: work_item, author: other_author)

      get api(api_request_path, user)

      baseline = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        get api(api_request_path, user)
      end

      extra_author = create(:user, developer_of: project)
      extra_note = create(:note, project: project, noteable: work_item, author: extra_author)

      expect { get api(api_request_path, user) }.to issue_same_number_of_queries_as(baseline)

      expect(response).to have_gitlab_http_status(:ok)
      note_ids = json_response.flat_map { |discussion| discussion['notes'].pluck('id') }
      expect(note_ids).to include(extra_note.id)
    end

    context 'when a note is not readable by the current user' do
      let_it_be(:guest) { create(:user, guest_of: project) }
      let_it_be(:internal_note) do
        create(:note, :confidential, project: project, noteable: work_item, author: user, note: 'Internal-only note')
      end

      it 'omits notes the user cannot read', :aggregate_failures do
        get api(api_request_path, guest)

        expect(response).to have_gitlab_http_status(:ok)
        note_ids = json_response.flat_map { |discussion| discussion['notes'].pluck('id') }
        expect(note_ids).not_to include(internal_note.id)
        expect(note_ids).to include(comment.id, system_note.id)
      end
    end
  end

  describe 'GET /projects/:id/-/work_items/:work_item_iid/discussions' do
    let(:api_request_path) { "/projects/#{project.id}/-/work_items/#{work_item.iid}/discussions" }

    it_behaves_like 'discussions endpoint'

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

    it_behaves_like 'discussions endpoint'

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api(api_request_path, personal_access_token: pat)
      end
    end
  end
end
