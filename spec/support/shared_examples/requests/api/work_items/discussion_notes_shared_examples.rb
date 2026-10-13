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
    path = api_request_path.sub("/-/work_items/#{work_item.iid}/", "/-/work_items/#{non_existing_record_iid}/")

    get api(path, user)

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

# Shared behaviour for the reply to a work item discussion endpoint. The including context
# must define the same lets as above, plus:
#   - `owner`              an owner of the work item's parent (may set created_at)
#   - `non_member`         a user with no membership on the parent
#   - `quick_action_label` a label named 'bug' that is visible to the work item
#   - `reply_path`         a lambda `->(item, discussion_id)` building the endpoint path
RSpec.shared_examples 'a work item endpoint replying to a discussion' do
  let(:params) { { body: 'hi!' } }
  let(:path_for) { ->(item) { reply_path.call(item, comment.discussion_id) } }

  it_behaves_like 'a work item endpoint creating a note'

  it 'adds the note to the discussion', :aggregate_failures do
    post api(api_request_path, user), params: params

    expect(response).to have_gitlab_http_status(:created)
    expect(json_response['type']).to eq('DiscussionNote')
    expect(Note.find(json_response['id']).discussion_id).to eq(comment.discussion_id)
  end

  it 'converts a standalone comment into a discussion thread', :aggregate_failures do
    post api(api_request_path, user), params: params

    expect(response).to have_gitlab_http_status(:created)
    expect(comment.reload.type).to eq('DiscussionNote')
  end

  it 'adds a reply to a multi-note discussion thread', :aggregate_failures do
    root = create(:discussion_note_on_work_item, noteable: work_item, author: user, **note_params)
    create(:discussion_note_on_work_item, noteable: work_item, author: user, in_reply_to: root, **note_params)

    post api(reply_path.call(work_item, root.discussion_id), user), params: params

    expect(response).to have_gitlab_http_status(:created)
    expect(Note.find(json_response['id']).discussion_id).to eq(root.discussion_id)
  end

  it 'inherits the confidentiality of an internal thread', :aggregate_failures do
    internal_note = create(:note, :confidential, noteable: work_item, author: user, **note_params)

    post api(reply_path.call(work_item, internal_note.discussion_id), user), params: params

    expect(response).to have_gitlab_http_status(:created)
    expect(json_response['internal']).to be(true)
  end

  it 'returns 400 when replying to a system note', :aggregate_failures do
    system_note = create(:note, :system, noteable: work_item, author: user, **note_params)

    post api(reply_path.call(work_item, system_note.discussion_id), user), params: params

    expect(response).to have_gitlab_http_status(:bad_request)
    expect(json_response['message']).to eq('400 Bad request - Replies to system notes are not allowed.')
  end

  it 'returns 404 when the discussion does not exist' do
    post api(reply_path.call(work_item, 'nonexistent'), user), params: params

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when the discussion belongs to a different work item' do
    other_work_item = create(:work_item, work_item.work_item_type.base_type, author: user, **note_params)
    other_note = create(:note, noteable: other_work_item, author: user, **note_params)

    post api(reply_path.call(work_item, other_note.discussion_id), user), params: params

    expect(response).to have_gitlab_http_status(:not_found)
  end

  context 'when no note in the discussion is readable by the current user' do
    let(:guest) { create(:user, guest_of: container) }
    let(:internal_note) do
      create(:note, :confidential, noteable: work_item, author: user, note: 'Internal-only note', **note_params)
    end

    it 'returns 404' do
      post api(reply_path.call(work_item, internal_note.discussion_id), guest), params: params

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end

# Same requirements as above, plus `locked_work_item`: a work item with a locked discussion in a public
# parent. Kept separate because the `/namespaces/:id` route only resolves groups for members, so a
# non-member gets 404 there instead of 403.
RSpec.shared_examples 'a work item endpoint rejecting replies to a locked discussion' do
  it 'returns forbidden for a non-member', :aggregate_failures do
    root = create(:note, noteable: locked_work_item, author: user, project: locked_work_item.project,
      namespace: locked_work_item.namespace)
    path = reply_path.call(locked_work_item, root.discussion_id)

    expect { post api(path, non_member), params: { body: 'hi!' } }.not_to change { locked_work_item.notes.count }

    expect(response).to have_gitlab_http_status(:forbidden)
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

