# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'organization transfer support tracking', :aggregate_failures, feature_category: :organization do
  let(:valid_statuses) { %w[supported todo no_work_needed] }

  # Tables that existed before this tracking system was introduced.
  # These are allowed to have value 'todo'.
  # DO NOT ADD new tables to this list. New tables must have value 'supported'.
  let(:allowed_todo_tables) do
    %w[
      abuse_events
      abuse_report_uploads
      abuse_report_upload_states
      abuse_report_user_mentions
      abuse_reports
      admin_roles
      agent_organization_authorizations
      ai_catalog_item_version_dependencies
      ai_catalog_items
      ai_code_suggestion_events
      ai_conversation_messages
      ai_duo_chat_events
      analytics_cycle_analytics_stage_event_hashes
      background_operation_jobs
      background_operation_workers
      bulk_import_configurations
      cluster_platforms_kubernetes
      cluster_providers_gcp
      clusters
      cluster_providers_aws
      clusters_kubernetes_namespaces
      custom_dashboard_search_data
      custom_dashboards
      dependency_list_export_part_uploads
      dependency_list_export_parts
      dependency_list_export_uploads
      import_failures
      import_offline_configurations
      issue_tracker_data
      jira_connect_installations
      jira_tracker_data
      ldap_admin_role_links
      member_roles
      merge_request_diff_commit_users
      non_sql_service_pings
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
      personal_access_token_last_used_ips
      pool_repositories
      project_topic_uploads
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
      todos
      topics
      upcoming_reconciliations
      user_agent_details
      user_uploads
      user_upload_states
      vulnerability_export_part_uploads
      vulnerability_export_parts
      vulnerability_export_upload_states
      vulnerability_export_uploads
      work_item_custom_types
      work_item_settings
      work_item_type_visibility_defaults
      zentao_tracker_data
    ]
  end

  let(:allowed_no_work_needed_tables) do
    %w[
      bulk_import_batch_trackers
      bulk_import_entities
      bulk_import_failures
      bulk_import_trackers
      enabled_foundational_flow_check_results
      integrations
      labels
      web_hooks
      web_hook_logs_daily
    ]
  end

  let(:org_sharded_tables) do
    Gitlab::Database::Dictionary.entries.select do |entry|
      sharded_by_organization?(entry)
    end
  end

  describe 'tables sharded by organization_id' do
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

        expect(sharded_by_organization?(entry)).to be(true),
          "Table '#{table_name}' is in allowed_todo_tables but is not sharded by organization " \
            "(sharding_key: #{entry.sharding_key}). Only tables sharded by organization belong here."

        transfer_support = entry.organization_transfer_support

        expect(transfer_support).to eq('todo'),
          "Table '#{table_name}' is in allowed_todo_tables but has value '#{transfer_support}'. " \
            "Remove it from allowed_todo_tables or update its value to 'todo'."
      end
    end

    it 'only allows known tables to have value: no_work_needed' do
      no_work_needed_tables = org_sharded_tables.select do |entry|
        entry.organization_transfer_support == 'no_work_needed'
      end

      no_work_needed_tables.each do |entry|
        table_name = entry.table_name

        expect(allowed_no_work_needed_tables).to include(table_name),
          "Table '#{table_name}' has value 'no_work_needed' but is not in the allowed_no_work_needed_tables list. " \
            "If this table has been reviewed and requires no transfer work, add it to the " \
            "allowed_no_work_needed_tables array in this spec."
      end
    end

    it 'ensures allowed_no_work_needed_tables only contains tables that actually have value: no_work_needed',
      :aggregate_failures do
      allowed_no_work_needed_tables.each do |table_name|
        entry = Gitlab::Database::Dictionary.entry(table_name)

        expect(entry).to be_present,
          "Table '#{table_name}' is in allowed_no_work_needed_tables but doesn't exist in the database dictionary."

        expect(sharded_by_organization?(entry)).to be(true),
          "Table '#{table_name}' is in allowed_no_work_needed_tables but is not sharded by organization " \
            "(sharding_key: #{entry.sharding_key}). Only tables sharded by organization belong here."

        transfer_support = entry.organization_transfer_support

        expect(transfer_support).to eq('no_work_needed'),
          "Table '#{table_name}' is in allowed_no_work_needed_tables but has value '#{transfer_support}'. " \
            "Remove it from allowed_no_work_needed_tables or update its value to 'no_work_needed'."
      end
    end
  end

  def sharded_by_organization?(entry)
    # skip 'organizations' table because we're not transferring any data from it
    return unless entry.table_name != "organizations"
    return unless entry.sharding_key.is_a?(Hash)

    entry.sharding_key.invert["organizations"].present?
  end

  # These tests validate that:
  # 1. Tables marked 'supported' in db/docs/*.yml are actually updated during transfer specs
  # 2. Tables updated during transfer specs are marked 'supported' in db/docs/*.yml
  #
  # The transfer specs are loaded and run internally before validation.
  #
  # We can only run these specs in EE as this will cover FOSS & EE models. Running this spec in
  # FOSS_ONLY=1 <run_spec> leads to specs failing because the models don't exist in FOSS but
  # we've marked them as supported. (e.g db/docs/vulnerability_exports.yml)
  # rubocop:disable RSpec/InstanceVariable -- We need to track sql queries around all the specs
  describe 'runtime transfer tracking validation', :eager_load, if: Gitlab.ee? do
    before(:context) do
      @tracker = Gitlab::Organizations::TransferTracker.new(
        service_path_pattern: %r{app/services/.*#{transfer_path_pattern}}o
      )
      @tracker.track do
        load_and_run_transfer_specs
      end
    end

    let(:supported_tables) do
      org_sharded_tables.select do |entry|
        entry.organization_transfer_support == 'supported'
      end
    end

    it 'ensures tables marked supported were actually updated during transfer specs' do
      supported_tables.each do |entry|
        expect(@tracker.tracked_tables).to include(entry.table_name),
          "Table '#{entry.table_name}' has organization_transfer_support: supported " \
            "in db/docs/#{entry.table_name}.yml but was not updated during any transfer spec. " \
            "Either add test coverage, update the status to 'todo' if transfer support is " \
            "not yet implemented, or 'no_work_needed' if no transfer work is required."
      end
    end

    it 'ensures tables updated during transfer are marked as supported' do
      @tracker.tracked_table_locations.each do |table_name, locations|
        entry = Gitlab::Database::Dictionary.entry(table_name)

        locations_text = locations.to_a.sort.map { |loc| "  - #{loc}" }.join("\n")

        expect(entry.organization_transfer_support).to eq('supported'),
          "Table '#{table_name}' was updated during transfer at:\n" \
            "#{locations_text}\n" \
            "but has organization_transfer_support: '#{entry.organization_transfer_support}' " \
            "in db/docs/#{table_name}.yml. Update it to 'supported'."
      end
    end
    # rubocop:enable RSpec/InstanceVariable

    def transfer_path_pattern
      'organizations/transfer/'
    end

    def load_and_run_transfer_specs
      spec_files = transfer_spec_files

      raise ArgumentError, "Expected transfer specs at **/#{transfer_path_pattern} but found none" if spec_files.empty?

      spec_files.each { |file| require file }

      reporter = RSpec::Core::NullReporter

      transfer_group_examples(spec_files).each do |group|
        group.run(reporter)
      end
    end

    def transfer_spec_files
      Dir.glob(Rails.root.join("{,ee/}spec/services/**/#{transfer_path_pattern}**/*_spec.rb"))
    end

    # Called after specs are required so that they're visible in Rspec.world
    def transfer_group_examples(spec_files)
      RSpec.world.example_groups.select do |group|
        spec_files.include?(group.metadata[:absolute_file_path])
      end
    end
  end
end
