# frozen_string_literal: true

# Requires from the caller:
#   work_item          - the noteable, readable by `user`
#   path_for           - lambda building the request path from a work item
#   user               - a reporter on the work item's parent
#   owner              - an owner of the work item's parent (may set created_at)
#   non_member         - a user with no membership on the parent
#   locked_work_item   - a work item with a locked discussion in a public parent
#   quick_action_label - a label named 'bug' that is visible to the work item
RSpec.shared_examples 'a work item endpoint creating a note' do
  let(:api_request_path) { path_for.call(work_item) }
  let(:params) { { body: 'hi!' } }

  it 'creates a note on the work item', :aggregate_failures do
    expect { post api(api_request_path, user), params: params }.to change { work_item.notes.count }.by(1)

    expect(response).to have_gitlab_http_status(:created)
    expect(json_response['body']).to eq('hi!')
    expect(json_response['internal']).to be(false)
    expect(json_response['noteable_id']).to eq(work_item.id)
    expect(json_response['author']['username']).to eq(user.username)
  end

  it 'creates an internal note when internal is true', :aggregate_failures do
    post api(api_request_path, user), params: params.merge(internal: true)

    expect(response).to have_gitlab_http_status(:created)
    expect(json_response['internal']).to be(true)
    expect(json_response['confidential']).to be(true)
  end

  it 'returns 400 when body is missing' do
    post api(api_request_path, user)

    expect(response).to have_gitlab_http_status(:bad_request)
  end

  it 'returns 404 when the work item does not exist' do
    post api(api_request_path.sub("/#{work_item.iid}/", "/#{non_existing_record_iid}/"), user), params: params

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns forbidden when the feature flag is disabled' do
    stub_feature_flags(work_item_rest_api: false)

    post api(api_request_path, user), params: params

    expect(response).to have_gitlab_http_status(:forbidden)
  end

  it 'returns unauthorized when no token is provided' do
    post api(api_request_path), params: params

    expect(response).to have_gitlab_http_status(:unauthorized)
  end

  it 'returns not_found when the user cannot read the work item' do
    post api(api_request_path, non_member), params: params

    expect(response).to have_gitlab_http_status(:not_found)
  end

  context 'when the discussion is locked' do
    it 'returns forbidden for a non-member', :aggregate_failures do
      expect { post api(path_for.call(locked_work_item), non_member), params: params }
        .not_to change { locked_work_item.notes.count }

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  context 'when setting created_at' do
    let(:creation_time) { 2.weeks.ago }
    let(:params) { { body: 'hi!', created_at: creation_time } }

    it 'sets the creation time for an owner', :aggregate_failures do
      post api(api_request_path, owner), params: params

      expect(response).to have_gitlab_http_status(:created)
      expect(Time.parse(json_response['created_at'])).to be_like_time(creation_time)
      expect(Time.parse(json_response['updated_at'])).to be_like_time(creation_time)
    end

    it 'ignores created_at for a reporter', :aggregate_failures do
      post api(api_request_path, user), params: params

      expect(response).to have_gitlab_http_status(:created)
      expect(Time.parse(json_response['created_at'])).not_to be_like_time(creation_time)
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

    it 'returns too_many_requests' do
      post api(api_request_path, user), params: params

      expect(response).to have_gitlab_http_status(:too_many_requests)
    end
  end
end
