# frozen_string_literal: true

# Requires:
# - `user`, `parent_work_item`, `child` (a work item that can validly become a child, not yet attached)
# - `path_for` - proc accepting `work_item_iid:` and `child_id:`, returning the full request path
# - `api_request_path` - `path_for` called with `parent_work_item.iid` and `child.id`
# - `already_attached_child` - a work item already attached as a child of `parent_work_item`
# - `other_parent_work_item` - a different, valid parent for `child`
# - `cross_boundary_child_work_item` - a valid, unattached child living in a different project than `child`
# - `unreadable_child_work_item` - a valid child type the current user cannot admin
# - `invalid_hierarchy_child_work_item` - a work item whose type cannot be a child of `parent_work_item`
# - `confidential_parent_work_item` - a confidential work item of a type valid as `child`'s parent
RSpec.shared_examples 'attach child work item endpoint' do
  let(:api_request_path) { path_for.call(work_item_iid: parent_work_item.iid, child_id: child.id) }

  it 'attaches the child work item and returns it' do
    post api(api_request_path, user)

    expect(response).to have_gitlab_http_status(:created)
    expect(json_response).to include('id' => child.id, 'iid' => child.iid, 'global_id' => child.to_gid.to_s)
    expect(child.reload.work_item_parent).to eq(parent_work_item)
  end

  it 'attaches the child across projects' do
    path = path_for.call(work_item_iid: parent_work_item.iid, child_id: cross_boundary_child_work_item.id)
    post api(path, user)

    expect(response).to have_gitlab_http_status(:created)
    expect(cross_boundary_child_work_item.reload.work_item_parent).to eq(parent_work_item)
  end

  context 'when the child work item already has a different parent' do
    before do
      create(:parent_link, work_item: child, work_item_parent: other_parent_work_item)
    end

    it 're-parents the child' do
      post api(api_request_path, user)

      expect(response).to have_gitlab_http_status(:created)
      expect(child.reload.work_item_parent).to eq(parent_work_item)
    end
  end

  context 'when the user can read but not update the parent' do
    it 'returns 403 without disclosing whether the child exists' do
      missing_path = path_for.call(work_item_iid: parent_work_item.iid, child_id: non_existing_record_id)
      restricted_path = path_for.call(work_item_iid: parent_work_item.iid, child_id: unreadable_child_work_item.id)

      post api(missing_path, unauthorized_user)

      expect(response).to have_gitlab_http_status(:forbidden)

      post api(restricted_path, unauthorized_user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  it 'returns a conflict when the child work item is already a child of the parent' do
    path = path_for.call(work_item_iid: parent_work_item.iid, child_id: already_attached_child.id)

    post api(path, user)

    expect(response).to have_gitlab_http_status(:conflict)
  end

  it 'returns 404 when the parent work item does not exist' do
    path = path_for.call(work_item_iid: non_existing_record_iid, child_id: child.id)

    post api(path, user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when the child work item does not exist' do
    path = path_for.call(work_item_iid: parent_work_item.iid, child_id: non_existing_record_id)

    post api(path, user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when the user cannot admin the parent link on the child' do
    path = path_for.call(work_item_iid: parent_work_item.iid, child_id: unreadable_child_work_item.id)

    post api(path, user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'does not disclose whether an inaccessible child exists' do
    expected_message = 'No matching work item found. Make sure that you are adding a valid work item ID.'

    restricted_path = path_for.call(work_item_iid: parent_work_item.iid, child_id: unreadable_child_work_item.id)
    post api(restricted_path, user)

    expect(json_response['message']).to eq(expected_message)

    missing_path = path_for.call(work_item_iid: parent_work_item.iid, child_id: non_existing_record_id)
    post api(missing_path, user)

    expect(json_response['message']).to eq(expected_message)
  end

  it 'returns 422 for an invalid hierarchy' do
    path = path_for.call(work_item_iid: parent_work_item.iid, child_id: invalid_hierarchy_child_work_item.id)

    post api(path, user)

    expect(response).to have_gitlab_http_status(:unprocessable_entity)
  end

  it 'returns 422 when attaching a work item to itself' do
    path = path_for.call(work_item_iid: parent_work_item.iid, child_id: parent_work_item.id)
    post api(path, user)

    expect(response).to have_gitlab_http_status(:unprocessable_entity)
    expect(json_response['message']).to include('is not allowed to point to itself')
  end

  it 'returns 422 when the parent is confidential and the child is not' do
    path = path_for.call(work_item_iid: confidential_parent_work_item.iid, child_id: child.id)

    post api(path, user)

    expect(response).to have_gitlab_http_status(:unprocessable_entity)
    expect(json_response['message']).to include('cannot assign a non-confidential')
  end

  it 'returns 401 when the user is not logged in' do
    post api(api_request_path)

    expect(response).to have_gitlab_http_status(:unauthorized)
  end

  it 'returns 400 when child_id is not a number' do
    path = path_for.call(work_item_iid: parent_work_item.iid, child_id: 'not-a-number')

    post api(path, user)

    expect(response).to have_gitlab_http_status(:bad_request)
    expect(json_response['error']).to eq('child_id is invalid')
  end

  it 'returns forbidden when the feature flag is disabled' do
    stub_feature_flags(work_item_rest_api: false)

    post api(api_request_path, user)

    expect(response).to have_gitlab_http_status(:forbidden)
  end
end
