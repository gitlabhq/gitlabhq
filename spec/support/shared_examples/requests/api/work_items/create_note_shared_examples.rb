# frozen_string_literal: true

# Provides the project-level setup for 'a work item endpoint creating a note'; callers define `path_for`.
RSpec.shared_context 'for creating a note on a project work item' do
  let_it_be(:owner) { project.first_owner }
  let_it_be(:public_project) { create(:project, :public) }
  let_it_be(:locked_work_item) { create(:work_item, :issue, project: public_project, discussion_locked: true) }
  let_it_be(:quick_action_label) { create(:label, project: project, title: 'bug') }

  let(:api_request_path) { path_for.call(work_item) }
end

# Requires from the caller:
#   work_item          - the noteable, readable by `user`
#   path_for           - lambda building the request path from a work item
#   user               - a reporter on the work item's parent
#   owner              - an owner of the work item's parent (may set created_at)
#   non_member         - a user with no membership on the parent
#   quick_action_label - a label named 'bug' that is visible to the work item
# May be overridden by the caller:
#   created_note_json  - the created note in the response, when it is nested (e.g. in a discussion)
# Endpoints that accept `internal` also include 'a work item endpoint creating an internal note', and
# routes that return 403 for a locked discussion include 'a work item endpoint rejecting notes on a
# locked discussion'. Replies inherit confidentiality, and the `/namespaces/:id` route 404s for
# non-members, so neither fits every caller.
RSpec.shared_examples 'a work item endpoint creating a note' do
  let(:params) { { body: 'hi!' } }
  let(:created_note_json) { json_response }

  it 'creates a note on the work item', :aggregate_failures do
    expect { post api(api_request_path, user), params: params }.to change { work_item.notes.count }.by(1)

    expect(response).to have_gitlab_http_status(:created)
    expect(created_note_json['body']).to eq('hi!')
    expect(created_note_json['internal']).to be(false)
    expect(created_note_json['noteable_id']).to eq(work_item.id)
    expect(created_note_json['author']['username']).to eq(user.username)
  end

  it 'returns 400 when body is missing' do
    post api(api_request_path, user)

    expect(response).to have_gitlab_http_status(:bad_request)
  end

  it 'returns 404 when the work item does not exist' do
    path = api_request_path.sub("/-/work_items/#{work_item.iid}/", "/-/work_items/#{non_existing_record_iid}/")

    post api(path, user), params: params

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 400 when work_item_iid is not an integer', :aggregate_failures do
    path = api_request_path.sub("/-/work_items/#{work_item.iid}/", "/-/work_items/#{work_item.iid}abc/")

    expect { post api(path, user), params: params }.not_to change { work_item.notes.count }

    expect(response).to have_gitlab_http_status(:bad_request)
  end

  it 'returns not_found when the feature flag is disabled' do
    stub_feature_flags(work_item_rest_api: false)

    post api(api_request_path, user), params: params

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns unauthorized when no token is provided' do
    post api(api_request_path), params: params

    expect(response).to have_gitlab_http_status(:unauthorized)
  end

  it 'returns not_found when the user cannot read the work item' do
    post api(api_request_path, non_member), params: params

    expect(response).to have_gitlab_http_status(:not_found)
  end

  context 'when setting created_at' do
    let(:creation_time) { 2.weeks.ago }
    let(:params) { { body: 'hi!', created_at: creation_time } }

    it 'sets the creation time for an owner', :aggregate_failures do
      post api(api_request_path, owner), params: params

      expect(response).to have_gitlab_http_status(:created)
      expect(Time.parse(created_note_json['created_at'])).to be_like_time(creation_time)
      expect(Time.parse(created_note_json['updated_at'])).to be_like_time(creation_time)
    end

    it 'ignores created_at for a reporter', :aggregate_failures do
      post api(api_request_path, user), params: params

      expect(response).to have_gitlab_http_status(:created)
      expect(Time.parse(created_note_json['created_at'])).not_to be_like_time(creation_time)
    end
  end

  context 'when the body contains only quick actions' do
    let(:params) { { body: "/label ~#{quick_action_label.title}" } }

    it 'applies the commands and returns 202 without creating a note', :aggregate_failures do
      expect { post api(api_request_path, user), params: params }.not_to change { work_item.notes.count }

      expect(response).to have_gitlab_http_status(:accepted)
      expect(json_response['commands_changes']).to include('add_label_ids')
      expect(work_item.reload.labels).to include(quick_action_label)
    end
  end

  context 'when rate limited' do
    before do
      allow(Gitlab::ApplicationRateLimiter).to receive(:throttled_request?).and_return(true)
    end

    it 'returns too_many_requests without querying notes', :aggregate_failures do
      recorder = ActiveRecord::QueryRecorder.new { post api(api_request_path, user), params: params }

      expect(response).to have_gitlab_http_status(:too_many_requests)
      expect(recorder.log.grep(/FROM "notes"/)).to be_empty
    end
  end
end

# Same requirements as 'a work item endpoint creating a note'.
RSpec.shared_examples 'a work item endpoint creating an internal note' do
  let(:params) { { body: 'hi!' } }
  let(:created_note_json) { json_response }

  it 'creates an internal note when internal is true', :aggregate_failures do
    post api(api_request_path, user), params: params.merge(internal: true)

    expect(response).to have_gitlab_http_status(:created)
    expect(created_note_json['internal']).to be(true)
    expect(created_note_json['confidential']).to be(true)
  end
end

# Requires `path_for`, `non_member` and `locked_work_item` (a work item with a locked discussion in a
# public parent) from the caller.
RSpec.shared_examples 'a work item endpoint rejecting notes on a locked discussion' do
  it 'returns forbidden for a non-member', :aggregate_failures do
    expect { post api(path_for.call(locked_work_item), non_member), params: { body: 'hi!' } }
      .not_to change { locked_work_item.notes.count }

    expect(response).to have_gitlab_http_status(:forbidden)
  end
end

# Same requirements as 'a work item endpoint creating a note'; the response is a discussion wrapping the note.
RSpec.shared_examples 'a work item endpoint creating a discussion' do
  it_behaves_like 'a work item endpoint creating a note' do
    let(:created_note_json) { json_response['notes'].first }
  end

  it_behaves_like 'a work item endpoint creating an internal note' do
    let(:created_note_json) { json_response['notes'].first }
  end

  it_behaves_like 'a work item endpoint rejecting notes on a locked discussion'

  it 'creates a new discussion thread', :aggregate_failures do
    post api(api_request_path, user), params: { body: 'hi!' }

    expect(response).to have_gitlab_http_status(:created)
    expect(json_response['individual_note']).to be(false)
    expect(json_response['notes'].first['type']).to eq('DiscussionNote')
  end
end
