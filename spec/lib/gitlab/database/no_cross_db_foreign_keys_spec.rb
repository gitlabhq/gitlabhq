# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'cross-database foreign keys', feature_category: :database do
  # Pre-existing FK that needs to be convered to loose foreign keys
  #
  # The issue corresponding to the loose foreign key conversion
  # should be added as a comment along with the name of the column.
  let!(:allowed_cross_database_foreign_keys) do
    keys = [
      'zoekt_indices.zoekt_enabled_namespace_id',
      'zoekt_repositories.project_id',
      'zoekt_replicas.zoekt_enabled_namespace_id',
      'zoekt_replicas.namespace_id',
      'system_access_microsoft_applications.namespace_id',
      'ci_job_artifact_states.partition_id.job_artifact_id',
      'p_ci_build_tags.tag_id',                                          # https://gitlab.com/gitlab-org/gitlab/-/issues/470872
      'ci_secure_file_states.ci_secure_file_id',                         # https://gitlab.com/groups/gitlab-org/-/epics/17347
      'dependency_proxy_blob_states.dependency_proxy_blob_id',           # https://gitlab.com/groups/gitlab-org/-/epics/17347
      'dependency_proxy_blob_states.group_id',                           # https://gitlab.com/groups/gitlab-org/-/epics/17347
      'dependency_proxy_manifest_states.dependency_proxy_manifest_id',   # https://gitlab.com/groups/gitlab-org/-/epics/17347
      'dependency_proxy_manifest_states.group_id',                       # https://gitlab.com/groups/gitlab-org/-/epics/17347
      'lfs_objects_projects.lfs_object_id',                              # https://gitlab.com/groups/gitlab-org/-/epics/17347
      'merge_request_diff_details.merge_request_diff_id',                # https://gitlab.com/groups/gitlab-org/-/epics/17347
      'merge_request_diff_details.project_id',                           # https://gitlab.com/groups/gitlab-org/-/epics/17347
      'pages_deployment_states.pages_deployment_id',                     # https://gitlab.com/groups/gitlab-org/-/epics/17347
      'pages_deployment_states.project_id',                              # https://gitlab.com/groups/gitlab-org/-/epics/17347
      'snippet_repositories.snippet_id',                                 # https://gitlab.com/groups/gitlab-org/-/epics/17347
      'snippet_repositories.snippet_organization_id',                    # https://gitlab.com/groups/gitlab-org/-/epics/17347
      'snippet_repositories.snippet_project_id',                         # https://gitlab.com/groups/gitlab-org/-/epics/17347
      'upload_states.upload_id',                                         # https://gitlab.com/groups/gitlab-org/-/epics/17347
      'application_settings.web_ide_oauth_application_id',          # https://gitlab.com/gitlab-org/gitlab/-/issues/531355
      'ai_settings.amazon_q_oauth_application_id',                  # https://gitlab.com/gitlab-org/gitlab/-/issues/531356
      'ai_settings.duo_workflow_oauth_application_id',              # https://gitlab.com/gitlab-org/gitlab/-/issues/531356
      'ai_settings.duo_workflow_service_account_user_id',           # https://gitlab.com/gitlab-org/gitlab/-/issues/531356
      'ai_settings.amazon_q_service_account_user_id',               # https://gitlab.com/gitlab-org/gitlab/-/issues/531356
      'targeted_message_dismissals.targeted_message_id',            # https://gitlab.com/gitlab-org/gitlab/-/issues/531357
      'user_broadcast_message_dismissals.broadcast_message_id',     # https://gitlab.com/gitlab-org/gitlab/-/issues/531358
      'targeted_message_namespaces.targeted_message_id',            # https://gitlab.com/gitlab-org/gitlab/-/issues/531357
      'plan_limits.plan_id',                                        # https://gitlab.com/gitlab-org/gitlab/-/issues/519892
      'term_agreements.term_id',                                    # https://gitlab.com/gitlab-org/gitlab/-/issues/531367
      'appearance_uploads.uploaded_by_user_id',                     # https://gitlab.com/gitlab-org/gitlab/-/issues/534207
      'appearance_uploads.project_id',                              # https://gitlab.com/gitlab-org/gitlab/-/issues/534207
      'appearance_uploads.namespace_id',                            # https://gitlab.com/gitlab-org/gitlab/-/issues/534207
      'appearance_uploads.organization_id'                          # https://gitlab.com/gitlab-org/gitlab/-/issues/534207
    ]

    # Pre-existing gitlab_main_cell <=> gitlab_main_clusterwide issues
    # Epic: https://gitlab.com/groups/gitlab-org/-/epics/16043
    # NOTE: Converting FK to LFK is not enough.
    #       The tables, and related features will need to be reworked to be org level
    keys += [
      'issues.work_item_type_id',
      'protected_branch_push_access_levels.deploy_key_id',
      'protected_tag_create_access_levels.deploy_key_id',
      'work_item_type_custom_lifecycles.work_item_type_id',
      'work_item_type_user_preferences.work_item_type_id',
      'abuse_report_user_mentions.note_id',
      'ssh_signatures.key_id',
      'subscription_add_on_purchases.subscription_add_on_id',
      'audit_events_streaming_http_instance_namespace_filters.audit_events_instance_external_audit_event_destination_id',
      'oauth_device_grants.application_id',
      'deploy_tokens.project_id',
      'deploy_tokens.group_id',
      'audit_events_streaming_instance_namespace_filters.external_streaming_destination_id',
      'identities.saml_provider_id',
      'gitlab_subscriptions.hosted_plan_id',
      'work_item_type_custom_fields.work_item_type_id',
      'project_deploy_tokens.deploy_token_id',
      'gpg_signatures.gpg_key_subkey_id',
      'gpg_signatures.gpg_key_id',
      'x509_commit_signatures.x509_certificate_id',
      'ldap_admin_role_links.member_role_id',
      'group_deploy_tokens.deploy_token_id',
      'abuse_report_uploads.project_id',
      'abuse_report_uploads.namespace_id',
      'abuse_report_uploads.organization_id',
      'user_permission_export_upload_uploads.project_id',
      'user_permission_export_upload_uploads.namespace_id',
      'user_permission_export_upload_uploads.organization_id',
      'security_trainings.provider_id',
      'analytics_language_trend_repository_languages.programming_language_id'
    ]

    # Pre-existing gitlab_main_user <=> gitlab_main_clusterwide issues
    # Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/505754
    # NOTE: Likely converting FK to LFK is not enough.
    #       The tables here needs to be reworked, or shifted to gitlab_main_user
    keys += [
      'abuse_reports.assignee_id',
      'abuse_reports.resolved_by_id',
      'abuse_report_notes.updated_by_id',
      'abuse_report_notes.author_id',
      'abuse_report_notes.resolved_by_id',
      'abuse_report_events.user_id',
      'deploy_tokens.creator_id',
      'user_admin_roles.admin_role_id',
      'abuse_events.user_id',
      'abuse_report_uploads.uploaded_by_user_id',
      'gpg_keys.user_id',
      'authentication_events.user_id',
      'abuse_trust_scores.user_id',
      'user_permission_export_upload_uploads.uploaded_by_user_id',
      'user_permission_export_uploads.user_id'
    ]

    keys
  end

  def foreign_keys_for(table_name)
    ApplicationRecord.connection.foreign_keys(table_name)
  end

  def is_cross_db?(fk_record)
    tables = [fk_record.from_table, fk_record.to_table]

    table_schemas = Gitlab::Database::GitlabSchema.table_schemas!(tables)

    !Gitlab::Database::GitlabSchema.cross_foreign_key_allowed?(table_schemas, tables)
  end

  def cross_db_failure_message(column, fk)
    tables = [fk.from_table, fk.to_table]
    table_schemas = Gitlab::Database::GitlabSchema.table_schemas!(tables)

    if table_schemas.all? { |schema| Gitlab::Database::GitlabSchema.require_sharding_key?(schema) }
      "Found extra cross-database foreign key #{column} referencing #{fk.to_table} with constraint name #{fk.name}. " \
      "When a foreign key references another database you must use a Loose Foreign Key instead https://docs.gitlab.com/ee/development/database/loose_foreign_keys.html."
    else
      # Any FK that references to / from a non-sharded table (e.g. gitlab_main_clusterwide) is not allowed
      "Found extra cross-database foreign key #{column} referencing #{fk.to_table} with constraint name #{fk.name}. " \
      "Sharded tables referencing from / to non-sharded tables are not allowed in Cells architecture. " \
      "Consult https://docs.gitlab.com/development/cells for possible solutions. " \
      "(gitlab_schemas: #{table_schemas.join(', ')})"
    end
  end

  it 'onlies have allowed list of cross-database foreign keys', :aggregate_failures do
    all_tables = ApplicationRecord.connection.data_sources
    allowlist = allowed_cross_database_foreign_keys.dup

    all_tables.each do |table|
      foreign_keys_for(table).each do |fk|
        next unless is_cross_db?(fk)

        column = "#{fk.from_table}.#{Array.wrap(fk.column).join('.')}"
        allowlist.delete(column)

        expect(allowed_cross_database_foreign_keys).to include(column), cross_db_failure_message(column, fk)
      end
    end

    formatted_allowlist = allowlist.map { |item| "- #{item}" }.join("\n")
    expect(allowlist).to be_empty, "The following items must be allowed_cross_database_foreign_keys` list," \
      "as it no longer appears as cross-database foreign key:\n" \
      "#{formatted_allowlist}"
  end

  it 'only allows existing foreign keys to be present in the exempted list', :aggregate_failures do
    allowed_cross_database_foreign_keys.each do |entry|
      table, _ = entry.split('.')

      all_foreign_keys_for_table = foreign_keys_for(table)
      fk_entry = all_foreign_keys_for_table.find do |fk|
        "#{fk.from_table}.#{Array.wrap(fk.column).join('.')}" == entry
      end

      expect(fk_entry).to be_present,
        "`#{entry}` is no longer a foreign key. " \
        "You must remove this entry from the `allowed_cross_database_foreign_keys` list."
    end
  end
end
