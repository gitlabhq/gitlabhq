# frozen_string_literal: true

# Provides the project-level setup for 'a work item endpoint updating a note'; callers define `note_path`.
RSpec.shared_context 'for updating a note on a project work item' do
  let_it_be(:non_author) { create(:user, developer_of: project) }
  let_it_be(:guest) { create(:user, guest_of: project) }
  let_it_be(:quick_action_label) { create(:label, project: project, title: 'bug') }
  let_it_be(:internal_note) do
    create(:note, :confidential, project: project, noteable: work_item, author: user, note: 'Internal-only note')
  end

  let_it_be(:other_work_item) { create(:work_item, :issue, project: project) }
  let_it_be(:other_note) do
    create(:note, project: project, noteable: other_work_item, author: user, note: 'Note on another work item')
  end
end

# Requires from the caller:
#   work_item          - the noteable, readable by `user`
#   comment            - a note on `work_item` authored by `user`
#   system_note        - a system note on `work_item`
#   note_path          - lambda(note_id, work_item_iid:) building the request path
#   user               - a reporter on the parent who authored `comment`
#   non_author         - a developer on the parent who did not author `comment`
#   non_member         - a user with no membership on the parent
#   guest              - a guest on the parent, who cannot read internal notes
#   internal_note      - an internal note on `work_item`
#   other_note         - a note on a different work item in the same parent
#   quick_action_label - a label named 'bug' that is visible to the work item
RSpec.shared_examples 'a work item endpoint updating a note' do
  let(:api_request_path) { note_path.call(comment.id) }
  let(:params) { { body: 'Updated body' } }

  it 'updates the note body', :aggregate_failures do
    put api(api_request_path, user), params: params

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response).to include('id' => comment.id, 'body' => 'Updated body')
    expect(json_response['author']['username']).to eq(user.username)
    expect(comment.reload.note).to eq('Updated body')
  end

  it 'returns 400 when body is missing' do
    put api(api_request_path, user)

    expect(response).to have_gitlab_http_status(:bad_request)
  end

  it 'returns 400 when body is blank' do
    expect { put api(api_request_path, user), params: { body: '' } }.not_to change { comment.reload.note }

    expect(response).to have_gitlab_http_status(:bad_request)
  end

  it 'returns 403 when the user is not the author' do
    expect { put api(api_request_path, non_author), params: params }.not_to change { comment.reload.note }

    expect(response).to have_gitlab_http_status(:forbidden)
  end

  it 'returns 403 for a system note' do
    expect { put api(note_path.call(system_note.id), user), params: params }
      .not_to change { system_note.reload.note }

    expect(response).to have_gitlab_http_status(:forbidden)
  end

  it 'returns 404 when the work item does not exist' do
    put api(note_path.call(comment.id, work_item_iid: non_existing_record_iid), user), params: params

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when the note does not exist' do
    put api(note_path.call(non_existing_record_id), user), params: params

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when the note belongs to a different work item' do
    expect { put api(note_path.call(other_note.id), user), params: params }.not_to change { other_note.reload.note }

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 for a note the user cannot read' do
    expect { put api(note_path.call(internal_note.id), guest), params: params }
      .not_to change { internal_note.reload.note }

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns not_found when the feature flag is disabled' do
    stub_feature_flags(work_item_rest_api: false)

    put api(api_request_path, user), params: params

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns unauthorized when no token is provided' do
    put api(api_request_path), params: params

    expect(response).to have_gitlab_http_status(:unauthorized)
  end

  it 'returns not_found when the user cannot read the work item' do
    put api(api_request_path, non_member), params: params

    expect(response).to have_gitlab_http_status(:not_found)
  end

  context 'when the body contains only quick actions' do
    let(:params) { { body: "/label ~#{quick_action_label.title}" } }

    it 'applies the commands and returns 202 after removing the note', :aggregate_failures do
      expect { put api(api_request_path, user), params: params }.to change { work_item.notes.count }.by(-1)

      expect(response).to have_gitlab_http_status(:accepted)
      expect(json_response['commands_changes']).to include('add_label_ids')
      expect(work_item.reload.labels).to include(quick_action_label)
    end
  end
end
