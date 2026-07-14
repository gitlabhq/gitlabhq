# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::Role, feature_category: :permissions do
  shared_examples 'a role that does not enable unexpected permissions' do
    before do
      # Ensure design_management_enabled? returns true so read_design/read_design_activity
      # (granted via can?(:read_issue) in ProjectPolicy) are consistently exercisable.
      # Project#lfs_enabled? checks both self[:lfs_enabled] and Gitlab.config.lfs.enabled,
      # so we must stub the global config in addition to setting lfs_enabled: true on the project.
      stub_lfs_setting(enabled: true)

      next unless Gitlab.ee?

      stub_licensed_features(GitlabSubscriptions::Features::ALL_FEATURES.index_with(true))
    end

    let(:all_permissions) do
      case scope
      when :project then ProjectPolicy.own_ability_map.map.keys
      when :group then GroupPolicy.own_ability_map.map.keys
      end
    end

    let(:role_permissions) { described_class.get(role).permissions(scope).to_a }
    let(:permissions_granted_outside_role_definition) { [] }

    # permissions_granted_outside_role_definition, with the EE-only permissions removed when
    # not running in EE.
    let(:available_permissions_granted_outside_role_definition) do
      next permissions_granted_outside_role_definition if Gitlab.ee?

      permissions_granted_outside_role_definition - ee_permissions
    end

    it 'does not enable permissions outside its role definition' do
      unexpected_permissions = all_permissions -
        role_permissions -
        available_permissions_granted_outside_role_definition

      enabled_unexpected_permissions =
        unexpected_permissions.select { |permission| actor.can?(permission, resource) }

      expect(enabled_unexpected_permissions).to be_empty,
        "The #{role} role is granted #{scope} permissions that are not in its role definition: " \
          "#{enabled_unexpected_permissions.sort.join(', ')}. Add them to " \
          "config/authz/roles/#{role}.yml, restrict the policy so the role is not granted the " \
          "permissions, or (if an intentional grant) add them to " \
          "permissions_granted_outside_role_definition."
    end

    it 'grants every permission it lists as granted outside its role definition' do
      checkable = available_permissions_granted_outside_role_definition & all_permissions
      not_granted = checkable.reject { |permission| actor.can?(permission, resource) }

      expect(not_granted).to be_empty,
        "The #{role} role's permissions_granted_outside_role_definition for #{scope} lists permissions " \
          "it cannot actually exercise: #{not_granted.sort.join(', ')}. Remove them if they're stale, " \
          "or check whether the policy rule that was supposed to grant them changed."
    end

    it 'does not list permissions already covered by its role definition' do
      redundant = permissions_granted_outside_role_definition & role_permissions

      expect(redundant).to be_empty,
        "The #{role} role's permissions_granted_outside_role_definition for #{scope} duplicates " \
          "permissions already in config/authz/roles/#{role}.yml: #{redundant.sort.join(', ')}. Remove " \
          "them from the allowlist - they're already covered by the role definition."
    end
  end

  # Clear the role definition cache before and after each test to prevent
  # test pollution from cached state that could be affected by BASE_PATH stubs
  # or other modifications to the role definitions
  before do
    described_class.reset!
  end

  after do
    described_class.reset!
  end

  # Permissions that are only ever granted by policy rules defined in EE. In FOSS mode
  # (Gitlab.ee? == false) the EE policy modules are never prepended, so the rules that grant
  # them don't exist and the permissions can't be exercised - even though DeclarativePolicy
  # still knows about them via CE-side permission group/role YAML references. Excluded from
  # the checks above when not running in EE.
  let(:ee_permissions) do
    %i[
      read_issue_analytics
      bulk_admin_epic
      create_vulnerability_feedback
      destroy_vulnerability_feedback
      update_vulnerability_feedback
      read_vulnerability_statistics
      update_vulnerability_flag
      download_wiki_code
    ]
  end

  let(:common_project_grants) do
    [
      # can?(:read_project)
      :read_incident_management_timeline_event_tag,
      :read_project_metadata,
      :read_attestation,

      # can?(:read_issue)
      :read_design,
      :read_design_activity,
      :read_issue_link,
      :read_issue_iid,

      # EE: can?(:read_project) & duo_features_enabled
      :access_duo_features,

      # Feature.enabled?(:build_service_proxy)
      :build_service_proxy_enabled,

      # project.override_pipeline_variables_allowed? (unrestricted by default)
      :set_pipeline_variables,

      # issue_analytics_enabled
      :read_issue_analytics,

      # project_level_analytics_dashboard_enabled
      :read_project_level_analytics_dashboard,

      # project_level_analytics_dashboard_enabled & can?(:read_cycle_analytics)
      :read_project_level_value_stream_dashboard_overview_counts,

      # can?(:read_project) & requirements_available
      :read_requirement,

      # target_branch_rules_available
      :read_target_branch_rule
    ]
  end

  let(:common_group_grants) do
    [
      # can?(:read_group)
      :read_milestone,
      :read_label,
      :read_issue_board,
      :read_issue_board_list,
      :read_group_member,
      :read_group_metadata,
      :read_counts,
      :read_achievement,
      :read_custom_emoji,
      :read_upload,
      :read_work_item_type,

      # can?(:read_cross_project) & can?(:read_group)
      :read_group_activity,
      :read_group_issues,
      :read_group_boards,
      :read_group_labels,
      :read_group_milestones,
      :read_group_merge_requests,
      :read_group_build_report_results,

      # EE: can?(:read_group) & duo_features_enabled
      :access_duo_features,

      # can?(:read_group) & custom_fields_available
      :read_custom_field,

      # can?(:read_group) & epics_available
      :read_epic,
      :read_epic_board,
      :read_epic_board_list,

      # can?(:read_group) & iterations_available
      :read_iteration,
      :read_iteration_cadence,

      # can?(:read_work_item) & work_item_statuses_available
      :read_work_item_lifecycle,
      :read_work_item_status
    ]
  end

  # Held by any authenticated role
  # can?(:create_issue) & okrs_enabled
  let(:issue_creator_grants) { [:create_key_result, :create_objective] }

  # Held by any role with actual group membership access
  let(:member_group_grants) do
    [
      # dependency_proxy_access_allowed & dependency_proxy_available
      :read_dependency_proxy,

      # has_access & contribution_analytics_available
      :read_contribution_analytics,
      :read_group_contribution_analytics,

      # has_access & group_activity_analytics_available
      :read_group_activity_analytics
    ]
  end

  # Package pull granted to guest and planner via a rollout flag. Reporter and above already own
  # :read_package directly (config/authz/roles/reporter.yml).
  # guest & allow_guest_plus_roles_to_pull_packages_enabled
  let(:package_pull_grants) { [:read_package] }

  # Held by planner and above (admin_epic is a planner.yml/reporter.yml own permission).
  # EE: can?(:admin_epic) & bulk_edit_feature_available
  let(:epic_admin_grants) { [:bulk_admin_epic] }

  # Held by developer and above (read_cluster is a developer.yml own permission).
  # EE: can?(:read_cluster) & cluster_deployments_available
  let(:cluster_read_grants) { [:read_cluster_environments] }

  # Additional project grants a role receives once it can read code and merge requests.
  let(:repository_read_grants) do
    [
      # EE: can?(:read_code)
      :read_path_locks,

      # can?(:download_code)
      :read_repository_graphs,

      # can?(:read_merge_request)
      :read_vulnerability_merge_request_link
    ]
  end

  # Additional project grants a role receives once it can read builds, pipelines and merge requests.
  let(:pipeline_read_grants) do
    [
      # can?(:read_build) & can?(:read_pipeline)
      :read_build_report_results,

      # EE: can?(:read_merge_request) & can?(:read_pipeline)
      :read_merge_train
    ]
  end

  # Additional project grants a role receives once it can push code and create pipeline schedules.
  # Held by developer and above.
  let(:code_write_grants) do
    [
      # EE: can?(:push_code)
      :create_path_lock,

      # can?(:create_pipeline_schedule)
      :read_ci_pipeline_schedules_plan_limit
    ]
  end

  # Additional project grants for maintainer and above.
  let(:maintainer_admin_grants) do
    [
      # mirror_available & can?(:admin_project)
      :admin_remote_mirror,

      # can?(:admin_terraform_state)
      :create_terraform_state_protection_rule,
      :delete_terraform_state_protection_rule,

      # can?(:admin_container_image) | can?(:admin_package)
      :view_package_registry_project_settings,

      # EE: repository_mirrors_enabled & can?(:admin_project)
      :admin_mirror,

      # EE: security_dashboard_enabled & can?(:admin_security_testing)
      :configure_security_scanner
    ]
  end

  # Held by any role with read_vulnerability (developer and above; security_manager).
  # EE: can?(:read_vulnerability)
  let(:vulnerability_read_grants) do
    [
      :read_vulnerability_feedback,
      :read_vulnerability_representation_information,
      :read_vulnerability_scanner
    ]
  end

  # Held by any role with admin_vulnerability (maintainer and above; security_manager).
  # EE: can?(:admin_vulnerability)
  let(:vulnerability_admin_grants) do
    [
      :create_security_project_tracked_ref,
      :delete_security_project_tracked_ref,
      :create_vulnerability_feedback,
      :create_vulnerability_state_transition,
      :destroy_vulnerability_feedback,
      :update_vulnerability_feedback
    ]
  end

  # public_builds: false drops read_build/read_pipeline/read_ci_cd_analytics/read_build_report_results,
  # which guest legitimately gets from the _read_public_* permissions when public_builds is on. Those
  # are deliberate setting-gated grants, not role-based grants, so we turn the setting off to isolate
  # role-based grants.
  # lfs_enabled: true is the project-level half of design_management_enabled?; the global
  # Gitlab.config.lfs.enabled half is stubbed in the shared example's before hook above.
  let_it_be(:private_project) { create(:project, :private, public_builds: false, lfs_enabled: true) }
  let_it_be(:private_group) { create(:group, :private) }
  let_it_be(:public_project) { create(:project, :public, lfs_enabled: true) }
  let_it_be(:public_group) { create(:group, :public) }

  describe 'public_anonymous' do
    let(:role) { :public_anonymous }
    let(:actor) { ::Users::Anonymous }

    before do
      next unless Gitlab.ee?

      stub_licensed_features(GitlabSubscriptions::Features::ALL_FEATURES.index_with(true))
    end

    context 'in projects' do
      let(:scope) { :project }
      let(:resource) { public_project }

      it 'lists only project permissions an anonymous caller can exercise on a public project' do
        unexercisable_permissions = described_class.get(role).permissions(:project).reject do |permission|
          actor.can?(permission, resource)
        end

        expect(unexercisable_permissions).to be_empty,
          "config/authz/roles/public_anonymous.yml lists project permissions that an " \
            "anonymous caller cannot exercise on a public project: " \
            "#{unexercisable_permissions.to_a.sort.join(', ')}. Either remove them from the YAML or " \
            "update ProjectPolicy so anonymous can exercise them."
      end

      it_behaves_like 'a role that does not enable unexpected permissions' do
        let(:permissions_granted_outside_role_definition) do
          common_project_grants + repository_read_grants + pipeline_read_grants + [
            # can?(:_read_public_build)
            :read_build,

            # can?(:_read_public_ci_cd_analytics)
            :read_ci_cd_analytics,

            # can?(:_read_public_pipeline_schedule)
            :read_pipeline_schedule,

            # public_project & model_registry_enabled (licensed feature)
            :read_model_registry,

            # public_project & model_experiments_enabled (licensed feature)
            :read_model_experiments,

            # public_pages
            :read_pages_content,

            # can?(:read_issue)
            :read_work_item
          ]
        end
      end
    end

    context 'in groups' do
      let(:scope) { :group }
      let(:resource) { public_group }

      it 'lists only group permissions an anonymous caller can exercise on a public group' do
        unexercisable_permissions = described_class.get(role).permissions(:group).reject do |permission|
          actor.can?(permission, resource)
        end

        expect(unexercisable_permissions).to be_empty,
          "config/authz/roles/public_anonymous.yml lists group permissions that an " \
            "anonymous caller cannot exercise on a public group: " \
            "#{unexercisable_permissions.to_a.sort.join(', ')}. Either remove them from the YAML or " \
            "update GroupPolicy so anonymous can exercise them."
      end

      it_behaves_like 'a role that does not enable unexpected permissions' do
        let(:permissions_granted_outside_role_definition) do
          common_group_grants + [
            # EE: public_group (group wikis)
            :download_wiki_code,

            # can?(:read_group)
            :read_issue,
            :read_namespace,
            :read_work_item
          ]
        end
      end
    end
  end

  describe 'guest' do
    let(:role) { :guest }

    context 'in projects' do
      let_it_be(:actor) { create(:user, guest_of: private_project) }

      let(:scope) { :project }
      let(:resource) { private_project }

      it_behaves_like 'a role that does not enable unexpected permissions' do
        let(:permissions_granted_outside_role_definition) do
          common_project_grants + issue_creator_grants + package_pull_grants
        end
      end
    end

    context 'in groups' do
      let_it_be(:actor) { create(:user, guest_of: private_group) }

      let(:scope) { :group }
      let(:resource) { private_group }

      it_behaves_like 'a role that does not enable unexpected permissions' do
        let(:permissions_granted_outside_role_definition) do
          common_group_grants + member_group_grants + package_pull_grants
        end
      end
    end
  end

  describe 'planner' do
    let(:role) { :planner }

    context 'in projects' do
      let_it_be(:actor) { create(:user, planner_of: private_project) }

      let(:scope) { :project }
      let(:resource) { private_project }

      it_behaves_like 'a role that does not enable unexpected permissions' do
        let(:permissions_granted_outside_role_definition) do
          common_project_grants + issue_creator_grants + repository_read_grants + package_pull_grants
        end
      end
    end

    context 'in groups' do
      let_it_be(:actor) { create(:user, planner_of: private_group) }

      let(:scope) { :group }
      let(:resource) { private_group }

      it_behaves_like 'a role that does not enable unexpected permissions' do
        let(:permissions_granted_outside_role_definition) do
          common_group_grants + member_group_grants + package_pull_grants + epic_admin_grants
        end
      end
    end
  end

  describe 'reporter' do
    let(:role) { :reporter }

    context 'in projects' do
      let_it_be(:actor) { create(:user, reporter_of: private_project) }

      let(:scope) { :project }
      let(:resource) { private_project }

      it_behaves_like 'a role that does not enable unexpected permissions' do
        let(:permissions_granted_outside_role_definition) do
          common_project_grants + issue_creator_grants + repository_read_grants + pipeline_read_grants
        end
      end
    end

    context 'in groups' do
      let_it_be(:actor) { create(:user, reporter_of: private_group) }

      let(:scope) { :group }
      let(:resource) { private_group }

      it_behaves_like 'a role that does not enable unexpected permissions' do
        let(:permissions_granted_outside_role_definition) do
          common_group_grants + member_group_grants + epic_admin_grants
        end
      end
    end
  end

  describe 'security_manager' do
    let(:role) { :security_manager }

    context 'in projects' do
      let_it_be(:actor) { create(:user, security_manager_of: private_project) }

      let(:scope) { :project }
      let(:resource) { private_project }

      it_behaves_like 'a role that does not enable unexpected permissions' do
        let(:permissions_granted_outside_role_definition) do
          common_project_grants + issue_creator_grants + repository_read_grants + pipeline_read_grants +
            vulnerability_read_grants + vulnerability_admin_grants + [
              # can?(:update_sec_ai_workflow_settings)
              :view_edit_page,

              # EE: can?(:read_vulnerability) / can?(:admin_vulnerability) - developer.yml (inherited by
              # maintainer/owner) already owns these two directly, but security_manager.yml doesn't.
              :read_vulnerability_statistics,
              :update_vulnerability_flag
            ]
        end
      end
    end

    context 'in groups' do
      let_it_be(:actor) { create(:user, security_manager_of: private_group) }

      let(:scope) { :group }
      let(:resource) { private_group }

      it_behaves_like 'a role that does not enable unexpected permissions' do
        let(:permissions_granted_outside_role_definition) do
          common_group_grants + member_group_grants + epic_admin_grants
        end
      end
    end
  end

  describe 'developer' do
    let(:role) { :developer }

    context 'in projects' do
      let_it_be(:actor) { create(:user, developer_of: private_project) }

      let(:scope) { :project }
      let(:resource) { private_project }

      it_behaves_like 'a role that does not enable unexpected permissions' do
        let(:permissions_granted_outside_role_definition) do
          common_project_grants + issue_creator_grants + repository_read_grants + pipeline_read_grants +
            code_write_grants + vulnerability_read_grants
        end
      end
    end

    context 'in groups' do
      let_it_be(:actor) { create(:user, developer_of: private_group) }

      let(:scope) { :group }
      let(:resource) { private_group }

      it_behaves_like 'a role that does not enable unexpected permissions' do
        let(:permissions_granted_outside_role_definition) do
          common_group_grants + member_group_grants + epic_admin_grants + cluster_read_grants
        end
      end
    end

    it 'includes all job update abilities defined in Ci::JobAbilities' do
      developer_permissions = described_class.get(role).permissions(:project)
      missing = ProjectPolicy.all_job_update_abilities.reject { |perm| developer_permissions.include?(perm) }

      expect(missing).to be_empty,
        "Developer role YAML is missing job update abilities: #{missing.join(', ')}. " \
          "Update config/authz/roles/developer.yml to include them."
    end
  end

  describe 'maintainer' do
    let(:role) { :maintainer }

    context 'in projects' do
      let_it_be(:actor) { create(:user, maintainer_of: private_project) }

      let(:scope) { :project }
      let(:resource) { private_project }

      it_behaves_like 'a role that does not enable unexpected permissions' do
        let(:permissions_granted_outside_role_definition) do
          common_project_grants + issue_creator_grants + repository_read_grants + pipeline_read_grants +
            code_write_grants + maintainer_admin_grants + vulnerability_read_grants +
            vulnerability_admin_grants
        end
      end
    end

    context 'in groups' do
      let_it_be(:actor) { create(:user, maintainer_of: private_group) }

      let(:scope) { :group }
      let(:resource) { private_group }

      it_behaves_like 'a role that does not enable unexpected permissions' do
        let(:permissions_granted_outside_role_definition) do
          common_group_grants + member_group_grants + epic_admin_grants + cluster_read_grants
        end
      end
    end
  end

  describe 'owner' do
    let(:role) { :owner }

    context 'in projects' do
      let_it_be(:actor) { create(:user, owner_of: private_project) }

      let(:scope) { :project }
      let(:resource) { private_project }

      it_behaves_like 'a role that does not enable unexpected permissions' do
        let(:permissions_granted_outside_role_definition) do
          common_project_grants + issue_creator_grants + repository_read_grants + pipeline_read_grants +
            code_write_grants + maintainer_admin_grants + vulnerability_read_grants +
            vulnerability_admin_grants
        end
      end
    end

    context 'in groups' do
      let_it_be(:actor) { create(:user, owner_of: private_group) }

      let(:scope) { :group }
      let(:resource) { private_group }

      it_behaves_like 'a role that does not enable unexpected permissions' do
        # On top of the common group grants, an owner's admin capabilities cascade into these.
        let(:permissions_granted_outside_role_definition) do
          common_group_grants + member_group_grants + epic_admin_grants + cluster_read_grants + [
            # can?(:admin_runners)
            :admin_group_or_admin_runners,

            # EE: can?(:admin_namespace)
            :admin_namespace_cluster_agent_mapping,

            # creation_allowed & can?(:read_resource_access_tokens)
            :create_resource_access_tokens,
            :manage_resource_access_tokens,

            # can?(:remove_group) | can?(:archive_group)
            :view_edit_page
          ]
        end
      end
    end
  end
end
