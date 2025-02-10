# frozen_string_literal: true

RSpec.shared_examples 'checks abilities for project level work items' do
  it 'checks guest abilities' do
    # allowed
    expect(permissions(guest, not_persisted_project_work_item)).to be_allowed(
      :read_work_item, :read_issue, :read_note, :admin_parent_link, :set_work_item_metadata,
      :admin_work_item_link, :create_note
    )
    expect(permissions(guest, project_work_item)).to be_allowed(
      :read_work_item, :read_issue, :read_note, :admin_parent_link, :admin_work_item_link, :create_note
    )
    expect(permissions(guest_author, authored_project_work_item)).to be_allowed(
      :read_work_item, :read_issue, :read_note, :update_work_item, :delete_work_item, :admin_parent_link,
      :admin_work_item_link, :create_note
    )
    expect(permissions(guest_author, authored_project_confidential_work_item)).to be_allowed(
      :read_work_item, :read_issue, :read_note, :update_work_item, :delete_work_item, :admin_parent_link,
      :admin_work_item_link, :create_note
    )

    # disallowed
    expect(permissions(guest, project_work_item)).to be_disallowed(
      :admin_work_item, :update_work_item, :delete_work_item, :set_work_item_metadata, :move_work_item, :clone_work_item
    )
    expect(permissions(guest, project_confidential_work_item)).to be_disallowed(
      :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :delete_work_item,
      :set_work_item_metadata, :create_note, :move_work_item, :clone_work_item
    )
    expect(permissions(guest_author, authored_project_work_item)).to be_disallowed(
      :admin_work_item, :set_work_item_metadata, :move_work_item, :clone_work_item
    )
    expect(permissions(guest_author, authored_project_confidential_work_item)).to be_disallowed(
      :admin_work_item, :set_work_item_metadata, :move_work_item, :clone_work_item
    )
  end

  it 'checks planner abilities' do
    # allowed
    expect(permissions(planner, project_work_item)).to be_allowed(
      :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :admin_parent_link,
      :set_work_item_metadata, :admin_work_item_link, :create_note, :move_work_item, :clone_work_item
    )
    expect(permissions(planner, project_confidential_work_item)).to be_allowed(:read_work_item, :read_issue,
      :read_note, :admin_work_item, :update_work_item, :admin_parent_link, :set_work_item_metadata,
      :admin_work_item_link, :create_note, :move_work_item, :clone_work_item
    )

    # disallowed
    expect(permissions(planner, project_work_item)).to be_allowed(:delete_work_item)
    expect(permissions(planner, project_confidential_work_item)).to be_allowed(:delete_work_item)
  end

  it 'checks group planner abilities' do
    # allowed
    expect(permissions(group_planner, project_work_item)).to be_allowed(
      :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :admin_parent_link,
      :set_work_item_metadata, :admin_work_item_link, :create_note, :move_work_item, :clone_work_item
    )
    expect(permissions(group_planner, project_confidential_work_item)).to be_allowed(:read_work_item,
      :read_issue, :read_note, :admin_work_item, :update_work_item, :admin_parent_link, :set_work_item_metadata,
      :admin_work_item_link, :create_note, :move_work_item, :clone_work_item
    )

    # disallowed
    expect(permissions(group_planner, project_work_item)).to be_allowed(:delete_work_item)
    expect(permissions(group_planner, project_confidential_work_item)).to be_allowed(:delete_work_item)
  end

  it 'checks reporter abilities' do
    # allowed
    expect(permissions(reporter, project_work_item)).to be_allowed(
      :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :admin_parent_link,
      :set_work_item_metadata, :admin_work_item_link, :create_note, :move_work_item, :clone_work_item
    )
    expect(permissions(reporter, project_confidential_work_item)).to be_allowed(:read_work_item, :read_issue,
      :read_note, :admin_work_item, :update_work_item, :admin_parent_link, :set_work_item_metadata,
      :admin_work_item_link, :create_note, :move_work_item, :clone_work_item
    )

    # disallowed
    expect(permissions(reporter, project_work_item)).to be_disallowed(:delete_work_item)
    expect(permissions(reporter, project_confidential_work_item)).to be_disallowed(:delete_work_item)
  end

  it 'checks group reporter abilities' do
    # allowed
    expect(permissions(group_reporter, project_work_item)).to be_allowed(
      :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :admin_parent_link,
      :set_work_item_metadata, :admin_work_item_link, :create_note, :move_work_item, :clone_work_item
    )
    expect(permissions(group_reporter, project_confidential_work_item)).to be_allowed(:read_work_item,
      :read_issue, :read_note, :admin_work_item, :update_work_item, :admin_parent_link, :set_work_item_metadata,
      :admin_work_item_link, :create_note, :move_work_item, :clone_work_item
    )

    # disallowed
    expect(permissions(group_reporter, project_work_item)).to be_disallowed(:delete_work_item)
    expect(permissions(group_reporter, project_confidential_work_item)).to be_disallowed(:delete_work_item)
  end
end
