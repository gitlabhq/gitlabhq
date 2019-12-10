# frozen_string_literal: true

RSpec.shared_context 'ProjectPolicy context' do
  set(:guest) { create(:user) }
  set(:reporter) { create(:user) }
  set(:developer) { create(:user) }
  set(:maintainer) { create(:user) }
  set(:owner) { create(:user) }
  set(:admin) { create(:admin) }
  let(:project) { create(:project, :public, namespace: owner.namespace) }

  let(:base_guest_permissions) do
    %i[
      read_project read_board read_list read_wiki read_issue
      read_project_for_iids read_issue_iid read_label
      read_milestone read_project_snippet read_project_member read_note
      create_project create_issue create_note upload_file create_merge_request_in
      award_emoji
    ]
  end

  let(:base_reporter_permissions) do
    %i[
      download_code fork_project create_project_snippet update_issue
      admin_issue admin_label admin_list read_commit_status read_build
      read_container_image read_pipeline read_environment read_deployment
      read_merge_request download_wiki_code read_sentry_issue read_prometheus
    ]
  end

  let(:team_member_reporter_permissions) do
    %i[build_download_code build_read_container_image]
  end

  let(:developer_permissions) do
    %i[
      admin_milestone admin_merge_request update_merge_request create_commit_status
      update_commit_status create_build update_build create_pipeline
      update_pipeline create_merge_request_from create_wiki push_code
      resolve_note create_container_image update_container_image
      create_environment create_deployment update_deployment create_release update_release
      update_environment
    ]
  end

  let(:base_maintainer_permissions) do
    %i[
      push_to_delete_protected_branch update_project_snippet
      admin_project_snippet admin_project_member admin_note admin_wiki admin_project
      admin_commit_status admin_build admin_container_image
      admin_pipeline admin_environment admin_deployment destroy_release add_cluster
      daily_statistics
    ]
  end

  let(:public_permissions) do
    %i[
      download_code fork_project read_commit_status read_pipeline
      read_container_image build_download_code build_read_container_image
      download_wiki_code read_release
    ]
  end

  let(:base_owner_permissions) do
    %i[
      change_namespace change_visibility_level rename_project remove_project
      archive_project remove_fork_project destroy_merge_request destroy_issue
      set_issue_iid set_issue_created_at set_issue_updated_at set_note_created_at
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

  before do
    project.add_guest(guest)
    project.add_maintainer(maintainer)
    project.add_developer(developer)
    project.add_reporter(reporter)
  end
end
