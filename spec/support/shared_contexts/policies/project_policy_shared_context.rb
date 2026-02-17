# frozen_string_literal: true

RSpec.shared_context 'ProjectPolicy context' do
  let_it_be_with_reload(:organization) { create(:common_organization) }
  let_it_be(:owner_namespace) { create(:user_namespace, organization: organization) }
  let_it_be_with_reload(:organization_owner) { create(:organization_user, :owner, organization: organization).user }
  let_it_be(:group, refind: true) { create(:group, :public, organization: organization) }

  let_it_be(:public_project_in_group, refind: true) { create(:project, :public, namespace: group) }
  let_it_be(:private_project_in_group, refind: true) { create(:project, :private, namespace: group) }

  let_it_be(:private_project, refind: true) { create(:project, :private, namespace: owner_namespace) }
  let_it_be(:internal_project, refind: true) { create(:project, :internal, namespace: owner_namespace) }
  let_it_be(:public_project, refind: true) { create(:project, :public, namespace: owner_namespace) }

  let_it_be(:direct_member_projects) do
    [private_project, internal_project, public_project, public_project_in_group]
  end

  let_it_be(:anonymous) { nil }
  let_it_be_with_reload(:guest) { create(:user, guest_of: direct_member_projects) }
  let_it_be_with_reload(:planner) { create(:user, planner_of: direct_member_projects) }
  let_it_be_with_reload(:reporter) { create(:user, reporter_of: direct_member_projects) }
  let_it_be_with_reload(:security_manager) { create(:user, security_manager_of: direct_member_projects) }
  let_it_be_with_reload(:developer) { create(:user, developer_of: direct_member_projects) }
  let_it_be_with_reload(:maintainer) { create(:user, maintainer_of: direct_member_projects) }
  let_it_be_with_reload(:owner) { create(:user, namespace: owner_namespace, owner_of: direct_member_projects) }
  let_it_be_with_reload(:admin) { create(:admin) }
  let_it_be_with_reload(:non_member) { create(:user) }

  let_it_be_with_reload(:inherited_guest) { create(:user, guest_of: group) }
  let_it_be_with_reload(:inherited_planner) { create(:user, planner_of: group) }
  let_it_be_with_reload(:inherited_reporter) { create(:user, reporter_of: group) }
  let_it_be_with_reload(:inherited_security_manager) { create(:user, security_manager_of: group) }
  let_it_be_with_reload(:inherited_developer) { create(:user, developer_of: group) }
  let_it_be_with_reload(:inherited_maintainer) { create(:user, maintainer_of: group) }
  let_it_be_with_reload(:inherited_owner) { create(:user, owner_of: group) }

  let(:base_guest_permissions) do
    %i[
      award_emoji
      create_issue
      create_note
      export_work_items
      read_issue
      read_issue_board
      read_issue_board_list
      read_issue_iid
      read_issue_link
      read_label
      read_milestone
      read_note
      read_project
      read_project_for_iids
      read_project_member
      read_project_metadata
      read_release
      read_snippet
      read_wiki
      upload_file
    ]
  end

  let(:planner_permissions) do
    base_guest_permissions +
      %i[
        admin_issue
        admin_issue_board
        admin_issue_board_list
        admin_label
        admin_milestone
        admin_wiki
        admin_work_item
        create_wiki
        destroy_issue
        download_wiki_code
        read_confidential_issues
        read_internal_note
        reopen_issue
        update_issue
      ]
  end

  let(:base_reporter_permissions) do
    %i[
      admin_issue
      admin_issue_board_list
      admin_label
      admin_milestone
      admin_work_item
      create_incident
      create_merge_request_in
      create_snippet
      daily_statistics
      download_code
      download_wiki_code
      fork_project
      metrics_dashboard
      read_build
      read_commit_status
      read_confidential_issues
      read_container_image
      read_deployment
      read_environment
      read_external_emails
      read_harbor_registry
      read_internal_note
      read_merge_request
      read_pipeline
      read_prometheus
      read_sentry_issue
      update_issue
    ]
  end

  let(:base_security_manager_permissions) do
    %i[
      security_manager_access
      access_security_and_compliance
      cancel_build
      create_build
      read_runners
      read_security_configuration
    ]
  end

  let(:team_member_reporter_permissions) do
    %i[
      build_download_code
      build_read_container_image
    ]
  end

  let(:developer_permissions) do
    %i[
      access_security_and_compliance
      admin_merge_request
      admin_tag
      cancel_build
      create_build
      create_commit_status
      create_container_image
      create_deployment
      create_environment
      create_merge_request_from
      create_pipeline
      create_release
      create_wiki
      destroy_container_image
      destroy_container_image_tag
      destroy_release
      push_code
      read_pod_logs
      read_resource_group
      read_terraform_state
      read_security_configuration
      resolve_note
      update_build
      update_container_image
      update_deployment
      update_environment
      update_escalation_status
      update_merge_request
      update_pipeline
      update_release
      update_resource_group
    ]
  end

  let(:base_maintainer_permissions) do
    %i[
      add_cluster
      admin_build
      admin_cicd_variables
      admin_container_image
      admin_deployment
      admin_environment
      admin_integrations
      admin_member_access_request
      admin_note
      admin_pipeline
      admin_project
      admin_project_member
      admin_protected_branch
      admin_push_rules
      admin_runners
      admin_snippet
      admin_terraform_state
      admin_upload
      admin_wiki
      create_deploy_token
      create_protected_branch
      destroy_deploy_token
      destroy_upload
      manage_deploy_tokens
      manage_merge_request_settings
      manage_protected_tags
      push_to_delete_protected_branch
      read_deploy_token
      read_member_access_request
      rename_project
      read_runners
      update_snippet
    ]
  end

  let(:public_permissions) do
    %i[
      build_download_code
      build_read_container_image
      create_merge_request_in
      download_code
      download_wiki_code
      fork_project
      read_commit_status
      read_container_image
      read_pipeline
      read_release
    ]
  end

  let(:base_owner_permissions) do
    %i[
      archive_project
      change_namespace
      change_visibility_level
      create_group_link
      delete_group_link
      destroy_issue
      destroy_merge_request
      manage_owners
      remove_fork_project
      remove_project
      set_issue_created_at
      set_issue_iid
      set_issue_updated_at
      set_note_created_at
      update_group_link
    ]
  end

  let(:admin_permissions) do
    %i[
      admin_remote_mirror
      delete_custom_attribute
      owner_access
      read_custom_attribute
      read_internal_note
      read_project_for_iids
      read_storage_disk_path
      update_custom_attribute
      update_max_artifacts_size
    ]
  end

  let(:organization_owner_permissions) do
    %i[
      admin_remote_mirror
      owner_access
    ]
  end

  # Used in EE specs
  let(:additional_guest_permissions) { [] }
  let(:additional_reporter_permissions) { [] }
  let(:additional_security_manager_permissions) { [] }
  let(:additional_maintainer_permissions) { [] }
  let(:additional_owner_permissions) { [] }

  let(:guest_permissions) { base_guest_permissions + additional_guest_permissions }
  let(:reporter_permissions) { base_reporter_permissions + additional_reporter_permissions }
  let(:security_manager_permissions) { base_security_manager_permissions + additional_security_manager_permissions }
  let(:maintainer_permissions) { base_maintainer_permissions + additional_maintainer_permissions }
  let(:owner_permissions) { base_owner_permissions + additional_owner_permissions }
end
