# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'organization transfer support tracking', :aggregate_failures, feature_category: :organization do
  let(:valid_statuses) { %w[supported todo] }

  # Tables that existed before this tracking system was introduced.
  # These are allowed to have value 'todo'.
  # DO NOT ADD new tables to this list. New tables must have value 'supported'.
  let(:allowed_todo_tables) do
    %w[
      abuse_events
      abuse_report_uploads
      abuse_report_user_mentions
      abuse_reports
      admin_roles
      agent_organization_authorizations
      ai_catalog_item_consumers
      ai_catalog_item_version_dependencies
      ai_catalog_items
      ai_code_suggestion_events
      ai_conversation_messages
      ai_duo_chat_events
      analytics_cycle_analytics_stage_event_hashes
      background_operation_jobs
      background_operation_workers
      bulk_import_batch_trackers
      bulk_import_configurations
      bulk_import_entities
      bulk_import_failures
      bulk_import_trackers
      ci_runner_taggings_group_type
      ci_runner_taggings_project_type
      clusters
      custom_dashboard_search_data
      custom_dashboards
      dependency_list_export_part_uploads
      dependency_list_export_parts
      dependency_list_export_uploads
      fork_networks
      granular_scopes
      group_type_ci_runner_machines
      group_type_ci_runners
      import_failures
      import_offline_configurations
      integrations
      issue_tracker_data
      jira_connect_installations
      jira_tracker_data
      ldap_admin_role_links
      member_roles
      merge_request_diff_commit_users
      non_sql_service_pings
      notes
      oauth_applications
      oauth_device_grants
      oauth_openid_requests
      organization_detail_uploads
      organization_details
      organization_foundational_agent_statuses
      organization_isolations
      organization_push_rules
      organization_settings
      organization_user_details
      organization_users
      personal_access_token_granular_scopes
      personal_access_token_last_used_ips
      project_secrets_manager_maintenance_tasks
      project_topic_uploads
      project_type_ci_runner_machines
      project_type_ci_runners
      queries_service_pings
      raw_usage_data
      sbom_component_versions
      sbom_components
      sbom_source_packages
      sbom_sources
      scim_oauth_access_tokens
      security_policy_settings
      slack_api_scopes
      slack_integrations
      slack_integrations_scopes
      snippet_repositories
      snippet_repository_storage_moves
      snippet_statistics
      snippet_uploads
      snippet_user_mentions
      subscription_user_add_on_assignment_versions
      topics
      upcoming_reconciliations
      user_agent_details
      user_uploads
      vulnerability_export_part_uploads
      vulnerability_export_parts
      vulnerability_export_uploads
      web_hooks
      web_hook_logs_daily
      zentao_tracker_data
    ]
  end

  describe 'tables sharded by organization_id' do
    let(:org_sharded_tables) do
      Gitlab::Database::Dictionary.entries.select do |entry|
        entry.sharding_key.is_a?(Hash) && entry.sharding_key.key?('organization_id')
      end
    end

    it 'requires organization_transfer_support field for all tables sharded by organization_id' do
      org_sharded_tables.each do |entry|
        transfer_support = entry.organization_transfer_support

        expect(transfer_support).to be_present,
          "Table '#{entry.table_name}' is sharded by organization_id but missing " \
            "'organization_transfer_support' field in db/docs/#{entry.table_name}.yml. " \
            "See doc/development/database/database_dictionary.md#organization-transfer-support"
      end
    end

    it 'requires a valid status value' do
      org_sharded_tables.each do |entry|
        transfer_support = entry.organization_transfer_support
        next unless transfer_support

        expect(transfer_support).to be_in(valid_statuses),
          "Table '#{entry.table_name}' has invalid organization_transfer_support value '#{transfer_support}'. " \
            "Must be one of: #{valid_statuses.join(', ')}"
      end
    end

    it 'only allows known tables to have value: todo' do
      todo_tables = org_sharded_tables.select do |entry|
        entry.organization_transfer_support == 'todo'
      end

      todo_tables.each do |entry|
        table_name = entry.table_name

        expect(allowed_todo_tables).to include(table_name),
          "Table '#{table_name}' has value 'todo' but is not in the allowed_todo_tables list. " \
            "If this is an existing table that needs transfer support, add it to the " \
            "allowed_todo_tables array in this spec."
      end
    end

    it 'ensures allowed_todo_tables only contains tables that actually have value: todo',
      :aggregate_failures do
      allowed_todo_tables.each do |table_name|
        entry = Gitlab::Database::Dictionary.entry(table_name)

        expect(entry).to be_present,
          "Table '#{table_name}' is in allowed_todo_tables but doesn't exist in the database dictionary."

        transfer_support = entry.organization_transfer_support

        expect(transfer_support).to eq('todo'),
          "Table '#{table_name}' is in allowed_todo_tables but has value '#{transfer_support}'. " \
            "Remove it from allowed_todo_tables or update its value to 'todo'."
      end
    end
  end
end
