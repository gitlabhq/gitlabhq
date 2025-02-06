# frozen_string_literal: true

RSpec.shared_context 'ProjectPolicy context' do
  let_it_be(:anonymous) { nil }
  let_it_be_with_reload(:guest) { create(:user) }
  let_it_be_with_reload(:planner) { create(:user) }
  let_it_be_with_reload(:reporter) { create(:user) }
  let_it_be_with_reload(:developer) { create(:user) }
  let_it_be_with_reload(:maintainer) { create(:user) }
  let_it_be_with_reload(:inherited_guest) { create(:user) }
  let_it_be_with_reload(:inherited_planner) { create(:user) }
  let_it_be_with_reload(:inherited_reporter) { create(:user) }
  let_it_be_with_reload(:inherited_developer) { create(:user) }
  let_it_be_with_reload(:inherited_maintainer) { create(:user) }
  let_it_be_with_reload(:organization) { create(:organization) }
  let_it_be_with_reload(:owner) { create(:user, namespace: create(:user_namespace, organization: organization)) }
  let_it_be_with_reload(:organization_owner) { create(:user, :organization_owner, organizations: [organization]) }
  let_it_be_with_reload(:admin) { create(:admin) }
  let_it_be_with_reload(:non_member) { create(:user) }
  let_it_be_with_refind(:group) { create(:group, :public) }
  let_it_be_with_refind(:private_project) { create(:project, :private, namespace: owner.namespace) }
  let_it_be_with_refind(:internal_project) { create(:project, :internal, namespace: owner.namespace) }
  let_it_be_with_refind(:public_project) { create(:project, :public, namespace: owner.namespace) }
  let_it_be_with_refind(:public_project_in_group) { create(:project, :public, namespace: group) }
  let_it_be_with_refind(:private_project_in_group) { create(:project, :private, namespace: group) }

  let(:base_guest_permissions) do
    %i[
      award_emoji create_issue create_note
      create_project read_issue_board read_issue read_issue_iid read_issue_link
      read_label read_issue_board_list read_milestone read_note read_project
      read_project_for_iids read_project_member read_release read_snippet
      read_wiki upload_file
    ]
  end

  let(:planner_permissions) do
    base_guest_permissions +
      %i[
        admin_issue admin_work_item admin_issue_board admin_issue_board_list admin_label admin_milestone
        read_confidential_issues update_issue reopen_issue destroy_issue read_internal_note
        download_wiki_code create_wiki admin_wiki export_work_items
      ]
  end

  let(:base_reporter_permissions) do
    %i[
      admin_issue admin_work_item admin_label admin_milestone admin_issue_board_list
      create_snippet create_incident daily_statistics create_merge_request_in download_code
      download_wiki_code fork_project metrics_dashboard read_build
      read_commit_status read_confidential_issues read_container_image
      read_harbor_registry read_deployment read_environment read_merge_request
      read_pipeline read_prometheus
      read_sentry_issue update_issue create_merge_request_in
      read_external_emails read_internal_note export_work_items
    ]
  end

  let(:team_member_reporter_permissions) do
    %i[build_download_code build_read_container_image]
  end

  let(:developer_permissions) do
    %i[
      admin_merge_request admin_tag create_build
      create_commit_status create_container_image create_deployment
      create_environment create_merge_request_from
      create_pipeline create_release
      create_wiki destroy_container_image push_code read_pod_logs
      read_terraform_state resolve_note update_build cancel_build update_commit_status
      update_container_image update_deployment update_environment
      update_merge_request update_pipeline update_release destroy_release
      read_resource_group update_resource_group update_escalation_status
    ]
  end

  let(:base_maintainer_permissions) do
    %i[
      add_cluster admin_build admin_commit_status admin_container_image
      admin_cicd_variables admin_deployment admin_environment admin_note admin_pipeline
      admin_project admin_project_member admin_push_rules admin_runner admin_snippet admin_terraform_state
      admin_wiki create_deploy_token destroy_deploy_token manage_deploy_tokens
      push_to_delete_protected_branch read_deploy_token update_snippet
      admin_upload destroy_upload admin_member_access_request read_member_access_request rename_project
      manage_merge_request_settings admin_integrations create_protected_branch admin_protected_branch
      manage_protected_tags
    ]
  end

  let(:public_permissions) do
    %i[
      build_download_code build_read_container_image create_merge_request_in download_code
      download_wiki_code fork_project read_commit_status read_container_image
      read_pipeline read_release
    ]
  end

  let(:base_owner_permissions) do
    %i[
      archive_project change_namespace change_visibility_level destroy_issue
      destroy_merge_request manage_owners remove_fork_project remove_project
      set_issue_created_at set_issue_iid set_issue_updated_at
      set_note_created_at
    ]
  end

  let(:admin_permissions) do
    %i[
      read_project_for_iids update_max_artifacts_size read_storage_disk_path
      owner_access admin_remote_mirror read_internal_note
    ]
  end

  let(:organization_owner_permissions) do
    %i[
      owner_access admin_remote_mirror
    ]
  end

  # Used in EE specs
  let(:additional_guest_permissions) { [] }
  let(:additional_reporter_permissions) { [] }
  let(:additional_maintainer_permissions) { [] }
  let(:additional_owner_permissions) { [] }

  let(:guest_permissions) { base_guest_permissions + additional_guest_permissions }
  let(:reporter_permissions) { base_reporter_permissions + additional_reporter_permissions }
  let(:maintainer_permissions) { base_maintainer_permissions + additional_maintainer_permissions }
  let(:owner_permissions) { base_owner_permissions + additional_owner_permissions }

  before_all do
    group.add_guest(inherited_guest)
    group.add_planner(inherited_planner)
    group.add_reporter(inherited_reporter)
    group.add_developer(inherited_developer)
    group.add_maintainer(inherited_maintainer)

    [private_project, internal_project, public_project, public_project_in_group].each do |project|
      project.add_guest(guest)
      project.add_planner(planner)
      project.add_reporter(reporter)
      project.add_developer(developer)
      project.add_maintainer(maintainer)
      project.add_owner(owner)
    end
  end
end
