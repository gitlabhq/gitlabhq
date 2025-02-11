# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'new tables missing sharding_key', feature_category: :cell do
  include ShardingKeySpecHelpers

  # Specific tables can be temporarily exempt from this requirement. You must add an issue link in a comment next to
  # the table name to remove this once a decision has been made.
  let(:allowed_to_be_missing_sharding_key) do
    [
      'merge_request_diff_commits_b5377a7a34', # has a desired sharding key instead
      'merge_request_diff_files_99208b8fac', # has a desired sharding key instead
      'p_ci_pipeline_variables', # has a desired sharding key instead
      'web_hook_logs_daily' # temporary copy of web_hook_logs
    ]
  end

  # Specific tables can be temporarily exempt from this requirement. You must add an issue link in a comment next to
  # the table name to remove this once a decision has been made.
  let(:allowed_to_be_missing_not_null) do
    [
      *tables_with_alternative_not_null_constraint,
      'analytics_devops_adoption_segments.namespace_id',
      *['badges.project_id', 'badges.group_id'],
      'ci_pipeline_schedules.project_id',
      'ci_sources_pipelines.project_id',
      'ci_triggers.project_id',
      'gpg_signatures.project_id',
      *['internal_ids.project_id', 'internal_ids.namespace_id'], # https://gitlab.com/gitlab-org/gitlab/-/issues/451900
      *['labels.project_id', 'labels.group_id'], # https://gitlab.com/gitlab-org/gitlab/-/issues/434356
      'member_roles.namespace_id', # https://gitlab.com/gitlab-org/gitlab/-/issues/444161
      'sprints.group_id',
      *['todos.project_id', 'todos.group_id']
    ]
  end

  # The following tables have multiple sharding keys and a check constraint that
  # correctly ensures at least one of the keys must be set, however the constraint
  # definition is written in a way that is difficult to verify using these specs.
  # For example:
  #   `CONSTRAINT example_constraint CHECK (((project_id IS NULL) <> (namespace_id IS NULL)))`
  let(:tables_with_alternative_not_null_constraint) do
    [
      *['protected_environments.project_id', 'protected_environments.group_id'],
      'security_orchestration_policy_configurations.project_id',
      'security_orchestration_policy_configurations.namespace_id',
      *['protected_branches.project_id', 'protected_branches.namespace_id']
    ]
  end

  # Some reasons to exempt a table:
  #   1. It has no foreign key for performance reasons
  #   2. It does not yet have a foreign key as the index is still being backfilled
  let(:allowed_to_be_missing_foreign_key) do
    [
      'ci_builds_metadata.project_id',
      'ci_deleted_objects.project_id', # LFK already present on p_ci_builds and cascade delete all ci resources
      'ci_job_artifacts.project_id',
      'ci_namespace_monthly_usages.namespace_id', # https://gitlab.com/gitlab-org/gitlab/-/issues/321400
      'ci_pipeline_chat_data.project_id',
      'ci_pipeline_messages.project_id',
      'p_ci_job_annotations.project_id', # LFK already present on p_ci_builds and cascade delete all ci resources
      'p_ci_pipelines_config.project_id', # LFK already present on p_ci_pipelines and cascade delete all ci resources
      'dast_profiles_pipelines.project_id', # LFK already present on dast_profiles and will cascade delete
      'dast_scanner_profiles_builds.project_id', # LFK already present on dast_scanner_profiles and will cascade delete
      'ldap_group_links.group_id',
      'namespace_descendants.namespace_id',
      'p_batched_git_ref_updates_deletions.project_id',
      'p_catalog_resource_sync_events.project_id',
      'project_data_transfers.project_id', # https://gitlab.com/gitlab-org/gitlab/-/issues/439201
      'value_stream_dashboard_counts.namespace_id', # https://gitlab.com/gitlab-org/gitlab/-/issues/439555
      'zoekt_tasks.project_identifier',
      'project_audit_events.project_id',
      'group_audit_events.group_id',
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
      'packages_nuget_symbols.project_id'
    ]
  end

  let(:starting_from_milestone) { 16.6 }

  let(:allowed_sharding_key_referenced_tables) { %w[projects namespaces organizations] }

  it 'requires a sharding_key for all cell-local tables, after milestone 16.6', :aggregate_failures do
    tables_missing_sharding_key(starting_from_milestone: starting_from_milestone).each do |table_name|
      expect(allowed_to_be_missing_sharding_key).to include(table_name), error_message(table_name)
    end
  end

  it 'ensures all sharding_key columns exist and reference projects, namespaces or organizations',
    :aggregate_failures do
    all_tables_to_sharding_key.each do |table_name, sharding_key|
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
    all_tables_to_sharding_key.each do |table_name, sharding_key|
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

    sql = <<~SQL
      SELECT c.table_name,
        CASE WHEN c.column_default IS NOT NULL THEN 'has default' ELSE NULL END,
        CASE WHEN c.is_nullable::boolean THEN 'nullable / not null constraint missing' ELSE NULL END,
        CASE WHEN fk.name IS NULL THEN 'no foreign key' ELSE
          CASE WHEN fk.is_valid THEN NULL ELSE 'foreign key exist but it is not validated' END
        END
      FROM information_schema.columns c
      LEFT JOIN postgres_foreign_keys fk
      ON fk.constrained_table_name = c.table_name AND fk.constrained_columns = '{organization_id}' and fk.referenced_columns = '{id}'
      WHERE c.column_name = 'organization_id'
        AND (fk.referenced_table_name = 'organizations' OR fk.referenced_table_name IS NULL)
        AND (c.column_default IS NOT NULL OR c.is_nullable::boolean OR fk.name IS NULL OR NOT fk.is_valid)
      ORDER BY c.table_name;
    SQL

    # To add a table to this list, create an issue under https://gitlab.com/groups/gitlab-org/-/epics/11670.
    # Use https://gitlab.com/gitlab-org/gitlab/-/issues/476206 as an example.
    work_in_progress = {
      "organization_users" => 'https://gitlab.com/gitlab-org/gitlab/-/issues/476210',
      "push_rules" => 'https://gitlab.com/gitlab-org/gitlab/-/issues/476212',
      "snippets" => 'https://gitlab.com/gitlab-org/gitlab/-/issues/476216',
      "topics" => 'https://gitlab.com/gitlab-org/gitlab/-/issues/463254',
      "oauth_access_tokens" => "https://gitlab.com/gitlab-org/gitlab/-/issues/496717",
      "oauth_access_grants" => "https://gitlab.com/gitlab-org/gitlab/-/issues/496717",
      "oauth_openid_requests" => "https://gitlab.com/gitlab-org/gitlab/-/issues/496717",
      "oauth_device_grants" => "https://gitlab.com/gitlab-org/gitlab/-/issues/496717",
      "uploads" => "https://gitlab.com/gitlab-org/gitlab/-/issues/398199",
      "bulk_import_trackers" => "https://gitlab.com/gitlab-org/gitlab/-/issues/517823"
    }

    has_lfk = ->(lfks) { lfks.any? { |k| k.options[:column] == 'organization_id' && k.to_table == 'organizations' } }

    organization_id_columns = ApplicationRecord.connection.select_rows(sql)
    checks = organization_id_columns.reject { |column| work_in_progress[column[0]] }
    messages = checks.filter_map do |check|
      table_name, *violations = check

      violations.delete_if do |v|
        (v == 'nullable / not null constraint missing' && has_null_check_constraint?(table_name, 'organization_id')) ||
          (v == 'no foreign key' && has_lfk.call(loose_foreign_keys.fetch(table_name, {})))
      end

      "  #{table_name} - #{violations.compact.join(', ')}" if violations.any?
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

  it 'does not allow tables that are permanently exempted from sharding to have sharding keys' do
    tables_exempted_from_sharding.each do |entry|
      expect(entry.sharding_key).to be_nil,
        "#{entry.table_name} is exempted from sharding and hence should not have a sharding key defined"
    end
  end

  it 'does not allow tables with FK references to be permanently exempted', :aggregate_failures do
    tables_exempted_from_sharding_table_names = tables_exempted_from_sharding.map(&:table_name)

    tables_exempted_from_sharding.each do |entry|
      fks = referenced_foreign_keys(entry.table_name).to_a

      fks.reject! { |fk| fk.constrained_table_name.in?(tables_exempted_from_sharding_table_names) }

      # Remove after https://gitlab.com/gitlab-org/gitlab/-/issues/515383 is resolved
      tables_to_be_fixed = %w[shards]
      if entry.table_name.in?(tables_to_be_fixed)
        raise "Expected there to be failures, but no failures for #{entry.table_name}." unless fks.present?

        puts "Table #{entry.table_name} will need to be fixed later. There are references from:\n\n" \
          "#{fks.map(&:constrained_table_name).join("\n")}"

        next
      end

      # rubocop:disable Layout/LineLength -- sorry, long URL
      expect(fks).to be_empty,
        "#{entry.table_name} is exempted from sharding, but has foreign key references to it.\n" \
          "For more information, see " \
          "https://docs.gitlab.com/ee/development/database/multiple_databases.html#exempting-certain-tables-from-having-sharding-keys.\n" \
          "The tables with foreign key references are:\n\n" \
          "#{fks.map(&:constrained_table_name).join("\n")}"
      # rubocop:enable Layout/LineLength

      lfks = referenced_loose_foreign_keys(entry.table_name)
      lfks.reject! { |lfk| lfk.from_table.in?(tables_exempted_from_sharding_table_names) }

      # rubocop:disable Layout/LineLength -- sorry, long URL
      expect(lfks).to be_empty,
        "#{entry.table_name} is exempted from sharding, but has loose foreign key references to it.\n" \
          "For more information, see " \
          "https://docs.gitlab.com/ee/development/database/multiple_databases.html#exempting-certain-tables-from-having-sharding-keys.\n" \
          "The tables with loose foreign key references are:\n\n" \
          "#{lfks.map(&:from_table).join("\n")}"
      # rubocop:enable Layout/LineLength
    end
  end

  it 'allows tables that have a sharding key to only have a sharding-key-required schema' do
    expect(tables_with_sharding_keys_not_in_sharding_key_required_schema).to be_empty, <<~ERROR.squish
      Tables: #{tables_with_sharding_keys_not_in_sharding_key_required_schema.join(',')}
      have a sharding key defined, but does not have a sharding-key-required schema assigned.
      Tables with sharding keys should have a schema where `require_sharding_key` is enabled
      like `gitlab_main_cell` or `gitlab_ci`.
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
      to our guidelines at https://docs.gitlab.com/ee/development/cells/#defining-a-sharding-key-for-all-cell-local-tables, or consult with the Tenant Scale group.
    HEREDOC
  end

  def tables_missing_sharding_key(starting_from_milestone:)
    ::Gitlab::Database::Dictionary.entries.filter_map do |entry|
      entry.table_name if entry.sharding_key.blank? &&
        !entry.exempt_from_sharding? &&
        entry.milestone_greater_than_or_equal_to?(starting_from_milestone) &&
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

    entries_with_sharding_key.to_h do |entry|
      [entry.table_name, entry.sharding_key]
    end
  end

  def tables_exempted_from_sharding
    ::Gitlab::Database::Dictionary.entries.select(&:exempt_from_sharding?)
  end

  def tables_with_sharding_keys_not_in_sharding_key_required_schema
    ::Gitlab::Database::Dictionary.entries.filter_map do |entry|
      entry.table_name if entry.sharding_key.present? &&
        !::Gitlab::Database::GitlabSchema.require_sharding_key?(entry.gitlab_schema)
    end
  end
end
