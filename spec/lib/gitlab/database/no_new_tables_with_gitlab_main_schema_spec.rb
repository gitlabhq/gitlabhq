# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'new tables with gitlab_main schema', feature_category: :cell do
  # During the development of Cells, we will be moving tables from the `gitlab_main` schema
  # to either the `gitlab_main_cell`, or another schema in
  # https://docs.gitlab.com/development/cells/#available-cells--organization-schemas.
  # As part of this process, starting from milestone 16.7, it will be a mandatory requirement that
  # all newly created tables are associated with one of these two schemas.
  # Any attempt to set the `gitlab_main` schema for a new table will result in a failure of this spec.

  # Specific tables can be exempted from this requirement, and such tables must be added to the `exempted_tables` list.
  let!(:exempted_tables) do
    [
      'abuse_report_assignees',                                 # gitlab_main_clusterwide now deprecated
      'abuse_report_label_links',                               # gitlab_main_clusterwide now deprecated
      'abuse_report_labels',                                    # gitlab_main_clusterwide now deprecated
      'abuse_report_notes',                                     # gitlab_main_clusterwide now deprecated
      'abuse_report_uploads',                                   # gitlab_main_clusterwide now deprecated
      'admin_roles',                                            # gitlab_main_clusterwide now deprecated
      'ai_feature_settings',                                    # gitlab_main_clusterwide now deprecated
      'ai_self_hosted_models',                                  # gitlab_main_clusterwide now deprecated
      'ai_testing_terms_acceptances',                           # gitlab_main_clusterwide now deprecated
      'audit_events_instance_amazon_s3_configurations',         # gitlab_main_clusterwide now deprecated
      'audit_events_instance_external_streaming_destinations',  # gitlab_main_clusterwide now deprecated
      'audit_events_instance_streaming_event_type_filters',     # gitlab_main_clusterwide now deprecated
      'cloud_connector_keys',                                   # gitlab_main_clusterwide now deprecated
      'instance_audit_events',                                  # gitlab_main_clusterwide now deprecated
      'instance_integrations',                                  # gitlab_main_clusterwide now deprecated
      'ldap_admin_role_links',                                  # gitlab_main_clusterwide now deprecated
      'user_audit_events',                                      # gitlab_main_clusterwide now deprecated
      'user_permission_export_upload_uploads'                   # gitlab_main_clusterwide now deprecated
    ]
  end

  let!(:starting_from_milestone) { 16.7 }

  it 'only allows exempted tables to have `gitlab_main` as its schema, after milestone 16.7', :aggregate_failures do
    tables_having_gitlab_main_schema(starting_from_milestone: starting_from_milestone).each do |table_name|
      expect(exempted_tables).to include(table_name), error_message(table_name)
    end
  end

  it 'only allows tables having `gitlab_main` as its schema in `exempted_tables`', :aggregate_failures do
    tables_having_gitlab_main_schema = gitlab_main_schema_tables.map(&:table_name)

    exempted_tables.each do |exempted_table|
      expect(tables_having_gitlab_main_schema).to include(exempted_table),
        "`#{exempted_table}` does not have `gitlab_main` as its schema.
        Please remove this table from the `exempted_tables` list."
    end
  end

  private

  def error_message(table_name)
    <<~HEREDOC
      The table `#{table_name}` has been added with `gitlab_main` schema.
      Starting from GitLab #{starting_from_milestone}, we expect new tables to use either the `gitlab_main_cell` or the
      `gitlab_main_cell_local`, or `gitlab_main_user` schema.

      To choose an appropriate schema for this table, please refer
      to our guidelines at https://docs.gitlab.com/ee/development/cells/#available-cells--organization-schemas or consult with the Tenant Scale group.
    HEREDOC
  end

  def tables_having_gitlab_main_schema(starting_from_milestone:)
    gitlab_main_schema_tables.filter_map do |entry|
      entry.table_name if entry.milestone_greater_than_or_equal_to?(starting_from_milestone)
    end
  end

  def gitlab_main_schema_tables
    ::Gitlab::Database::Dictionary.entries.find_all_by_schema('gitlab_main')
  end
end
