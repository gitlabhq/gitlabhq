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
      :admin_work_item, :update_work_item, :delete_work_item, :set_work_item_metadata, :move_work_item,
      :clone_work_item, :summarize_comments
    )
    expect(permissions(guest, project_confidential_work_item)).to be_disallowed(
      :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :delete_work_item,
      :set_work_item_metadata, :create_note, :move_work_item, :clone_work_item, :summarize_comments
    )
    expect(permissions(guest_author, authored_project_work_item)).to be_disallowed(
      :admin_work_item, :set_work_item_metadata, :move_work_item, :clone_work_item, :summarize_comments
    )
    expect(permissions(guest_author, authored_project_confidential_work_item)).to be_disallowed(
      :admin_work_item, :set_work_item_metadata, :move_work_item, :clone_work_item, :summarize_comments
    )

    expect(permissions(guest, incident_work_item)).to be_disallowed(
      :admin_work_item, :update_work_item, :set_work_item_metadata, :delete_work_item
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
    expect(permissions(planner, incident_work_item)).to be_disallowed(
      :admin_work_item, :update_work_item, :set_work_item_metadata, :delete_work_item
    )
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

    expect(permissions(reporter, incident_work_item)).to be_allowed(
      :admin_work_item, :update_work_item, :set_work_item_metadata
    )

    # disallowed
    expect(permissions(reporter, project_work_item)).to be_disallowed(:delete_work_item, :summarize_comments)
    expect(permissions(reporter, project_confidential_work_item)).to be_disallowed(
      :delete_work_item, :summarize_comments
    )
    expect(permissions(reporter, incident_work_item)).to be_disallowed(:delete_work_item, :summarize_comments)
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
    expect(permissions(group_reporter, project_work_item)).to be_disallowed(:delete_work_item, :summarize_comments)
    expect(permissions(group_reporter, project_confidential_work_item))
      .to be_disallowed(:delete_work_item, :summarize_comments)
  end
end

RSpec.shared_examples 'prevents access to project-level {issues|work_items} with type Epic' do |factory|
  context 'with Epic work item type' do
    let_it_be(:with_epic_type) do
      create(
        factory,
        work_item_type: WorkItems::Type.default_by_type(:epic),
        project: project,
        assignees: [assignee],
        author: author
      )
    end

    let(:work_item_permissions) do
      %i[delete_work_item set_work_item_metadata admin_work_item_link admin_parent_link move_work_item clone_work_item]
    end

    let(:issue_permissions) do
      %i[
        read_cross_project admin_all_resources read_all_resources change_repository_storage resolve_note read_issue
        update_issue reopen_issue update_merge_request reopen_merge_request create_note admin_note award_emoji
        read_incident_management_timeline_event admin_incident_management_timeline_event create_timelog read_issuable
        read_issuable_participables read_note ead_internal_note set_note_created_at mark_note_as_internal
        reposition_note create_issue admin_issue destroy_issue read_issue_iid read_design create_design update_design
        destroy_design move_design create_todo update_subscription set_issue_metadata admin_issue_link
        set_confidentiality admin_issue_relation read_crm_contacts set_issue_crm_contacts move_issue clone_issue
        read_work_item create_work_item update_work_item admin_work_item destroy_work_item
      ]
    end

    let(:abilities) { factory == :work_item ? issue_permissions.append(*work_item_permissions) : issue_permissions }

    it "does not allow anonymous any access to the #{factory}" do
      expect(permissions(nil, with_epic_type)).to be_disallowed(*abilities)
    end

    where(role: %w[guest planner reporter owner admin assignee author support_bot])

    with_them do
      let(:current_user) { public_send(role) }

      it "does not allow user any access to the #{factory}" do
        expect(permissions(current_user, with_epic_type)).to be_disallowed(*abilities)
      end
    end
  end
end
