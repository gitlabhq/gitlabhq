# frozen_string_literal: true

RSpec.shared_context 'ProjectPolicy context' do
  let_it_be(:anonymous) { nil }
  let_it_be(:guest) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:owner) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:non_member) { create(:user) }
  let_it_be_with_refind(:private_project) { create(:project, :private, namespace: owner.namespace) }
  let_it_be_with_refind(:internal_project) { create(:project, :internal, namespace: owner.namespace) }
  let_it_be_with_refind(:public_project) { create(:project, :public, namespace: owner.namespace) }

  let(:base_guest_permissions) do
    %i[
      award_emoji create_issue create_incident create_merge_request_in create_note
      create_project read_issue_board read_issue read_issue_iid read_issue_link
      read_label read_issue_board_list read_milestone read_note read_project
      read_project_for_iids read_project_member read_release read_snippet
      read_wiki upload_file
    ]
  end

  let(:base_reporter_permissions) do
    %i[
      admin_issue admin_issue_link admin_label admin_issue_board_list create_snippet
      daily_statistics download_code download_wiki_code fork_project metrics_dashboard
      read_build read_commit_status read_confidential_issues
      read_container_image read_deployment read_environment read_merge_request
      read_metrics_dashboard_annotation read_pipeline read_prometheus
      read_sentry_issue update_issue
    ]
  end

  let(:team_member_reporter_permissions) do
    %i[build_download_code build_read_container_image]
  end

  let(:developer_permissions) do
    %i[
      admin_merge_request admin_milestone admin_tag create_build
      create_commit_status create_container_image create_deployment
      create_environment create_merge_request_from
      create_metrics_dashboard_annotation create_pipeline create_release
      create_wiki delete_metrics_dashboard_annotation
      destroy_container_image push_code read_pod_logs read_terraform_state
      resolve_note update_build update_commit_status update_container_image
      update_deployment update_environment update_merge_request
      update_metrics_dashboard_annotation update_pipeline update_release destroy_release
    ]
  end

  let(:base_maintainer_permissions) do
    %i[
      add_cluster admin_build admin_commit_status admin_container_image
      admin_deployment admin_environment admin_note admin_pipeline
      admin_project admin_project_member admin_snippet admin_terraform_state
      admin_wiki create_deploy_token destroy_deploy_token
      push_to_delete_protected_branch read_deploy_token update_snippet
    ]
  end

  let(:public_permissions) do
    %i[
      build_download_code build_read_container_image download_code
      download_wiki_code fork_project read_commit_status read_container_image
      read_pipeline read_release
    ]
  end

  let(:base_owner_permissions) do
    %i[
      archive_project change_namespace change_visibility_level destroy_issue
      destroy_merge_request remove_fork_project remove_project rename_project
      set_issue_created_at set_issue_iid set_issue_updated_at
      set_note_created_at
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
    [private_project, internal_project, public_project].each do |project|
      project.add_guest(guest)
      project.add_reporter(reporter)
      project.add_developer(developer)
      project.add_maintainer(maintainer)
    end
  end
end
