# frozen_string_literal: true

RSpec.shared_context 'GroupPolicy context' do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:group, refind: true) do
    create(:group, :private, :owner_subgroup_creation_only, :allow_runner_registration_token,
      organization: organization)
  end

  let_it_be(:guest) { create(:user, guest_of: group) }
  let_it_be(:planner) { create(:user, planner_of: group) }
  let_it_be(:reporter) { create(:user, reporter_of: group) }
  let_it_be(:developer) { create(:user, developer_of: group) }
  let_it_be(:maintainer) { create(:user, maintainer_of: group) }
  let_it_be(:owner) { create(:user, owner_of: group) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:non_group_member) { create(:user) }
  let_it_be(:external_user) { create(:user, :external) }

  let_it_be(:organization_owner) { create(:organization_user, :owner, organization: organization).user }

  let(:public_permissions) do
    %i[
      read_group read_counts read_issue read_namespace
      read_label read_issue_board_list read_milestone read_issue_board
      read_group_activity read_group_issues read_group_boards read_group_labels
      read_group_milestones read_group_merge_requests
    ]
  end

  let(:guest_permissions) do
    %i[
      read_label read_group upload_file read_namespace_via_membership read_group_activity
      read_group_issues read_group_boards read_group_labels read_group_milestones
      read_group_merge_requests
    ]
  end

  let(:planner_permissions) do
    guest_permissions + %i[
      admin_label admin_milestone admin_issue_board admin_issue_board_list
      admin_issue admin_work_item update_issue destroy_issue read_confidential_issues read_internal_note
      read_crm_contact read_crm_organization
    ]
  end

  let(:reporter_permissions) do
    %i[
      admin_label
      admin_milestone
      admin_issue_board
      admin_work_item
      read_container_image
      read_harbor_registry
      read_prometheus
      read_crm_contact
      read_crm_organization
      read_internal_note
      read_confidential_issues
    ]
  end

  let(:developer_permissions) do
    %i[
      create_custom_emoji
      create_package
      read_cluster
    ]
  end

  let(:maintainer_permissions) do
    %i[
      destroy_package
      create_projects
      create_cluster update_cluster admin_cluster add_cluster
      admin_upload destroy_upload
      admin_achievement
      award_achievement
      read_group_runners
      admin_push_rules
    ]
  end

  let(:owner_permissions) do
    %i[
      owner_access
      admin_cicd_variables
      admin_group
      admin_namespace
      admin_group_member
      admin_package
      admin_runner
      change_visibility_level
      set_note_created_at
      create_subgroup
      read_statistics
      update_default_branch_protection
      register_group_runners
      read_billing
      edit_billing
      destroy_issue
      admin_member_access_request
      update_git_access_protocol
      remove_group
      view_edit_page
      manage_merge_request_settings
      admin_integrations
    ]
  end

  let(:admin_permissions) { %i[admin_organization read_confidential_issues read_internal_note] }

  subject { described_class.new(current_user, group) }
end