# Shared behaviour for the PUT single note in a work item discussion endpoint. The including
# context must define the same lets as above, plus:
#   - `discussion_note`      a resolvable DiscussionNote authored by `user` on `work_item`
#   - `discussion_note_path` a lambda `->(discussion_id, note_id, work_item_iid: work_item.iid)`
#                            building the endpoint path
#   - `api_request_path`     pointing at `discussion_note`
RSpec.shared_examples 'a work item endpoint updating a discussion note' do
  it 'updates the note body', :aggregate_failures do
    put api(api_request_path, user), params: { body: 'Hello!' }

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response).to include('id' => discussion_note.id, 'body' => 'Hello!')
    expect(discussion_note.reload.note).to eq('Hello!')
  end

  it 'updates the body of a reply in a multi-note discussion thread', :aggregate_failures do
    reply = create(:discussion_note_on_work_item, noteable: work_item, author: user, in_reply_to: discussion_note,
      **note_params)

    put api(discussion_note_path.call(discussion_note.discussion_id, reply.id), user), params: { body: 'Hello!' }

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response).to include('id' => reply.id, 'body' => 'Hello!')
  end

  it 'resolves the note when resolved is true', :aggregate_failures do
    put api(api_request_path, user), params: { resolved: true }

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response).to include('id' => discussion_note.id, 'resolvable' => true, 'resolved' => true)
    expect(json_response['resolved_by']).to include('id' => user.id)
    expect(Time.parse(json_response['resolved_at'])).to be_like_time(discussion_note.reload.resolved_at)
  end

  it 'unresolves the note when resolved is false', :aggregate_failures do
    discussion_note.resolve!(user)

    put api(api_request_path, user), params: { resolved: false }

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response).to include('id' => discussion_note.id, 'resolvable' => true, 'resolved' => false)
    expect(json_response['resolved_at']).to be_nil
    expect(discussion_note.reload).not_to be_resolved
  end

  it 'resolves only the targeted note in a multi-note discussion thread', :aggregate_failures do
    reply = create(:discussion_note_on_work_item, noteable: work_item, author: user, in_reply_to: discussion_note,
      **note_params)

    put api(api_request_path, user), params: { resolved: true }

    expect(response).to have_gitlab_http_status(:ok)
    expect(discussion_note.reload).to be_resolved
    expect(reply.reload).not_to be_resolved
  end

  it 'resolves the note for a member who did not author it', :aggregate_failures do
    developer = create(:user, developer_of: container)

    put api(api_request_path, developer), params: { resolved: true }

    expect(response).to have_gitlab_http_status(:ok)
    expect(discussion_note.reload).to be_resolved
  end

  it 'returns 400 when neither body nor resolved is given' do
    put api(api_request_path, user)

    expect(response).to have_gitlab_http_status(:bad_request)
  end

  it 'returns 400 when both body and resolved are given' do
    put api(api_request_path, user), params: { body: 'Hello!', resolved: true }

    expect(response).to have_gitlab_http_status(:bad_request)
  end

  it 'returns 400 when the note is not resolvable' do
    put api(discussion_note_path.call(comment.discussion_id, comment.id), user), params: { resolved: true }

    expect(response).to have_gitlab_http_status(:bad_request)
  end

  it 'returns 400 when resolved is blank', :aggregate_failures do
    put api(api_request_path, user), params: { resolved: nil }

    expect(response).to have_gitlab_http_status(:bad_request)
    expect(json_response['error']).to eq('resolved is empty')
  end

  it 'returns 403 when the user cannot edit the note' do
    developer = create(:user, developer_of: container)

    put api(api_request_path, developer), params: { body: 'Hello!' }

    expect(response).to have_gitlab_http_status(:forbidden)
  end

  it 'returns 403 when the user cannot resolve the note' do
    guest = create(:user, guest_of: container)

    put api(api_request_path, guest), params: { resolved: true }

    expect(response).to have_gitlab_http_status(:forbidden)
  end

  it 'returns 404 when the work item does not exist' do
    put api(discussion_note_path.call(discussion_note.discussion_id, discussion_note.id,
      work_item_iid: non_existing_record_iid), user), params: { body: 'Hello!' }

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when the discussion does not exist' do
    put api(discussion_note_path.call('nonexistent', discussion_note.id), user), params: { body: 'Hello!' }

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when the note does not exist' do
    put api(discussion_note_path.call(discussion_note.discussion_id, non_existing_record_id), user),
      params: { body: 'Hello!' }

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when the note belongs to a different discussion on the same work item' do
    put api(discussion_note_path.call(discussion_note.discussion_id, comment.id), user), params: { body: 'Hello!' }

    expect(response).to have_gitlab_http_status(:not_found)
    expect(comment.reload.note).not_to eq('Hello!')
  end

  it 'returns 404 when the note belongs to a different work item' do
    other_work_item = create(:work_item, work_item.work_item_type.base_type, author: user, **note_params)
    other_note = create(:discussion_note_on_work_item, noteable: other_work_item, author: user, **note_params)

    put api(discussion_note_path.call(other_note.discussion_id, other_note.id), user), params: { body: 'Hello!' }

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns not_found when the feature flag is disabled' do
    stub_feature_flags(work_item_rest_api: false)

    put api(api_request_path, user), params: { body: 'Hello!' }

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns unauthorized when no token is provided' do
    put api(api_request_path), params: { body: 'Hello!' }

    expect(response).to have_gitlab_http_status(:unauthorized)
  end

  context 'when the note is not readable by the current user' do
    let(:guest) { create(:user, guest_of: container) }
    let(:internal_note) do
      create(:discussion_note_on_work_item, :confidential, noteable: work_item, author: user, **note_params)
    end

    it 'returns 404' do
      put api(discussion_note_path.call(internal_note.discussion_id, internal_note.id), guest),
        params: { resolved: true }

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end

