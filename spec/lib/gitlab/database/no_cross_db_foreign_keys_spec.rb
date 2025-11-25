# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'cross-database foreign keys', feature_category: :database do
  # Acceptable cross-schema foreign key patterns with directionality
  # Format: [from_schema, to_schema]
  # Cell-local tables can reference org tables because the FK direction
  # (cell-local -> org) does not block data migration.
  let!(:acceptable_cross_schema_foreign_key_patterns) do
    [
      [:gitlab_main_cell_local, :gitlab_main_org],
      [:gitlab_ci_cell_local, :gitlab_ci]
    ]
  end

  # Pre-existing FK that needs to be converted to loose foreign keys
  #
  # The issue corresponding to the loose foreign key conversion
  # should be added as a comment along with the name of the column.
  let!(:allowed_cross_database_foreign_keys) do
    keys = [
      'lfs_objects_projects.lfs_object_id',
      'p_ci_build_tags.tag_id',                                     # https://gitlab.com/gitlab-org/gitlab/-/issues/470872
      'targeted_message_dismissals.targeted_message_id',            # https://gitlab.com/gitlab-org/gitlab/-/issues/531357
      'user_broadcast_message_dismissals.broadcast_message_id',     # https://gitlab.com/gitlab-org/gitlab/-/issues/531358
      'targeted_message_namespaces.targeted_message_id',            # https://gitlab.com/gitlab-org/gitlab/-/issues/531357
      'term_agreements.term_id',                                    # https://gitlab.com/gitlab-org/gitlab/-/issues/531367
      'appearance_uploads.uploaded_by_user_id',                     # https://gitlab.com/gitlab-org/gitlab/-/issues/534207
      'appearance_uploads.project_id',                              # https://gitlab.com/gitlab-org/gitlab/-/issues/534207
      'appearance_uploads.namespace_id',                            # https://gitlab.com/gitlab-org/gitlab/-/issues/534207
      'appearance_uploads.organization_id',                         # https://gitlab.com/gitlab-org/gitlab/-/issues/534207
      'application_settings.workspaces_oauth_application_id',       # https://gitlab.com/gitlab-org/gitlab/-/issues/574704
      'application_settings.web_ide_oauth_application_id',          # https://gitlab.com/gitlab-org/gitlab/-/issues/574704

      # https://gitlab.com/gitlab-org/gitlab/-/issues/560435
      'dingtalk_tracker_data.integration_id',

      # https://gitlab.com/gitlab-org/gitlab/-/issues/560712
      'audit_events_streaming_instance_namespace_filters.external_streaming_destination_id',
      'audit_events_streaming_http_instance_namespace_filters.namespace_id'
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

  def matches_acceptable_cross_schema_fk?(fk)
    from_schema = Gitlab::Database::GitlabSchema.table_schema!(fk.from_table)
    to_schema = Gitlab::Database::GitlabSchema.table_schema!(fk.to_table)

    acceptable_cross_schema_foreign_key_patterns.any? do |acceptable_from, acceptable_to|
      from_schema == acceptable_from && to_schema == acceptable_to
    end
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

  it 'only has allowed list of cross-database foreign keys', :aggregate_failures do
    all_tables = ApplicationRecord.connection.data_sources
    allowlist = allowed_cross_database_foreign_keys.dup

    all_tables.each do |table|
      foreign_keys_for(table).each do |fk|
        next unless is_cross_db?(fk)

        column = "#{fk.from_table}.#{Array.wrap(fk.column).join('.')}"

        if matches_acceptable_cross_schema_fk?(fk)
          # Print FK matching acceptable cross-schema pattern, for informational purposes
          warn "\nℹ️  Found cross-schema foreign key matching acceptable pattern: #{column}"
        else
          # Fail for cross-DB FKs that don't match acceptable patterns
          allowlist.delete(column)
          expect(allowed_cross_database_foreign_keys).to include(column), cross_db_failure_message(column, fk)
        end
      end
    end

    formatted_allowlist = allowlist.map { |item| "- #{item}" }.join("\n")
    expect(allowlist).to be_empty,
      "The following items must be removed from the `allowed_cross_database_foreign_keys` list," \
        "as it no longer appears as cross-database foreign key:\n" \
        "#{formatted_allowlist}"
  end

  it 'only allows existing foreign keys in the exempted list', :aggregate_failures do
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
