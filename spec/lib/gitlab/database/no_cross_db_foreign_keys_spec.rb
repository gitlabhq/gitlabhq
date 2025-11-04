# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'cross-database foreign keys', feature_category: :database do
  # Pre-existing FK that needs to be converted to loose foreign keys
  #
  # The issue corresponding to the loose foreign key conversion
  # should be added as a comment along with the name of the column.
  let!(:allowed_cross_database_foreign_keys) do
    keys = [
      'excluded_merge_requests.merge_request_id',                        # https://gitlab.com/gitlab-org/gitlab/-/issues/517248
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
      'container_repository_states.project_id',                          # https://gitlab.com/groups/gitlab-org/-/epics/17347
      'container_repository_states.container_repository_id',             # https://gitlab.com/groups/gitlab-org/-/epics/17347
      'design_management_repository_states.namespace_id',                # https://gitlab.com/groups/gitlab-org/-/epics/17347
      'design_management_repository_states.design_management_repository_id', # https://gitlab.com/groups/gitlab-org/-/epics/17347
      'wiki_repository_states.project_id',                               # https://gitlab.com/groups/gitlab-org/-/epics/17347
      'wiki_repository_states.project_wiki_repository_id',               # https://gitlab.com/groups/gitlab-org/-/epics/17347
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
