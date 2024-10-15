# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'cross-database foreign keys' do
  # While we are building out Cells, we will be moving tables from gitlab_main schema
  # to either gitlab_main_clusterwide schema or gitlab_main_cell schema.
  # During this transition phase, cross database foreign keys need
  # to be temporarily allowed to exist, until we can work on converting these columns to loose foreign keys.
  # The issue corresponding to the loose foreign key conversion
  # should be added as a comment along with the name of the column.

  # The Sec database decomposition additionally requires the ability to temporarily permit cross database
  # foreign keys.
  let!(:allowed_cross_database_foreign_keys) do
    [
      'gitlab_subscriptions.hosted_plan_id',                     # https://gitlab.com/gitlab-org/gitlab/-/issues/422012
      'group_import_states.user_id',                             # https://gitlab.com/gitlab-org/gitlab/-/issues/421210
      'identities.saml_provider_id',                             # https://gitlab.com/gitlab-org/gitlab/-/issues/422010
      'issues.author_id',                                        # https://gitlab.com/gitlab-org/gitlab/-/issues/422154
      'issues.closed_by_id',                                     # https://gitlab.com/gitlab-org/gitlab/-/issues/422154
      'issues.updated_by_id',                                    # https://gitlab.com/gitlab-org/gitlab/-/issues/422154
      'issue_assignees.user_id',                                 # https://gitlab.com/gitlab-org/gitlab/-/issues/422154
      'lfs_file_locks.user_id',                                  # https://gitlab.com/gitlab-org/gitlab/-/issues/430838
      'merge_requests.assignee_id',                              # https://gitlab.com/gitlab-org/gitlab/-/issues/422080
      'merge_requests.updated_by_id',                            # https://gitlab.com/gitlab-org/gitlab/-/issues/422080
      'merge_requests.merge_user_id',                            # https://gitlab.com/gitlab-org/gitlab/-/issues/422080
      'merge_requests.author_id',                                # https://gitlab.com/gitlab-org/gitlab/-/issues/422080
      'namespace_commit_emails.email_id',                        # https://gitlab.com/gitlab-org/gitlab/-/issues/429804
      'namespace_commit_emails.user_id',                         # https://gitlab.com/gitlab-org/gitlab/-/issues/429804
      'path_locks.user_id',                                      # https://gitlab.com/gitlab-org/gitlab/-/issues/429380
      'protected_branch_push_access_levels.user_id',             # https://gitlab.com/gitlab-org/gitlab/-/issues/431054
      'protected_branch_merge_access_levels.user_id',            # https://gitlab.com/gitlab-org/gitlab/-/issues/431055
      'user_group_callouts.user_id',                             # https://gitlab.com/gitlab-org/gitlab/-/issues/421287
      'subscription_user_add_on_assignments.user_id',            # https://gitlab.com/gitlab-org/gitlab/-/issues/444666
      'subscription_add_on_purchases.subscription_add_on_id'     # https://gitlab.com/gitlab-org/gitlab/-/issues/444666
    ]
  end

  def foreign_keys_for(table_name)
    ApplicationRecord.connection.foreign_keys(table_name)
  end

  def is_cross_db?(fk_record)
    tables = [fk_record.from_table, fk_record.to_table]

    table_schemas = Gitlab::Database::GitlabSchema.table_schemas!(tables)

    !Gitlab::Database::GitlabSchema.cross_foreign_key_allowed?(table_schemas, tables)
  end

  it 'onlies have allowed list of cross-database foreign keys', :aggregate_failures do
    all_tables = ApplicationRecord.connection.data_sources

    all_tables.each do |table|
      foreign_keys_for(table).each do |fk|
        if is_cross_db?(fk)
          column = "#{fk.from_table}.#{fk.column}"
          expect(allowed_cross_database_foreign_keys).to include(column), "Found extra cross-database foreign key #{column} referencing #{fk.to_table} with constraint name #{fk.name}. When a foreign key references another database you must use a Loose Foreign Key instead https://docs.gitlab.com/ee/development/database/loose_foreign_keys.html ."
        end
      end
    end
  end

  it 'only allows existing foreign keys to be present in the exempted list', :aggregate_failures do
    allowed_cross_database_foreign_keys.each do |entry|
      table, _ = entry.split('.')

      all_foreign_keys_for_table = foreign_keys_for(table)
      fk_entry = all_foreign_keys_for_table.find { |fk| "#{fk.from_table}.#{fk.column}" == entry }

      expect(fk_entry).to be_present,
        "`#{entry}` is no longer a foreign key. " \
        "You must remove this entry from the `allowed_cross_database_foreign_keys` list."
    end
  end
end
