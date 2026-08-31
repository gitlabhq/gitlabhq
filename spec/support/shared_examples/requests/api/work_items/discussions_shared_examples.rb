# frozen_string_literal: true

# Shared behaviour for the work item discussions endpoints, reused by both the CE
# project/namespace specs and the EE group (epic) specs.
#
# The including context must define:
#   - `api_request_path` the endpoint path, containing "/<work_item.iid>/"
#   - `work_item`         the parent work item (issue or epic)
#   - `user`              a user who can read the work item and its notes
#   - `comment`           a regular note authored by `user` on `work_item`
#   - `system_note`       a system note authored by `user` on `work_item`
#   - `container`         the project or group notes/membership are scoped to
#   - `note_params`       keyword args identifying the noteable's container when creating
#                         notes directly, e.g. `{ project: project }` or
#                         `{ namespace: group, project: nil }`
RSpec.shared_examples 'a work item discussions endpoint' do
  it 'returns all discussions on the work item', :aggregate_failures do
    get api(api_request_path, user)

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response).to all(include('id', 'individual_note', 'notes'))

    note_ids = json_response.flat_map { |discussion| discussion['notes'].pluck('id') }
    expect(note_ids).to contain_exactly(comment.id, system_note.id)
  end

  it 'groups notes that belong to the same discussion thread', :aggregate_failures do
    root = create(:discussion_note_on_work_item, noteable: work_item, author: user, **note_params)
    reply = create(:discussion_note_on_work_item, noteable: work_item, author: user, in_reply_to: root, **note_params)

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
    other_author = create(:user, developer_of: container)
    create(:note, noteable: work_item, author: other_author, **note_params)

    get api(api_request_path, user)

    baseline = ActiveRecord::QueryRecorder.new(skip_cached: false) do
      get api(api_request_path, user)
    end

    extra_author = create(:user, developer_of: container)
    extra_note = create(:note, noteable: work_item, author: extra_author, **note_params)

    expect { get api(api_request_path, user) }.to issue_same_number_of_queries_as(baseline)

    expect(response).to have_gitlab_http_status(:ok)
    note_ids = json_response.flat_map { |discussion| discussion['notes'].pluck('id') }
    expect(note_ids).to include(extra_note.id)
  end

  context 'when a note is not readable by the current user' do
    let(:guest) { create(:user, guest_of: container) }

    # We need to create this note ahead of time otherwise test will be false-positive
    let!(:internal_note) do
      create(:note, :confidential, noteable: work_item, author: user, note: 'Internal-only note', **note_params)
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

# The including context must define the same interface as
# 'a work item discussions endpoint', minus `system_note` (not used here).
RSpec.shared_examples 'a work item single discussion endpoint' do
  it 'returns the discussion with its notes', :aggregate_failures do
    get api(api_request_path, user)

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response).to include('id' => comment.discussion_id, 'individual_note' => true)
    expect(json_response['notes'].pluck('id')).to contain_exactly(comment.id)
  end

  it 'returns all notes in a multi-note discussion thread', :aggregate_failures do
    root = create(:discussion_note_on_work_item, noteable: work_item, author: user, **note_params)
    reply = create(:discussion_note_on_work_item, noteable: work_item, author: user, in_reply_to: root, **note_params)

    get api(api_request_path.sub(comment.discussion_id, root.discussion_id), user)

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response['individual_note']).to be(false)
    expect(json_response['notes'].pluck('id')).to contain_exactly(root.id, reply.id)
  end

  it 'does not issue N+1 queries when the discussion has more replies', :aggregate_failures do
    root = create(:discussion_note_on_work_item, noteable: work_item, author: user, **note_params)
    path = api_request_path.sub(comment.discussion_id, root.discussion_id)
    other_author = create(:user, developer_of: container)
    create(:discussion_note_on_work_item, noteable: work_item, author: other_author, in_reply_to: root, **note_params)

    get api(path, user)

    baseline = ActiveRecord::QueryRecorder.new(skip_cached: false) do
      get api(path, user)
    end

    extra_author = create(:user, developer_of: container)
    extra_reply = create(:discussion_note_on_work_item, noteable: work_item, author: extra_author,
      in_reply_to: root, **note_params)

    expect { get api(path, user) }.to issue_same_number_of_queries_as(baseline)

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response['notes'].pluck('id')).to include(extra_reply.id)
  end

  it 'returns 404 when the work item does not exist' do
    get api(api_request_path.sub("/#{work_item.iid}/", "/#{non_existing_record_iid}/"), user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when the discussion does not exist' do
    get api(api_request_path.sub(comment.discussion_id, 'nonexistent'), user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when the discussion belongs to a different work item' do
    other_work_item = create(:work_item, work_item.work_item_type.base_type, author: user, **note_params)
    other_note = create(:note, noteable: other_work_item, author: user, **note_params)

    get api(api_request_path.sub(comment.discussion_id, other_note.discussion_id), user)

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

  context 'when no note in the discussion is readable by the current user' do
    let(:guest) { create(:user, guest_of: container) }
    let(:internal_note) do
      create(:note, :confidential, noteable: work_item, author: user, note: 'Internal-only note', **note_params)
    end

    it 'returns 404' do
      get api(api_request_path.sub(comment.discussion_id, internal_note.discussion_id), guest)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
