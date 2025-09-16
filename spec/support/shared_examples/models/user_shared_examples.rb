# frozen_string_literal: true

RSpec.shared_examples 'associations with defined deletion strategies', :aggregate_failures do
  using RSpec::Parameterized::TableSyntax

  let(:existing_associations_without_dependent) do
    %i[
      uploads
      expired_today_and_unnotified_keys
      expiring_soon_and_unnotified_keys
      group_deploy_keys
      gpg_keys
      emails
      expiring_soon_and_unnotified_personal_access_tokens
      webauthn_registrations
      saved_replies
      user_synced_attributes_metadata
      aws_role
      ghost_user_migration
      followed_users
      following_users
      members
      namespace_deletion_schedules
      group_members
      project_members
      created_namespace_details
      admin_abuse_report_assignees
      resolved_abuse_reports
      abuse_events
      abuse_trust_scores
      builds
      pipelines
      pipeline_schedules
      notification_settings
      triggers
      audit_events
      uploaded_uploads
      alert_assignees
      issue_assignees
      created_custom_emoji
      bulk_imports
      namespace_import_user
      placeholder_user_detail
      custom_attributes
      trusted_with_spam_attribute
      callouts
      group_callouts
      project_callouts
      term_agreements
      organization_users
      organization_user_details
      status
      user_preference
      user_detail
      user_highest_role
      credit_card_validation
      phone_number_validation
      atlassian_identity
      banned_user
      reviews
      timelogs
      early_access_program_tracking_events
      namespace_commit_emails
      user_achievements
      awarded_user_achievements
      revoked_user_achievements
      vscode_settings
      broadcast_message_dismissals
      epics
      test_reports
      assigned_epics
      vulnerability_feedback
      vulnerability_state_transitions
      vulnerability_severity_overrides
      commented_vulnerability_feedback
      boards_epic_user_preferences
      epic_board_recent_visits
      minimal_access_group_members
      elevated_members
      requested_member_approvals
      reviewed_member_approvals
      users_ops_dashboard_projects
      users_security_dashboard_projects
      group_saml_identities
      deployment_approvals
      smartcard_identities
      group_scim_identities
      instance_scim_identities
      scim_group_memberships
      board_preferences
      user_permission_export_uploads
      oncall_participants
      escalation_rules
      namespace_bans
      workspaces
      dependency_list_exports
      created_namespace_cluster_agent_mappings
      created_organization_cluster_agent_mappings
      country_access_logs
      pipl_user
      user_admin_role
      user_member_role
      user_group_member_roles
      ai_conversation_threads
      subscription_seat_assignments
      compromised_password_detections
      arkose_sessions
    ]
  end

  let(:excluded_tables) do
    %w[
      abuse_report_events
      abuse_report_notes
      abuse_report_uploads
      achievement_uploads
      ai_vectorizable_file_uploads
      alert_management_alert_metric_image_uploads
      appearance_uploads
      approval_group_rules_users
      approval_merge_request_rules_approved_approvers
      approval_merge_request_rules_users
      approval_policy_merge_request_bypass_events
      approval_project_rules_users
      board_group_recent_visits
      board_project_recent_visits
      boards_epic_board_recent_visits
      boards_epic_list_user_preferences
      bulk_import_export_upload_uploads
      bulk_import_exports
      coverage_fuzzing_corpuses
      csv_issue_imports
      cluster_agents
      clusters
      dependency_list_export_part_uploads
      dependency_list_export_uploads
      deploy_tokens
      design_management_action_uploads
      group_deletion_schedules
      group_import_states
      group_scim_identities
      import_export_upload_uploads
      import_export_uploads
      import_failures
      import_source_users
      incident_management_oncall_participants
      issuable_metric_image_uploads
      jira_imports
      lists
      list_user_preferences
      ml_experiments
      members_deletion_schedules
      merge_requests_approval_rules_approver_users
      merge_requests_compliance_violations
      merge_requests_merge_data
      namespace_uploads
      organization_detail_uploads
      note_uploads
      packages_composer_packages
      packages_debian_group_distributions
      packages_debian_project_distributions
      packages_packages
      project_export_jobs
      project_import_export_relation_export_upload_uploads
      project_topic_uploads
      project_uploads
      protected_environment_approval_rules
      protected_environment_deploy_access_levels
      requirements_management_test_reports
      saved_replies
      security_orchestration_policy_rule_schedules
      snippet_uploads
      subscription_user_add_on_assignments
      user_group_callouts
      user_permission_export_upload_uploads
      user_project_callouts
      user_uploads
      vulnerability_archive_export_uploads
      vulnerability_export_part_uploads
      vulnerability_export_uploads
      vulnerability_remediation_uploads
      work_item_descriptions
      agent_activity_events
      ai_settings
      ai_user_metrics
      alert_management_alert_assignees
      authentication_events
      board_assignees
      catalog_resource_versions
      cluster_agent_tokens
      cluster_agent_url_configurations
      custom_fields
      design_management_versions
      draft_notes
      duo_workflows_workflows
      incident_management_escalation_rules
      incident_management_timeline_events
      lfs_file_locks
      merge_request_metrics
      merge_trains
      ml_candidates
      ml_models
      protected_tag_create_access_levels
      resource_iteration_events
      resource_link_events
      resource_milestone_events
      resource_weight_events
      scim_identities
      security_policy_dismissals
      service_desk_custom_email_verifications
      smartcard_identities
      ssh_signatures
      targeted_message_dismissals
      terraform_state_versions
      terraform_states
      user_broadcast_message_dismissals
      user_callouts
      user_custom_attributes
      user_follow_users
      user_synced_attributes_metadata
      user_namespace_callouts
      uploads_9ba88c4165
      vs_code_settings
      work_item_custom_lifecycles
      work_item_custom_statuses
      work_item_type_user_preferences
    ]
  end

  let(:user_associations) { User.reflect_on_all_associations }

  it 'specifies dependent option on all required associations' do
    assc_eligible_for_dependent_clause = [:has_many, :has_one]

    user_associations.each do |association|
      next if association.macro == :belongs_to
      next if association.options[:through]
      next if existing_associations_without_dependent.include?(association.name)

      next unless assc_eligible_for_dependent_clause.include?(association.macro)

      dependent_value = association.options[:dependent]

      expect(dependent_value).not_to be_nil,
        "Association #{association.name} should have a dependent clause " \
          "(either :destroy, :nullify, :delete_all, or :delete)"

      expect([:destroy, :nullify, :delete_all, :delete]).to include(dependent_value),
        "Association #{association.name} has dependent: #{dependent_value}, " \
          "but should be one of: :destroy, :nullify, :delete_all, or :delete"
    end
  end

  describe 'database foreign keys without model associations' do
    it 'identifies tables with foreign keys to users that lack dependent associations', :aggregate_failures do
      fk_query = <<-SQL
       SELECT
        cls.relname AS table_name,
        att.attname AS column_name,
        'users' AS foreign_table_name,
        'id' AS foreign_column_name,
        con.conname AS constraint_name
      FROM
        pg_constraint con
        JOIN pg_class cls ON con.conrelid = cls.oid
        JOIN pg_namespace nsp ON cls.relnamespace = nsp.oid
        JOIN pg_attribute att ON att.attrelid = cls.oid AND att.attnum = ANY(con.conkey)
      WHERE
        con.contype = 'f'
        AND con.confrelid = (SELECT oid FROM pg_class WHERE relname = 'users')
        AND nsp.nspname = current_schema()
        AND cls.relname NOT LIKE '%\\_p\\_%'
        AND cls.relname NOT LIKE '%\\_p$'
      ORDER BY
        table_name;
      SQL

      foreign_keys = ApplicationRecord.connection.execute(fk_query)

      tables_with_fk_to_users = foreign_keys.pluck('table_name').uniq
      tables_with_fk_to_users = tables_with_fk_to_users.reject { |table| excluded_tables.include?(table) }

      table_names_with_association = user_associations.map { |assoc| assoc.klass.table_name }

      tables_without_associations = tables_with_fk_to_users.select do |table|
        table_names_with_association.exclude?(table)
      end

      expect(tables_without_associations).to be_empty,
        "Found tables with foreign keys to users but no " \
          "corresponding associations in User model: " \
          "#{tables_without_associations.join(', ')}.\n" \
          "Consider adding appropriate associations with dependent clauses to prevent orphaned records."
    end
  end
end