# Shared behaviour for the DELETE single note in a work item discussion endpoint. The including
# context must define the same lets as the GET note examples, plus:
#   - `deletable_note`       a DiscussionNote authored by `user` on `work_item`, created per example
#   - `discussion_note_path` a lambda `->(discussion_id, note_id, work_item_iid: work_item.iid)`
#                            building the endpoint path
#   - `api_request_path`     the endpoint path for `deletable_note`
RSpec.shared_examples 'a work item endpoint deleting a discussion note' do
  it 'deletes the note', :aggregate_failures do
    delete api(api_request_path, user)

    expect(response).to have_gitlab_http_status(:no_content)
    expect(Note.exists?(deletable_note.id)).to be(false)
  end

  it 'deletes a reply in a multi-note discussion thread', :aggregate_failures do
    reply = create(:discussion_note_on_work_item, noteable: work_item, author: user, in_reply_to: deletable_note,
      **note_params)

    delete api(discussion_note_path.call(deletable_note.discussion_id, reply.id), user)

    expect(response).to have_gitlab_http_status(:no_content)
    expect(Note.exists?(reply.id)).to be(false)
    expect(Note.exists?(deletable_note.id)).to be(true)
  end

  it 'returns 404 on a second delete of the same note' do
    delete api(api_request_path, user)
    delete api(api_request_path, user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it_behaves_like '412 response' do
    let(:request) { api(api_request_path, user) }
  end

  it 'deletes another user note as a maintainer', :aggregate_failures do
    maintainer = create(:user, maintainer_of: container)

    delete api(api_request_path, maintainer)

    expect(response).to have_gitlab_http_status(:no_content)
    expect(Note.exists?(deletable_note.id)).to be(false)
  end

  it 'returns 403 when the user cannot delete the note', :aggregate_failures do
    developer = create(:user, developer_of: container)

    delete api(api_request_path, developer)

    expect(response).to have_gitlab_http_status(:forbidden)
    expect(Note.exists?(deletable_note.id)).to be(true)
  end

  it 'returns 403 for a system note', :aggregate_failures do
    system_note = create(:system_note, noteable: work_item, author: user, **note_params)

    delete api(discussion_note_path.call(system_note.discussion_id, system_note.id), user)

    expect(response).to have_gitlab_http_status(:forbidden)
    expect(Note.exists?(system_note.id)).to be(true)
  end

  it 'returns 404 when the work item does not exist' do
    delete api(discussion_note_path.call(deletable_note.discussion_id, deletable_note.id,
      work_item_iid: non_existing_record_iid), user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when the discussion does not exist' do
    delete api(discussion_note_path.call('nonexistent', deletable_note.id), user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when the note does not exist' do
    delete api(discussion_note_path.call(deletable_note.discussion_id, non_existing_record_id), user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when the note belongs to a different discussion on the same work item', :aggregate_failures do
    delete api(discussion_note_path.call(deletable_note.discussion_id, comment.id), user)

    expect(response).to have_gitlab_http_status(:not_found)
    expect(Note.exists?(comment.id)).to be(true)
  end

  it 'returns 404 when the note belongs to a different work item', :aggregate_failures do
    other_work_item = create(:work_item, work_item.work_item_type.base_type, author: user, **note_params)
    other_note = create(:discussion_note_on_work_item, noteable: other_work_item, author: user, **note_params)

    delete api(discussion_note_path.call(other_note.discussion_id, other_note.id), user)

    expect(response).to have_gitlab_http_status(:not_found)
    expect(Note.exists?(other_note.id)).to be(true)
  end

  it 'returns not_found when the feature flag is disabled' do
    stub_feature_flags(work_item_rest_api: false)

    delete api(api_request_path, user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns unauthorized when no token is provided' do
    delete api(api_request_path)

    expect(response).to have_gitlab_http_status(:unauthorized)
  end

  context 'when the note is not readable by the current user' do
    let(:guest) { create(:user, guest_of: container) }
    let(:internal_note) do
      create(:discussion_note_on_work_item, :confidential, noteable: work_item, author: user, **note_params)
    end

    it 'returns 404', :aggregate_failures do
      delete api(discussion_note_path.call(internal_note.discussion_id, internal_note.id), guest)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(Note.exists?(internal_note.id)).to be(true)
    end
  end
end
