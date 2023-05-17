# frozen_string_literal: true

RSpec.shared_context 'GroupPolicy context' do
  let_it_be(:guest) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:owner) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:non_group_member) { create(:user) }
  let_it_be(:group, refind: true) { create(:group, :private, :owner_subgroup_creation_only, :crm_enabled) }

  let(:public_permissions) do
    %i[
      read_group read_counts
      read_label read_issue_board_list read_milestone read_issue_board
    ]
  end

  let(:guest_permissions) do
    %i[
      read_label read_group upload_file read_namespace read_group_activity
      read_group_issues read_group_boards read_group_labels read_group_milestones
      read_group_merge_requests
    ]
  end

  let(:reporter_permissions) do
    %i[
      admin_label
      admin_milestone
      admin_issue_board
      read_container_image
      read_harbor_registry
      read_metrics_dashboard_annotation
      read_prometheus
      read_crm_contact
      read_crm_organization
      read_internal_note
    ]
  end

  let(:developer_permissions) do
    %i[
      admin_metrics_dashboard_annotation
      create_custom_emoji
      create_package
      read_cluster
    ]
  end

  let(:maintainer_permissions) do
    %i[
      destroy_package
      admin_package
      create_projects
      create_cluster update_cluster admin_cluster add_cluster
      destroy_upload
      admin_achievement
      award_achievement
    ]
  end

  let(:owner_permissions) do
    %i[
      owner_access
      admin_group
      admin_namespace
      admin_group_member
      change_visibility_level
      set_note_created_at
      create_subgroup
      read_statistics
      update_default_branch_protection
      read_group_runners
      admin_group_runners
      register_group_runners
      read_billing
      edit_billing
      admin_member_access_request
    ]
  end

  let(:admin_permissions) { %i[read_confidential_issues read_internal_note] }

  before_all do
    group.add_guest(guest)
    group.add_reporter(reporter)
    group.add_developer(developer)
    group.add_maintainer(maintainer)
    group.add_owner(owner)
  end

  subject { described_class.new(current_user, group) }
end
