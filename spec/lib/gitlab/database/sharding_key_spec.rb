# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'new tables missing sharding_key', feature_category: :organization do
  include ShardingKeySpecHelpers

  # Specific tables can be temporarily exempt from this requirement. You must add an issue link in a comment next to
  # the table name to remove this once a decision has been made.
  let(:allowed_to_be_missing_sharding_key) do
    [
      'web_hook_logs_daily', # temporary copy of web_hook_logs
      'ci_gitlab_hosted_runner_monthly_usages', # https://gitlab.com/gitlab-org/gitlab/-/issues/553104
      'uploads_9ba88c4165', # https://gitlab.com/gitlab-org/gitlab/-/issues/398199
      'merge_request_diff_files_99208b8fac', # has a desired sharding key instead
      'notes_archived', # temp table: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191155
      'label_links_archived' # temp table: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/206448
    ]
  end

  # Specific tables can be temporarily exempt from this requirement. You must add an issue link in a comment next to
  # the table name to remove this once a decision has been made.
  let(:allowed_to_be_missing_not_null) do
    [
      *['badges.project_id', 'badges.group_id'], # https://gitlab.com/gitlab-org/gitlab/-/issues/562439
      'member_roles.namespace_id', # https://gitlab.com/gitlab-org/gitlab/-/issues/444161
      *['todos.project_id', 'todos.group_id'], # https://gitlab.com/gitlab-org/gitlab/-/issues/562437
      *[
        'bulk_import_trackers.organization_id',
        'bulk_import_trackers.project_id',
        'bulk_import_trackers.namespace_id'
      ], # https://gitlab.com/gitlab-org/gitlab/-/issues/560846
      *uploads_and_partitions,
      'ci_runner_taggings_group_type.organization_id', # NOT NULL constraint NOT VALID
      'ci_runner_taggings_project_type.organization_id', # NOT NULL constraint NOT VALID
      'group_type_ci_runner_machines.organization_id', # NOT NULL constraint NOT VALID
      'group_type_ci_runners.organization_id', # NOT NULL constraint NOT VALID
      'project_type_ci_runner_machines.organization_id', # NOT NULL constraint NOT VALID
      'project_type_ci_runners.organization_id', # NOT NULL constraint NOT VALID
      'security_scans.project_id', # NOT NULL constraint NOT VALID
      *['labels.group_id', 'labels.project_id', 'labels.organization_id'], # NOT NULL constraint NOT VALID
      'keys.organization_id'
    ]
  end

  # The following tables are work in progress as part of
  # https://gitlab.com/gitlab-org/gitlab/-/issues/398199
  # TODO: Remove these exceptions once the issue is closed.
  let(:uploads_and_partitions) do
    %w[
      achievement_uploads.namespace_id
      ai_vectorizable_file_uploads.project_id
      alert_management_alert_metric_image_uploads.project_id
      bulk_import_export_upload_uploads.project_id bulk_import_export_upload_uploads.namespace_id
      dependency_list_export_part_uploads.organization_id
      dependency_list_export_uploads.organization_id dependency_list_export_uploads.namespace_id
      dependency_list_export_uploads.project_id
      design_management_action_uploads.namespace_id
      import_export_upload_uploads.project_id import_export_upload_uploads.namespace_id
      issuable_metric_image_uploads.namespace_id
      namespace_uploads.namespace_id
      organization_detail_uploads.organization_id
      project_import_export_relation_export_upload_uploads.project_id
      project_topic_uploads.organization_id
      project_uploads.project_id
      snippet_uploads.organization_id
      vulnerability_export_part_uploads.organization_id
      vulnerability_export_uploads.organization_id
      vulnerability_archive_export_uploads.project_id
      vulnerability_remediation_uploads.project_id
    ]
  end

  # Some reasons to exempt a table:
  #   1. It has no foreign key for performance reasons
  #   2. It does not yet have a foreign key as the index is still being backfilled
  let(:allowed_to_be_missing_foreign_key) do
    [
      'ci_deleted_objects.project_id', # LFK already present on p_ci_builds and cascade delete all ci resources
      'ci_namespace_monthly_usages.namespace_id', # https://gitlab.com/gitlab-org/gitlab/-/issues/321400
      'ci_pipeline_chat_data.project_id',
      'p_ci_pipeline_variables.project_id',
      'ci_pipeline_messages.project_id',
      # LFK already present on ci_pipeline_schedules and cascade delete all ci resources.
      'ci_pipeline_schedule_variables.project_id',
      'ci_build_trace_chunks.project_id', # LFK already present on p_ci_builds and cascade delete all ci resources
      'p_ci_job_annotations.project_id', # LFK already present on p_ci_builds and cascade delete all ci resources
      'ci_build_pending_states.project_id', # LFK already present on p_ci_builds and cascade delete all ci resources
      'ci_builds_runner_session.project_id', # LFK already present on p_ci_builds and cascade delete all ci resources
      'ci_resources.project_id', # LFK already present on ci_resource_groups and cascade delete all ci resources
      'ci_unit_test_failures.project_id', # LFK already present on ci_unit_tests and cascade delete all ci resources
      'dast_profiles_pipelines.project_id', # LFK already present on dast_profiles and will cascade delete
      'dast_scanner_profiles_builds.project_id', # LFK already present on dast_scanner_profiles and will cascade delete
      'vulnerability_finding_links.project_id', # LFK already present on vulnerability_occurrence with cascade delete
      'vulnerability_occurrence_identifiers.project_id', # LFK present on vulnerability_occurrence with cascade delete
      'secret_detection_token_statuses.project_id',
      # LFK already present on vulnerability_occurrence with cascade delete.
      'ldap_group_links.group_id',
      'namespace_descendants.namespace_id',
      'p_batched_git_ref_updates_deletions.project_id',
      'p_catalog_resource_sync_events.project_id',
      'project_data_transfers.project_id', # https://gitlab.com/gitlab-org/gitlab/-/issues/439201
      'value_stream_dashboard_counts.namespace_id', # https://gitlab.com/gitlab-org/gitlab/-/issues/439555
      'project_audit_events.project_id',
      'group_audit_events.group_id',
      'user_audit_events.user_id',
      # aggregated table, a worker ensures eventual consistency
      'analytics_cycle_analytics_issue_stage_events.group_id',
      # aggregated table, a worker ensures eventual consistency
      'analytics_cycle_analytics_merge_request_stage_events.group_id',
      # This is event log table for gitlab_subscriptions and should not be deleted.
      # See more: https://gitlab.com/gitlab-org/gitlab/-/issues/462598#note_1949768698
      'gitlab_subscription_histories.namespace_id',
      # allowed as it points to itself
      'organizations.id',
      # contains an object storage reference. Group_id is the sharding key but we can't use the usual cascade delete FK.
      'virtual_registries_packages_maven_cache_entries.group_id',
      # The table contains references in the object storage and thus can't have cascading delete
      # nor being NULL by the definition of a sharding key.
      'packages_nuget_symbols.project_id',
      'packages_package_files.project_id',
      'merge_request_commits_metadata.project_id',
      'sbom_vulnerability_scans.project_id',
      'p_duo_workflows_checkpoints.project_id',
      'p_duo_workflows_checkpoints.namespace_id'
    ]
  end

  let(:starting_from_milestone) { 16.6 }

  it 'requires a sharding_key for all cell-local tables, after milestone 16.6', :aggregate_failures do
    tables_missing_sharding_key(starting_from_milestone: starting_from_milestone).each do |table_name|
      expect(allowed_to_be_missing_sharding_key).to include(table_name), error_message(table_name)
    end
  end

  it 'requires a sharding_key, sharding_key_issue_url, or desired_sharding_key for all cell-local tables',
    :aggregate_failures do
    tables_missing_sharding_key_or_sharding_in_progress.each do |table_name|
      expect(allowed_to_be_missing_sharding_key).to include(table_name),
        "This table #{table_name} is missing `sharding_key` in the `db/docs` YML file. " \
          "Alternatively, set either a `sharding_key_issue_url`, or desired_sharding_key` attribute. " \
          "Please refer to https://docs.gitlab.com/development/organization/#defining-a-sharding-key-for-all-organizational-tables."
    end
  end

  it 'ensures all sharding_key columns exist and reference projects, namespaces or organizations',
    :aggregate_failures do
    all_tables_to_sharding_key.each do |table_name, sharding_key, gitlab_schema|
      allowed_sharding_key_referenced_tables = ::Gitlab::Database::GitlabSchema.sharding_root_tables(gitlab_schema)

      sharding_key.each do |column_name, referenced_table_name|
        expect(column_exists?(table_name, column_name)).to eq(true),
          "Could not find sharding key column #{table_name}.#{column_name}"
        expect(referenced_table_name).to be_in(allowed_sharding_key_referenced_tables)

        if allowed_to_be_missing_foreign_key.include?("#{table_name}.#{column_name}")
          expect(has_foreign_key?(table_name, column_name)).to eq(false),
            "The column `#{table_name}.#{column_name}` has a foreign key so cannot be " \
              "allowed_to_be_missing_foreign_key. " \
              "If this is a foreign key referencing the specified table #{referenced_table_name} " \
              "then you must remove it from allowed_to_be_missing_foreign_key"
        else
          next if Gitlab::Database::PostgresPartition.partition_exists?(table_name)

          expect(has_foreign_key?(table_name, column_name, to_table_name: referenced_table_name)).to eq(true),
            "Missing a foreign key constraint for `#{table_name}.#{column_name}` " \
              "referencing #{referenced_table_name}. " \
              "All sharding keys must have a foreign key constraint"
        end
      end
    end
  end

  it 'ensures all sharding_key columns are not nullable or have a not null check constraint',
    :aggregate_failures do
    all_tables_to_sharding_key.each do |table_name, sharding_key, _gitlab_schema|
      sharding_key_columns = sharding_key.keys

      if sharding_key_columns.one?
        column_name = sharding_key_columns.first
        not_nullable = not_nullable?(table_name, column_name)
        has_null_check_constraint = has_null_check_constraint?(table_name, column_name)

        if allowed_to_be_missing_not_null.include?("#{table_name}.#{column_name}")
          expect(not_nullable || has_null_check_constraint).to eq(false),
            "You must remove `#{table_name}.#{column_name}` from allowed_to_be_missing_not_null " \
              "since it now has a valid constraint."
        else
          expect(not_nullable || has_null_check_constraint).to eq(true),
            "Missing a not null constraint for `#{table_name}.#{column_name}`. " \
              "All sharding keys must be not nullable or have a NOT NULL check constraint"
        end
      else
        allowed_columns = allowed_to_be_missing_not_null & sharding_key_columns.map { |c| "#{table_name}.#{c}" }
        has_null_check_constraint = has_multi_column_null_check_constraint?(table_name, sharding_key_columns)

        if allowed_columns.present?
          if allowed_columns.length != sharding_key_columns.length
            expect(allowed_columns.length).to eq(sharding_key_columns.length),
              "`#{table_name}` has sharding keys #{sharding_key_columns.to_sentence} but " \
                "allowed_to_be_missing_not_null contains only #{allowed_columns.to_sentence}. " \
                "allowed_to_be_missing_not_null must contain all sharding key columns, or none"
          else
            expect(has_null_check_constraint).to eq(false),
              "You must remove #{allowed_columns.to_sentence} from allowed_to_be_missing_not_null " \
                "since there is now a valid constraint"
          end
        else
          expect(has_null_check_constraint).to eq(true),
            "Missing a not null constraint for #{sharding_key_columns.to_sentence} on `#{table_name}`. " \
              "All sharding keys must have a NOT NULL check constraint. For more information on constraints for " \
              "multiple columns, see https://docs.gitlab.com/ee/development/database/not_null_constraints.html#not-null-constraints-for-multiple-columns"
        end
      end
    end
  end

  it 'ensures all organization_id columns are not nullable, have no default, and have a foreign key' do
    loose_foreign_keys = Gitlab::Database::LooseForeignKeys.definitions.group_by(&:from_table)

    # Step 1: Get all tables with organization_id columns
    tables_sql = <<~SQL
      SELECT table_name
      FROM information_schema.columns
      WHERE column_name = 'organization_id'
        AND table_schema = 'public'
      ORDER BY table_name;
    SQL

    table_names = ApplicationRecord.connection.select_values(tables_sql)

    # Step 2: Check each table individually to avoid complex joins
    organization_id_columns = []

    # Process in batches of 50 to avoid statement timeout issues with large queries
    table_names.each_slice(50) do |table_batch|
      batch_conditions = table_batch.map do |table|
        table_name = ApplicationRecord.connection.quote(table)
        "c.table_name = #{table_name}"
      end.join(' OR ')

      batch_sql = <<~SQL
        SELECT c.table_name,
          CASE WHEN c.column_default IS NOT NULL THEN 'has default' ELSE NULL END,
          CASE WHEN c.is_nullable::boolean THEN 'nullable / not null constraint missing' ELSE NULL END
        FROM information_schema.columns c
        WHERE c.column_name = 'organization_id'
          AND c.table_schema = 'public'
          AND (#{batch_conditions})
        ORDER BY c.table_name;
      SQL

      batch_results = ApplicationRecord.connection.select_rows(batch_sql)
      organization_id_columns.concat(batch_results)
    end

    # Step 3: Check foreign keys using Rails schema introspection
    work_in_progress = {
      "web_hooks" => "https://gitlab.com/gitlab-org/gitlab/-/issues/524812",
      "snippet_user_mentions" => "https://gitlab.com/gitlab-org/gitlab/-/issues/517825",
      "bulk_import_trackers" => "https://gitlab.com/gitlab-org/gitlab/-/issues/560846",
      "organization_users" => 'https://gitlab.com/gitlab-org/gitlab/-/issues/476210',
      "push_rules" => 'https://gitlab.com/gitlab-org/gitlab/-/issues/476212',
      "topics" => 'https://gitlab.com/gitlab-org/gitlab/-/issues/463254',
      "oauth_access_tokens" => "https://gitlab.com/gitlab-org/gitlab/-/issues/496717",
      "oauth_access_grants" => "https://gitlab.com/gitlab-org/gitlab/-/issues/496717",
      "oauth_openid_requests" => "https://gitlab.com/gitlab-org/gitlab/-/issues/496717",
      "oauth_device_grants" => "https://gitlab.com/gitlab-org/gitlab/-/issues/496717",
      "ai_duo_chat_events" => "https://gitlab.com/gitlab-org/gitlab/-/issues/516140",
      "fork_networks" => "https://gitlab.com/gitlab-org/gitlab/-/issues/522958",
      "bulk_import_configurations" => "https://gitlab.com/gitlab-org/gitlab/-/issues/536521",
      "pool_repositories" => "https://gitlab.com/gitlab-org/gitlab/-/issues/490484",
      'todos' => 'https://gitlab.com/gitlab-org/gitlab/-/issues/562437',
      # All the tables below related to uploads are part of the same work to
      # add sharding key to the table
      "admin_roles" => "https://gitlab.com/gitlab-org/gitlab/-/issues/553437",
      "uploads" => "https://gitlab.com/gitlab-org/gitlab/-/issues/398199",
      "abuse_report_uploads" => "https://gitlab.com/gitlab-org/gitlab/-/issues/398199",
      "achievement_uploads" => "https://gitlab.com/gitlab-org/gitlab/-/issues/398199",
      "ai_vectorizable_file_uploads" => "https://gitlab.com/gitlab-org/gitlab/-/issues/398199",
      "alert_management_alert_metric_image_uploads" => "https://gitlab.com/gitlab-org/gitlab/-/issues/398199",
      "appearance_uploads" => "https://gitlab.com/gitlab-org/gitlab/-/issues/398199",
      "bulk_import_export_upload_uploads" => "https://gitlab.com/gitlab-org/gitlab/-/issues/398199",
      "dependency_list_export_part_uploads" => "https://gitlab.com/gitlab-org/gitlab/-/issues/398199",
      "dependency_list_export_uploads" => "https://gitlab.com/gitlab-org/gitlab/-/issues/398199",
      "design_management_action_uploads" => "https://gitlab.com/gitlab-org/gitlab/-/issues/398199",
      "import_export_upload_uploads" => "https://gitlab.com/gitlab-org/gitlab/-/issues/398199",
      "issuable_metric_image_uploads" => "https://gitlab.com/gitlab-org/gitlab/-/issues/398199",
      "namespace_uploads" => "https://gitlab.com/gitlab-org/gitlab/-/issues/398199",
      "organization_detail_uploads" => "https://gitlab.com/gitlab-org/gitlab/-/issues/398199",
      "project_import_export_relation_export_upload_uploads" => "https://gitlab.com/gitlab-org/gitlab/-/issues/398199",
      "project_topic_uploads" => "https://gitlab.com/gitlab-org/gitlab/-/issues/398199",
      "project_uploads" => "https://gitlab.com/gitlab-org/gitlab/-/issues/398199",
      "snippet_uploads" => "https://gitlab.com/gitlab-org/gitlab/-/issues/398199",
      "uploads_9ba88c4165" => "https://gitlab.com/gitlab-org/gitlab/-/issues/398199",
      "user_permission_export_upload_uploads" => "https://gitlab.com/gitlab-org/gitlab/-/issues/398199",
      "user_uploads" => "https://gitlab.com/gitlab-org/gitlab/-/issues/398199",
      "vulnerability_export_part_uploads" => "https://gitlab.com/gitlab-org/gitlab/-/issues/398199",
      "vulnerability_export_uploads" => "https://gitlab.com/gitlab-org/gitlab/-/issues/398199",
      "vulnerability_archive_export_uploads" => "https://gitlab.com/gitlab-org/gitlab/-/issues/398199",
      "vulnerability_remediation_uploads" => "https://gitlab.com/gitlab-org/gitlab/-/issues/398199",
      # End of uploads related tables
      "ci_runner_machines" => "https://gitlab.com/gitlab-org/gitlab/-/issues/525293",
      "clusters" => "https://gitlab.com/gitlab-org/gitlab/-/issues/553452",
      "instance_type_ci_runners" => "https://gitlab.com/gitlab-org/gitlab/-/issues/525293",
      "group_type_ci_runner_machines" => "https://gitlab.com/gitlab-org/gitlab/-/issues/525293",
      "project_type_ci_runner_machines" => "https://gitlab.com/gitlab-org/gitlab/-/issues/525293",
      "ci_runner_taggings" => "https://gitlab.com/gitlab-org/gitlab/-/issues/525293",
      "ci_runner_taggings_instance_type" => "https://gitlab.com/gitlab-org/gitlab/-/issues/525293",
      "ci_runners" => "https://gitlab.com/gitlab-org/gitlab/-/issues/525293",
      "group_type_ci_runners" => "https://gitlab.com/gitlab-org/gitlab/-/issues/525293",
      "instance_type_ci_runner_machines" => "https://gitlab.com/gitlab-org/gitlab/-/issues/525293",
      "project_type_ci_runners" => "https://gitlab.com/gitlab-org/gitlab/-/issues/525293",
      "ci_runner_taggings_group_type" => "https://gitlab.com/gitlab-org/gitlab/-/issues/549027",
      "ci_runner_taggings_project_type" => "https://gitlab.com/gitlab-org/gitlab/-/issues/549028",
      "customer_relations_contacts" => "https://gitlab.com/gitlab-org/gitlab/-/issues/549029",
      "jira_tracker_data" => "https://gitlab.com/gitlab-org/gitlab/-/issues/549032",
      "abuse_reports" => "https://gitlab.com/gitlab-org/gitlab/-/issues/553435",
      "abuse_report_labels" => "https://gitlab.com/gitlab-org/gitlab/-/issues/553427",
      "abuse_report_events" => "https://gitlab.com/gitlab-org/gitlab/-/issues/553429",
      "abuse_events" => "https://gitlab.com/gitlab-org/gitlab/-/issues/553427",
      "spam_logs" => "https://gitlab.com/gitlab-org/gitlab/-/issues/553470",
      "abuse_report_assignees" => "https://gitlab.com/gitlab-org/gitlab/-/issues/553428",
      "labels" => "https://gitlab.com/gitlab-org/gitlab/-/issues/563889",
      "member_roles" => "https://gitlab.com/gitlab-org/gitlab/-/issues/567738",
      "notes" => "https://gitlab.com/gitlab-org/gitlab/-/issues/569521",
      "notes_archived" => "https://gitlab.com/gitlab-org/gitlab/-/issues/569521",
      "system_note_metadata" => "https://gitlab.com/gitlab-org/gitlab/-/issues/571215",
      "note_diff_files" => "https://gitlab.com/gitlab-org/gitlab/-/issues/550694",
      "keys" => "https://gitlab.com/gitlab-org/gitlab/-/issues/553463",
      "suggestions" => "https://gitlab.com/gitlab-org/gitlab/-/issues/550696",
      "commit_user_mentions" => "https://gitlab.com/gitlab-org/gitlab/-/issues/550692"
    }

    has_lfk = ->(lfks) { lfks.any? { |k| k.options[:column] == 'organization_id' && k.to_table == 'organizations' } }

    columns_to_check = organization_id_columns.reject { |column| work_in_progress[column[0]] }
    messages = columns_to_check.filter_map do |column|
      table_name = column[0]
      violations = column[1..].compact

      # Check foreign keys using Rails
      begin
        foreign_keys = ApplicationRecord.connection.foreign_keys(table_name)
        org_fk = foreign_keys.find { |fk| fk.column == 'organization_id' && fk.to_table == 'organizations' }

        violations << 'no foreign key' unless org_fk || has_lfk.call(loose_foreign_keys.fetch(table_name, {}))
      rescue ActiveRecord::StatementInvalid
        # Table might not exist or be accessible
        violations << 'no foreign key'
      end

      violations.delete_if do |v|
        (v == 'nullable / not null constraint missing' && has_null_check_constraint?(table_name, 'organization_id')) ||
          (v == 'no foreign key' && has_lfk.call(loose_foreign_keys.fetch(table_name, {})))
      end

      "  #{table_name} - #{violations.join(', ')}" if violations.any?
    end

    expect(messages).to be_empty, "Expected all organization_id columns to be not nullable, have no default, " \
      "and have a validated foreign key, but the following tables do not meet this criteria:" \
      "\n#{messages.join("\n")}\n\n" \
      "If this is a work in progress, please create an issue under " \
      "https://gitlab.com/groups/gitlab-org/-/epics/11670, " \
      "and add the table to the work in progress list in this test."
  end

  it 'only allows `allowed_to_be_missing_sharding_key` to include tables that are missing a sharding_key',
    :aggregate_failures do
    allowed_to_be_missing_sharding_key.each do |exempted_table|
      expect(tables_missing_sharding_key(starting_from_milestone: starting_from_milestone)).to include(exempted_table),
        "`#{exempted_table}` is not missing a `sharding_key`. " \
          "You must remove this table from the `allowed_to_be_missing_sharding_key` list."
    end
  end

  it 'only allows `allowed_to_be_missing_not_null` to include sharding keys',
    :aggregate_failures do
    allowed_to_be_missing_not_null.each do |exemption|
      table, column = exemption.split('.')
      entry = ::Gitlab::Database::Dictionary.entry(table)

      expect(entry&.sharding_key&.keys).to include(column),
        "`#{exemption}` is not a `sharding_key`. " \
          "You must remove this entry from the `allowed_to_be_missing_not_null` list."
    end
  end

  it 'only allows `allowed_to_be_missing_foreign_key` to include sharding keys',
    :aggregate_failures do
    allowed_to_be_missing_foreign_key.each do |exemption|
      table, column = exemption.split('.')
      entry = ::Gitlab::Database::Dictionary.entry(table)

      expect(entry&.sharding_key&.keys).to include(column),
        "`#{exemption}` is not a `sharding_key`. " \
          "You must remove this entry from the `allowed_to_be_missing_foreign_key` list."
    end
  end

  it 'allows tables that have a sharding key to only have a sharding-key-required schema' do
    expect(tables_with_sharding_keys_not_in_sharding_key_required_schema).to be_empty, <<~ERROR.squish
      Tables: #{tables_with_sharding_keys_not_in_sharding_key_required_schema.join(',')}
      have a sharding key defined, but does not have a sharding-key-required schema assigned.
      Tables with sharding keys should have a schema where `require_sharding_key` is enabled
      like `gitlab_main_org` or `gitlab_ci`.
      Please change the `gitlab_schema` of these tables accordingly.
    ERROR
  end

  it 'does not allow invalid follow-up issue URLs', :aggregate_failures do
    issue_url_regex = %r{\Ahttps://gitlab\.com/gitlab-org/gitlab/-/issues/\d+\z}

    entries_with_issue_link.each do |entry|
      if entry.sharding_key.present? || entry.desired_sharding_key.present?
        expect(entry.sharding_key_issue_url).not_to be_present,
          "You must remove `sharding_key_issue_url` from #{entry.table_name} now that it " \
            "has a valid sharding key/desired sharding key."
      else
        expect(entry.sharding_key_issue_url).to match(issue_url_regex),
          "Invalid `sharding_key_issue_url` url for #{entry.table_name}. Please use the following format: " \
            "https://gitlab.com/gitlab-org/gitlab/-/issues/XXX"
      end
    end
  end

  private

  def error_message(table_name)
    <<~HEREDOC
      The table `#{table_name}` is missing a `sharding_key` in the `db/docs` YML file.
      Starting from GitLab #{starting_from_milestone}, we expect all new tables to define a `sharding_key`.

      To choose an appropriate sharding_key for this table please refer
      to our guidelines at https://docs.gitlab.com/ee/development/organization/#defining-a-sharding-key-for-all-cell-local-tables, or consult with the Tenant Scale group.
    HEREDOC
  end

  def tables_missing_sharding_key(starting_from_milestone:)
    ::Gitlab::Database::Dictionary.entries.filter_map do |entry|
      entry.table_name if entry.sharding_key.blank? &&
        entry.milestone_greater_than_or_equal_to?(starting_from_milestone) &&
        ::Gitlab::Database::GitlabSchema.require_sharding_key?(entry.gitlab_schema)
    end
  end

  def tables_missing_sharding_key_or_sharding_in_progress
    ::Gitlab::Database::Dictionary.entries.filter_map do |entry|
      entry.table_name if entry.sharding_key.blank? &&
        entry.sharding_key_issue_url.blank? &&
        entry.desired_sharding_key.blank? &&
        ::Gitlab::Database::GitlabSchema.require_sharding_key?(entry.gitlab_schema)
    end
  end

  def entries_with_issue_link
    ::Gitlab::Database::Dictionary.entries.select do |entry|
      entry.sharding_key_issue_url.present?
    end
  end

  def all_tables_to_sharding_key
    entries_with_sharding_key = ::Gitlab::Database::Dictionary.entries.select do |entry|
      entry.sharding_key.present?
    end

    entries_with_sharding_key.map do |entry|
      [entry.table_name, entry.sharding_key, entry.gitlab_schema]
    end
  end

  def tables_with_sharding_keys_not_in_sharding_key_required_schema
    ::Gitlab::Database::Dictionary.entries.filter_map do |entry|
      entry.table_name if entry.sharding_key.present? &&
        !::Gitlab::Database::GitlabSchema.require_sharding_key?(entry.gitlab_schema)
    end
  end
end
