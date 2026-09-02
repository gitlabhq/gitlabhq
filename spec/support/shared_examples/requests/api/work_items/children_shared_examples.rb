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

  it 'ignores undeclared fields and features query params' do
    post api("#{api_request_path}?features=labels&fields[a]=b", user)

    expect(response).to have_gitlab_http_status(:created)
    expect(json_response.keys).to contain_exactly('id', 'iid', 'global_id', 'title')
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

# Requires:
# - `user`, `parent_work_item`, `attached_child` (a work item currently attached as a child of `parent_work_item`)
# - `path_for` - proc accepting `work_item_iid:` and `child_id:`, returning the full request path
# - `api_request_path` - `path_for` called with `parent_work_item.iid` and `attached_child.id`
# - `unauthorized_user` - a user who can read but not update the parent
# - `unreadable_child_work_item` - a work item currently attached as a child of `parent_work_item`
#   that the current user cannot admin
# - `unlinked_unreadable_child_work_item` - a work item the current user cannot admin, not attached
#   to `parent_work_item`
# - `cross_boundary_attached_child` - a work item living in a different project than `parent_work_item`,
#   currently attached as its child
# - `other_parent_work_item` - a different, valid parent for `attached_child`
RSpec.shared_examples 'detach child work item endpoint' do
  let(:api_request_path) { path_for.call(work_item_iid: parent_work_item.iid, child_id: attached_child.id) }

  it 'detaches the child work item' do
    delete api(api_request_path, user)

    expect(response).to have_gitlab_http_status(:no_content)
    expect(response.body).to be_empty
    expect(attached_child.reload.work_item_parent).to be_nil
  end

  it 'detaches the child across projects' do
    path = path_for.call(work_item_iid: parent_work_item.iid, child_id: cross_boundary_attached_child.id)

    delete api(path, user)

    expect(response).to have_gitlab_http_status(:no_content)
    expect(cross_boundary_attached_child.reload.work_item_parent).to be_nil
  end

  it 'returns 404 when re-detaching an already detached child' do
    delete api(api_request_path, user)
    expect(response).to have_gitlab_http_status(:no_content)

    delete api(api_request_path, user)
    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when the child is linked to a different parent' do
    path = path_for.call(work_item_iid: other_parent_work_item.iid, child_id: attached_child.id)

    delete api(path, user)

    expect(response).to have_gitlab_http_status(:not_found)
    expect(attached_child.reload.work_item_parent).to eq(parent_work_item)
  end

  it 'returns 404 when the parent work item does not exist' do
    path = path_for.call(work_item_iid: non_existing_record_iid, child_id: attached_child.id)

    delete api(path, user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when the child work item does not exist' do
    path = path_for.call(work_item_iid: parent_work_item.iid, child_id: non_existing_record_id)

    delete api(path, user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when child is not linked to a parent' do
    other_child = create(:work_item, :task, project: project)
    path = path_for.call(work_item_iid: parent_work_item.iid, child_id: other_child.id)

    delete api(path, user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when the user cannot admin the parent link on the child' do
    path = path_for.call(work_item_iid: parent_work_item.iid, child_id: unreadable_child_work_item.id)

    delete api(path, user)

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'does not disclose whether an inaccessible child exists' do
    expected_message = ::API::Helpers::WorkItems::HierarchyFinders::CHILD_NOT_FOUND_MESSAGE

    linked_path = path_for.call(work_item_iid: parent_work_item.iid, child_id: unreadable_child_work_item.id)
    delete api(linked_path, user)
    expect(json_response['message']).to eq(expected_message)

    unlinked_path =
      path_for.call(work_item_iid: parent_work_item.iid, child_id: unlinked_unreadable_child_work_item.id)
    delete api(unlinked_path, user)
    expect(json_response['message']).to eq(expected_message)

    missing_path = path_for.call(work_item_iid: parent_work_item.iid, child_id: non_existing_record_id)
    delete api(missing_path, user)
    expect(json_response['message']).to eq(expected_message)
  end

  it 'returns 403 when the user cannot update the parent' do
    delete api(api_request_path, unauthorized_user)

    expect(response).to have_gitlab_http_status(:forbidden)
  end

  it 'returns 401 when the user is not logged in' do
    delete api(api_request_path)

    expect(response).to have_gitlab_http_status(:unauthorized)
  end

  it 'returns 400 when child_id is not a number' do
    path = path_for.call(work_item_iid: parent_work_item.iid, child_id: 'not-a-number')

    delete api(path, user)

    expect(response).to have_gitlab_http_status(:bad_request)
    expect(json_response['error']).to eq('child_id is invalid')
  end

  it 'returns forbidden when the feature flag is disabled' do
    stub_feature_flags(work_item_rest_api: false)

    delete api(api_request_path, user)

    expect(response).to have_gitlab_http_status(:forbidden)
  end
end

# Requires:
# - `user`, `parent_work_item` and its existing children `first_child`, `second_child`, `closed_child`,
#   with relative positions in that order (see the top-level `before_all` in children_spec.rb)
# - `path_for` - proc accepting `work_item_iid:` and `child_id:`, returning the full request path
# - `unauthorized_user` - a user who can read but not update `parent_work_item`
# - `non_sibling_work_item` - a valid work item that is not a child of `parent_work_item`
# - `unreadable_sibling_work_item` - a child of `parent_work_item` the current user can neither read nor admin
# - `cross_boundary_sibling_work_item` - a child of `parent_work_item` living in a different project
RSpec.shared_examples 'reorder child work item endpoint' do
  let(:api_request_path) { path_for.call(work_item_iid: parent_work_item.iid, child_id: second_child.id) }

  def sibling_order_for(parent_work_item)
    ::WorkItems::ParentLink
      .where(work_item_parent_id: parent_work_item.id, work_item_id: [first_child.id, second_child.id, closed_child.id])
      .order(:relative_position)
      .pluck(:work_item_id)
  end

  it 'moves the child before the given sibling and returns it' do
    # second_child (200) starts after first_child (100); moving it so first_child is
    # positioned *after* it swaps their order.
    put api(api_request_path, user), params: { move_after_id: first_child.id }

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response).to include('id' => second_child.id, 'iid' => second_child.iid,
      'global_id' => second_child.to_gid.to_s)
    expect(sibling_order_for(parent_work_item)).to eq([second_child.id, first_child.id, closed_child.id])
  end

  it 'moves the child after the given sibling' do
    # first_child (100) starts before second_child (200); moving it so second_child is
    # positioned *before* it swaps their order.
    path = path_for.call(work_item_iid: parent_work_item.iid, child_id: first_child.id)

    put api(path, user), params: { move_before_id: second_child.id }

    expect(response).to have_gitlab_http_status(:ok)
    expect(sibling_order_for(parent_work_item)).to eq([second_child.id, first_child.id, closed_child.id])
  end

  it 'prioritizes move_before_id when both move_before_id and move_after_id are given' do
    # move_before_id: closed_child would place second_child after closed_child (last);
    # move_after_id: first_child would place second_child before first_child (first).
    # move_before_id wins, so second_child ends up right after closed_child.
    put api(api_request_path, user), params: { move_before_id: closed_child.id, move_after_id: first_child.id }

    expect(response).to have_gitlab_http_status(:ok)
    expect(sibling_order_for(parent_work_item)).to eq([first_child.id, closed_child.id, second_child.id])
  end

  it 'returns 400 when neither move_before_id nor move_after_id is given' do
    put api(api_request_path, user)

    expect(response).to have_gitlab_http_status(:bad_request)
  end

  it 'returns 404 when the parent work item does not exist' do
    path = path_for.call(work_item_iid: non_existing_record_iid, child_id: second_child.id)

    put api(path, user), params: { move_before_id: first_child.id }

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when the child work item is not a child of the parent' do
    path = path_for.call(work_item_iid: parent_work_item.iid, child_id: non_sibling_work_item.id)

    put api(path, user), params: { move_before_id: first_child.id }

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when move_before_id does not reference a sibling' do
    put api(api_request_path, user), params: { move_before_id: non_sibling_work_item.id }

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 404 when move_before_id references a sibling the user cannot read' do
    put api(api_request_path, user), params: { move_before_id: unreadable_sibling_work_item.id }

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 403 when the user cannot update the parent' do
    put api(api_request_path, unauthorized_user), params: { move_before_id: first_child.id }

    expect(response).to have_gitlab_http_status(:forbidden)
  end

  it 'returns 404 when the user cannot admin the parent link on the sibling child' do
    path = path_for.call(work_item_iid: parent_work_item.iid, child_id: unreadable_sibling_work_item.id)

    put api(path, user), params: { move_before_id: first_child.id }

    expect(response).to have_gitlab_http_status(:not_found)
  end

  it 'returns 422 when the resulting parent-child link is invalid' do
    parent_work_item.update_column(:confidential, true)

    put api(api_request_path, user), params: { move_before_id: first_child.id }

    expect(response).to have_gitlab_http_status(:unprocessable_entity)
    expect(json_response['message']).to include('cannot assign a non-confidential')
  ensure
    # because parent_work_item is let_it_be defined object
    parent_work_item.update_column(:confidential, false)
  end

  it 'does not disclose whether an inaccessible or non-sibling work item exists' do
    expected_message = 'No matching work item found. Make sure that you are adding a valid work item ID.'

    missing_child_path = path_for.call(work_item_iid: parent_work_item.iid, child_id: non_existing_record_id)
    put api(missing_child_path, user), params: { move_before_id: first_child.id }
    expect(json_response['message']).to eq(expected_message)

    non_sibling_child_path = path_for.call(work_item_iid: parent_work_item.iid, child_id: non_sibling_work_item.id)
    put api(non_sibling_child_path, user), params: { move_before_id: first_child.id }
    expect(json_response['message']).to eq(expected_message)

    unreadable_sibling_path = path_for.call(work_item_iid: parent_work_item.iid,
      child_id: unreadable_sibling_work_item.id)
    put api(unreadable_sibling_path, user), params: { move_before_id: first_child.id }
    expect(json_response['message']).to eq(expected_message)

    put api(api_request_path, user), params: { move_before_id: non_sibling_work_item.id }
    expect(json_response['message']).to eq(expected_message)

    put api(api_request_path, user), params: { move_before_id: non_existing_record_id }
    expect(json_response['message']).to eq(expected_message)

    put api(api_request_path, user), params: { move_before_id: unreadable_sibling_work_item.id }
    expect(json_response['message']).to eq(expected_message)
  end

  it 'reorders the child relative to itself without error' do
    path = path_for.call(work_item_iid: parent_work_item.iid, child_id: first_child.id)

    put api(path, user), params: { move_before_id: first_child.id }

    expect(response).to have_gitlab_http_status(:ok)
    expect(sibling_order_for(parent_work_item)).to eq([first_child.id, second_child.id, closed_child.id])
  end

  it 'is idempotent when the same reorder is repeated' do
    put api(api_request_path, user), params: { move_after_id: first_child.id }

    expect(response).to have_gitlab_http_status(:ok)
    expect(sibling_order_for(parent_work_item)).to eq([second_child.id, first_child.id, closed_child.id])

    put api(api_request_path, user), params: { move_after_id: first_child.id }

    expect(response).to have_gitlab_http_status(:ok)
    expect(sibling_order_for(parent_work_item)).to eq([second_child.id, first_child.id, closed_child.id])
  end

  it 'reorders a sibling that lives in a different project than the parent' do
    path = path_for.call(work_item_iid: parent_work_item.iid, child_id: cross_boundary_sibling_work_item.id)

    put api(path, user), params: { move_before_id: first_child.id }

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response).to include('id' => cross_boundary_sibling_work_item.id)
  end

  it 'returns 401 when the user is not logged in' do
    put api(api_request_path), params: { move_before_id: first_child.id }

    expect(response).to have_gitlab_http_status(:unauthorized)
  end

  it 'returns 400 when child_id is not a number' do
    path = path_for.call(work_item_iid: parent_work_item.iid, child_id: 'not-a-number')

    put api(path, user), params: { move_before_id: first_child.id }

    expect(response).to have_gitlab_http_status(:bad_request)
  end

  it 'returns forbidden when the feature flag is disabled' do
    stub_feature_flags(work_item_rest_api: false)

    put api(api_request_path, user), params: { move_before_id: first_child.id }

    expect(response).to have_gitlab_http_status(:forbidden)
  end
end
