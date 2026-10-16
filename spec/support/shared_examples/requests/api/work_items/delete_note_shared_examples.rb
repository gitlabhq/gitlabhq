# frozen_string_literal: true

# Provides the project-level setup for 'a work item endpoint deleting a note'; callers define `note_path`.
RSpec.shared_context 'for deleting a note on a project work item' do
  let_it_be(:non_author) { create(:user, developer_of: project) }
  let_it_be(:guest) { create(:user, guest_of: project) }
  let_it_be(:internal_note) do
    create(:note, :confidential, project: project, noteable: work_item, author: user, note: 'Internal-only note')
  end

  let_it_be(:other_work_item) { create(:work_item, :issue, project: project) }
  let_it_be(:other_note) do
    create(:note, project: project, noteable: other_work_item, author: user, note: 'Note on another work item')
  end

  let_it_be(:other_project) { create(:project, :private, reporters: user) }
  let_it_be(:other_parent_work_item) { create(:work_item, :issue, project: other_project) }
  let_it_be(:other_parent_note) do
    create(:note, project: other_project, noteable: other_parent_work_item, author: user, note: 'Note elsewhere')
  end
end

# Requires from the caller:
#   work_item     - the noteable, readable by `user`
#   comment       - a note on `work_item` authored by `user`
#   system_note   - a system note on `work_item`
#   note_path     - lambda(note_id, work_item_iid:) building the request path
#   user          - a reporter on the parent who authored `comment`
#   non_author    - a developer on the parent who did not author `comment`
#   non_member    - a user with no membership on the parent
#   guest         - a guest on the parent, who cannot read internal notes
#   internal_note     - an internal note on `work_item`, authored by `user`
#   other_note        - a note on a different work item in the same parent
#   other_parent_note - a note authored by `user` on a work item in a different parent
RSpec.shared_examples 'a work item endpoint deleting a note' do
  let_it_be(:admin) { create(:admin) }

  let(:api_request_path) { note_path.call(comment.id) }

  it 'deletes the note', :aggregate_failures do
    expect { delete api(api_request_path, user) }.to change { Note.exists?(comment.id) }.from(true).to(false)

    expect(response).to have_gitlab_http_status(:no_content)
    expect(response.body).to be_empty
  end

  it 'returns 404 when deleting the same note again', :aggregate_failures do
    delete api(api_request_path, user)
    expect(response).to have_gitlab_http_status(:no_content)

    delete api(api_request_path, user)
    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'deletes an internal note for its author' do
    expect { delete api(note_path.call(internal_note.id), user) }
      .to change { Note.exists?(internal_note.id) }.from(true).to(false)

    expect(response).to have_gitlab_http_status(:no_content)
  end

  it 'deletes the note for an admin in admin mode' do
    expect { delete api(api_request_path, admin, admin_mode: true) }
      .to change { Note.exists?(comment.id) }.from(true).to(false)

    expect(response).to have_gitlab_http_status(:no_content)
  end

  it 'returns 403 when the user is not the author' do
    expect { delete api(api_request_path, non_author) }.not_to change { Note.exists?(comment.id) }

    expect(response).to have_gitlab_http_status(:forbidden)
  end

  it 'returns 403 for a system note' do
    expect { delete api(note_path.call(system_note.id), user) }.not_to change { Note.exists?(system_note.id) }

    expect(response).to have_gitlab_http_status(:forbidden)
  end

  it 'returns 404 when the work item does not exist' do
    delete api(note_path.call(comment.id, work_item_iid: non_existing_record_iid), user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when the note does not exist' do
    delete api(note_path.call(non_existing_record_id), user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when the note belongs to a different work item' do
    expect { delete api(note_path.call(other_note.id), user) }.not_to change { Note.exists?(other_note.id) }

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when the note belongs to a work item in a different parent' do
    expect { delete api(note_path.call(other_parent_note.id), user) }
      .not_to change { Note.exists?(other_parent_note.id) }

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 for a note the user cannot read' do
    expect { delete api(note_path.call(internal_note.id), guest) }.not_to change { Note.exists?(internal_note.id) }

    expect(response).to have_gitlab_http_status(:not_found)
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

  it 'returns not_found when the user cannot read the work item' do
    delete api(api_request_path, non_member)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it_behaves_like '412 response' do
    let(:request) { api(api_request_path, user) }
  end
end
