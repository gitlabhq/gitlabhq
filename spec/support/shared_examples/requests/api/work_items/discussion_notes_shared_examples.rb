# frozen_string_literal: true

# Shared behaviour for the work item discussion notes endpoints, reused by both the CE
# project/namespace specs and the EE group (epic) specs.
#
# The including context must define:
#   - `api_request_path` the endpoint path for `comment`'s discussion, containing "/<work_item.iid>/"
#   - `work_item`         the parent work item (issue or epic)
#   - `user`              a user who can read the work item and its notes
#   - `comment`           a regular note authored by `user` on `work_item`
#   - `container`         the project or group notes/membership are scoped to
#   - `note_params`       keyword args identifying the noteable's container when creating
#                         notes directly, e.g. `{ project: project }` or
#                         `{ namespace: group, project: nil }`
RSpec.shared_examples 'a work item discussion notes endpoint' do
  let(:thread_path) { ->(discussion_id) { api_request_path.sub(comment.discussion_id, discussion_id) } }

  it 'returns the notes of the discussion', :aggregate_failures do
    get api(api_request_path, user)

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response.pluck('id')).to contain_exactly(comment.id)
    expect(json_response).to all(include('id', 'body', 'author', 'system', 'noteable_id', 'noteable_type'))
  end

  it 'returns all notes in a multi-note discussion thread, oldest first', :aggregate_failures do
    root = create(:discussion_note_on_work_item, noteable: work_item, author: user, **note_params)
    reply = create(:discussion_note_on_work_item, noteable: work_item, author: user, in_reply_to: root, **note_params)

    get api(thread_path.call(root.discussion_id), user)

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response.pluck('id')).to eq([root.id, reply.id])
  end

  context 'with pagination' do
    let(:root) { create(:discussion_note_on_work_item, noteable: work_item, author: user, **note_params) }
    let!(:reply) do
      create(:discussion_note_on_work_item, noteable: work_item, author: user, in_reply_to: root, **note_params)
    end

    it 'returns one page of notes and a cursor for the next page', :aggregate_failures do
      get api(thread_path.call(root.discussion_id), user), params: { per_page: 1 }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to eq([root.id])
      expect(response.headers['X-Next-Cursor']).to be_present

      get api(thread_path.call(root.discussion_id), user),
        params: { per_page: 1, cursor: response.headers['X-Next-Cursor'] }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to eq([reply.id])
    end

    it 'returns an empty page when the cursor points past the last note', :aggregate_failures do
      cursor = Base64.urlsafe_encode64(Gitlab::Json.dump(id: reply.id, _kd: 'n'))

      get api(thread_path.call(root.discussion_id), user), params: { cursor: cursor }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq([])
    end

    it 'returns 404 when the cursor is for a discussion that does not exist', :aggregate_failures do
      cursor = Base64.urlsafe_encode64(Gitlab::Json.dump(id: root.id, _kd: 'n'))

      get api(thread_path.call('nonexistent'), user), params: { cursor: cursor }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns an empty first page when only later pages hold readable notes', :aggregate_failures do
      guest = create(:user, guest_of: container)
      internal_root = create(:discussion_note_on_work_item, noteable: work_item, author: user, **note_params)
      visible_reply = create(:discussion_note_on_work_item, noteable: work_item, author: user,
        in_reply_to: internal_root, **note_params)
      # Replies must match the root's confidentiality, so hide only the root after the fact.
      internal_root.update_column(:confidential, true)

      get api(thread_path.call(internal_root.discussion_id), guest), params: { per_page: 1 }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq([])
      expect(response.headers['X-Next-Cursor']).to be_present

      get api(thread_path.call(internal_root.discussion_id), guest),
        params: { per_page: 1, cursor: response.headers['X-Next-Cursor'] }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to eq([visible_reply.id])
    end

    it 'rejects a per_page value of 0' do
      get api(api_request_path, user), params: { per_page: 0 }

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'rejects a per_page value above 100' do
      get api(api_request_path, user), params: { per_page: 101 }

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  it 'does not issue N+1 queries when the discussion has more replies', :aggregate_failures do
    # Users::ActivityService's lease-gated write to last_activity_on would otherwise land on a random request.
    User.find(user.id).update_column(:last_activity_on, Date.current)
    root = create(:discussion_note_on_work_item, noteable: work_item, author: user, **note_params)
    path = thread_path.call(root.discussion_id)
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
    expect(json_response.pluck('id')).to include(extra_reply.id)
  end

  it 'returns 404 when the work item does not exist' do
    get api(api_request_path.sub("/#{work_item.iid}/", "/#{non_existing_record_iid}/"), user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when the discussion does not exist' do
    get api(thread_path.call('nonexistent'), user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when the discussion belongs to a different work item' do
    other_work_item = create(:work_item, work_item.work_item_type.base_type, author: user, **note_params)
    other_note = create(:note, noteable: other_work_item, author: user, **note_params)

    get api(thread_path.call(other_note.discussion_id), user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns not_found when the feature flag is disabled' do
    stub_feature_flags(work_item_rest_api: false)

    get api(api_request_path, user)

    expect(response).to have_gitlab_http_status(:not_found)
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
      get api(thread_path.call(internal_note.discussion_id), guest)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end

# Shared behaviour for the single note in a work item discussion endpoint. The including
# context must define the same lets as above, plus:
#   - `discussion_note_path` a lambda `->(discussion_id, note_id, work_item_iid: work_item.iid)`
#                            building the endpoint path
RSpec.shared_examples 'a work item discussion note endpoint' do
  it 'returns the note', :aggregate_failures do
    get api(api_request_path, user)

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response).to include('id' => comment.id, 'body' => comment.note, 'system' => false)
    expect(json_response).to include('author', 'noteable_id', 'noteable_type')
  end

  it 'returns a reply in a multi-note discussion thread', :aggregate_failures do
    root = create(:discussion_note_on_work_item, noteable: work_item, author: user, **note_params)
    reply = create(:discussion_note_on_work_item, noteable: work_item, author: user, in_reply_to: root, **note_params)

    get api(discussion_note_path.call(root.discussion_id, reply.id), user)

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response).to include('id' => reply.id)
  end

  it 'returns 404 when the work item does not exist' do
    get api(discussion_note_path.call(comment.discussion_id, comment.id, work_item_iid: non_existing_record_iid), user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when the discussion does not exist' do
    get api(discussion_note_path.call('nonexistent', comment.id), user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when the note does not exist' do
    get api(discussion_note_path.call(comment.discussion_id, non_existing_record_id), user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when the note belongs to a different discussion on the same work item' do
    other_note = create(:note, noteable: work_item, author: user, **note_params)

    get api(discussion_note_path.call(comment.discussion_id, other_note.id), user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when the note belongs to a different work item' do
    other_work_item = create(:work_item, work_item.work_item_type.base_type, author: user, **note_params)
    other_note = create(:note, noteable: other_work_item, author: user, **note_params)

    get api(discussion_note_path.call(other_note.discussion_id, other_note.id), user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns not_found when the feature flag is disabled' do
    stub_feature_flags(work_item_rest_api: false)

    get api(api_request_path, user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns unauthorized when no token is provided' do
    get api(api_request_path)

    expect(response).to have_gitlab_http_status(:unauthorized)
  end

  context 'when the note is not readable by the current user' do
    let(:guest) { create(:user, guest_of: container) }
    let(:internal_note) do
      create(:note, :confidential, noteable: work_item, author: user, note: 'Internal-only note', **note_params)
    end

    it 'returns 404' do
      get api(discussion_note_path.call(internal_note.discussion_id, internal_note.id), guest)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
