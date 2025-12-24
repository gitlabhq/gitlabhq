# frozen_string_literal: true

# rubocop:disable RSpec/MultipleMemoizedHelpers -- Shared context provides fixtures for all group policy tests
RSpec.shared_context 'GroupPolicy context' do
  let_it_be(:organization) { create(:common_organization) }
  let_it_be(:group, refind: true) do
    create(:group, :private, :owner_subgroup_creation_only, :allow_runner_registration_token,
      organization: organization)
  end

  let_it_be(:subgroup) { create(:group, :private, parent: group) }

  let_it_be(:anonymous) { nil }
  let_it_be(:guest) { create(:user, guest_of: group) }
  let_it_be(:planner) { create(:user, planner_of: group) }
  let_it_be(:reporter) { create(:user, reporter_of: group) }
  let_it_be(:security_manager) { create(:user, security_manager_of: group) }
  let_it_be(:developer) { create(:user, developer_of: group) }
  let_it_be(:maintainer) { create(:user, maintainer_of: group) }
  let_it_be(:owner) { create(:user, owner_of: group) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:non_group_member) { create(:user) }
  let_it_be(:external_user) { create(:user, :external) }
  let_it_be(:subgroup_guest) { create(:user, guest_of: subgroup) }
  let_it_be(:subgroup_maintainer) { create(:user, maintainer_of: subgroup) }

  let_it_be(:organization_owner) { create(:organization_user, :owner, organization: organization).user }

  let(:public_anonymous_permissions) do
    %i[
      read_counts
      read_group
      read_group_activity
      read_group_boards
      read_group_issues
      read_group_labels
      read_group_merge_requests
      read_group_metadata
      read_group_milestones
      read_issue
      read_issue_board
      read_issue_board_list
      read_label
      read_milestone
      read_namespace
    ]
  end

  let(:public_permissions) do
    (public_anonymous_permissions + %i[upload_file]).uniq
  end

  let(:guest_permissions) do
    (public_permissions + %i[read_namespace_via_membership]).uniq
  end

  let(:planner_permissions) do
    (
      guest_permissions + %i[
        admin_issue
        admin_issue_board
        admin_issue_board_list
        admin_label
        admin_milestone
        admin_work_item
        destroy_issue
        read_confidential_issues
        read_crm_contact
        read_crm_organization
        read_internal_note
        update_issue
      ]
    ).uniq
  end

  let(:reporter_permissions) do
    (
      guest_permissions + %i[
        admin_issue
        admin_issue_board
        admin_issue_board_list
        admin_label
        admin_milestone
        admin_work_item
        read_ci_cd_analytics
        read_confidential_issues
        read_container_image
        read_crm_contact
        read_crm_organization
        read_harbor_registry
        read_internal_note
        read_prometheus
        update_issue
      ]
    ).uniq
  end

  let(:security_manager_permissions) do
    (reporter_permissions + %i[security_manager_access]).uniq
  end

  let(:developer_permissions) do
    (
      reporter_permissions + %i[
        create_custom_emoji
        create_package
        create_observability_access_request
        update_o11y_settings
        delete_o11y_settings
        read_cluster
        read_observability_portal
      ]
    ).uniq
  end

  let(:maintainer_permissions) do
    (
      developer_permissions + %i[
        destroy_package
        create_projects
        create_cluster update_cluster admin_cluster add_cluster
        admin_upload destroy_upload
        admin_achievement
        award_achievement
        read_runners
        admin_push_rules
      ]
    ).uniq
  end

  let(:owner_permissions) do
    (
      maintainer_permissions + security_manager_permissions + %i[
        owner_access
        admin_cicd_variables
        admin_group
        admin_namespace
        admin_group_member
        admin_package
        admin_runners
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
        set_issue_updated_at
        set_issue_created_at
        activate_group_member
        archive_group
      ]
    ).uniq
  end

  let(:admin_permissions) do
    (owner_permissions + %i[admin_organization read_confidential_issues read_internal_note]).uniq
  end

  let(:all_permissions) do
    (
      admin_permissions +
      owner_permissions +
      maintainer_permissions +
      developer_permissions +
      reporter_permissions +
      security_manager_permissions +
      planner_permissions +
      guest_permissions +
      public_permissions +
      public_anonymous_permissions
    ).uniq
  end

  subject { described_class.new(current_user, group) }
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
