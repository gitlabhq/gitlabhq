# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::MigrationHelpers::RestrictGitlabSchema, :use_clean_rails_redis_caching, query_analyzers: false,
  stub_feature_flags: false, feature_category: :cell do
  let(:schema_class) { Class.new(Gitlab::Database::Migration[1.0]).include(described_class) }

  # We keep only the GitlabSchemasValidateConnection analyzer running
  around do |example|
    Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection.with_suppressed(false) do
      example.run
    end
  end

  describe '#restrict_gitlab_migration' do
    it 'invalid schema raises exception' do
      expect { schema_class.restrict_gitlab_migration gitlab_schema: :gitlab_non_existing }
        .to raise_error(/Unknown 'gitlab_schema:/)
    end

    it 'does configure allowed_gitlab_schema' do
      schema_class.restrict_gitlab_migration gitlab_schema: :gitlab_main

      expect(schema_class.allowed_gitlab_schemas).to eq(%i[gitlab_main])
    end
  end

  context 'when executing migrations' do
    using RSpec::Parameterized::TableSyntax

    where do
      {
        "does create table in gitlab_main and gitlab_ci" => {
          migration: ->(klass) do
            def change
              create_table :_test_table do |t|
                t.references :project, foreign_key: true, null: false
                t.timestamps_with_timezone null: false
              end
            end
          end,
          query_matcher: /CREATE TABLE "_test_table"/,
          expected: {
            no_gitlab_schema: {
              main: :success,
              ci: :success
            },
            gitlab_schema_gitlab_shared: {
              main: :ddl_not_allowed,
              ci: :ddl_not_allowed
            },
            gitlab_schema_gitlab_main: {
              main: :ddl_not_allowed,
              ci: :skipped
            }
          }
        },
        "does add column to projects in gitlab_main and gitlab_ci" => {
          migration: ->(klass) do
            def change
              add_column :projects, :__test_column, :integer
            end
          end,
          query_matcher: /ALTER TABLE "projects" ADD "__test_column" integer/,
          expected: {
            no_gitlab_schema: {
              main: :success,
              ci: :success
            },
            gitlab_schema_gitlab_shared: {
              main: :ddl_not_allowed,
              ci: :ddl_not_allowed
            },
            gitlab_schema_gitlab_main: {
              main: :ddl_not_allowed,
              ci: :skipped
            }
          }
        },
        "does add column to p_ci_builds in gitlab_main and gitlab_ci" => {
          migration: ->(klass) do
            def change
              add_column :p_ci_builds, :__test_column, :integer
            end
          end,
          query_matcher: /ALTER TABLE "p_ci_builds" ADD "__test_column" integer/,
          expected: {
            no_gitlab_schema: {
              main: :success,
              ci: :success
            },
            gitlab_schema_gitlab_shared: {
              main: :ddl_not_allowed,
              ci: :ddl_not_allowed
            },
            gitlab_schema_gitlab_main: {
              main: :ddl_not_allowed,
              ci: :skipped
            }
          }
        },
        "does add index to projects in gitlab_main and gitlab_ci" => {
          migration: ->(klass) do
            def change
              # Due to running in transaction we cannot use `add_concurrent_index`
              add_index :projects, :hidden
            end
          end,
          query_matcher: /CREATE INDEX/,
          expected: {
            no_gitlab_schema: {
              main: :success,
              ci: :success
            },
            gitlab_schema_gitlab_shared: {
              main: :ddl_not_allowed,
              ci: :ddl_not_allowed
            },
            gitlab_schema_gitlab_main: {
              main: :ddl_not_allowed,
              ci: :skipped
            }
          }
        },
        "does add index to ci_builds in gitlab_main and gitlab_ci" => {
          migration: ->(klass) do
            def change
              # Due to running in transaction we cannot use `add_concurrent_index`
              index_name = 'index_ci_builds_on_tag_and_type_eq_ci_build'
              add_index :ci_builds, :tag, where: "type = 'Ci::Build'", name: index_name
            end
          end,
          query_matcher: /CREATE INDEX/,
          expected: {
            no_gitlab_schema: {
              main: :success,
              ci: :success
            },
            gitlab_schema_gitlab_shared: {
              main: :ddl_not_allowed,
              ci: :ddl_not_allowed
            },
            gitlab_schema_gitlab_main: {
              main: :ddl_not_allowed,
              ci: :skipped
            }
          }
        },
        "does create trigger in gitlab_main and gitlab_ci" => {
          migration: ->(klass) do
            include Gitlab::Database::SchemaHelpers

            def up
              create_trigger_function('_test_trigger_function', replace: true) do
                <<~SQL
                  RETURN NULL;
                SQL
              end
            end

            def down
              drop_function('_test_trigger_function')
            end
          end,
          query_matcher: /CREATE OR REPLACE FUNCTION/,
          expected: {
            no_gitlab_schema: {
              main: :success,
              ci: :success
            },
            gitlab_schema_gitlab_shared: {
              main: :ddl_not_allowed,
              ci: :ddl_not_allowed
            },
            gitlab_schema_gitlab_main: {
              main: :ddl_not_allowed,
              ci: :skipped
            }
          }
        },
        "does create schema in gitlab_main and gitlab_ci" => {
          migration: ->(klass) do
            include Gitlab::Database::SchemaHelpers

            def up
              execute("create schema __test_schema")
            end

            def down; end
          end,
          query_matcher: /create schema __test_schema/,
          expected: {
            no_gitlab_schema: {
              main: :success,
              ci: :success
            },
            gitlab_schema_gitlab_shared: {
              main: :success,
              ci: :success
            },
            gitlab_schema_gitlab_main: {
              # This is not properly detected today since there are no helpers
              # available to consider this as a DDL type of change
              main: :success,
              ci: :skipped
            }
          }
        },
        "does attach loose foreign key trigger in gitlab_main and gitlab_ci" => {
          migration: ->(klass) do
            include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

            enable_lock_retries!

            def up
              track_record_deletions(:audit_events)
            end

            def down
              untrack_record_deletions(:audit_events)
            end
          end,
          query_matcher: /CREATE TRIGGER/,
          expected: {
            no_gitlab_schema: {
              main: :success,
              ci: :success
            },
            gitlab_schema_gitlab_shared: {
              main: :ddl_not_allowed,
              ci: :ddl_not_allowed
            },
            gitlab_schema_gitlab_main: {
              main: :ddl_not_allowed,
              ci: :skipped
            }
          }
        },
        "does insert into software_licenses" => {
          migration: ->(klass) do
            def up
              software_license_class.create!(name: 'aaa')
            end

            def down
              software_license_class.where(name: 'aaa').delete_all
            end

            def software_license_class
              Class.new(Gitlab::Database::Migration[2.0]::MigrationRecord) do
                self.table_name = 'software_licenses'
              end
            end
          end,
          query_matcher: /INSERT INTO "software_licenses"/,
          expected: {
            no_gitlab_schema: {
              main: :dml_not_allowed,
              ci: :dml_not_allowed
            },
            gitlab_schema_gitlab_shared: {
              main: :dml_access_denied,
              ci: :dml_access_denied
            },
            gitlab_schema_gitlab_main: {
              main: :success,
              ci: :skipped
            }
          }
        },
        "does raise exception when accessing tables outside of gitlab_main" => {
          migration: ->(klass) do
            def up
              ci_instance_variables_class.create!(variable_type: 1, key: 'aaa')
            end

            def down
              ci_instance_variables_class.delete_all
            end

            def ci_instance_variables_class
              Class.new(Gitlab::Database::Migration[2.0]::MigrationRecord) do
                self.table_name = 'ci_instance_variables'
              end
            end
          end,
          query_matcher: /INSERT INTO "ci_instance_variables"/,
          expected: {
            no_gitlab_schema: {
              main: :dml_not_allowed,
              ci: :dml_not_allowed
            },
            gitlab_schema_gitlab_shared: {
              main: :dml_access_denied,
              ci: :dml_access_denied
            },
            gitlab_schema_gitlab_main: {
              main: :dml_access_denied,
              ci: :skipped
            }
          }
        },
        "does allow modifying gitlab_shared" => {
          migration: ->(klass) do
            def up
              detached_partitions_class.create!(drop_after: Time.current, table_name: '_test_table')
            end

            def down; end

            def detached_partitions_class
              Class.new(Gitlab::Database::Migration[2.0]::MigrationRecord) do
                self.table_name = 'detached_partitions'
              end
            end
          end,
          query_matcher: /INSERT INTO "detached_partitions"/,
          expected: {
            no_gitlab_schema: {
              main: :success,
              ci: :success
            },
            gitlab_schema_gitlab_shared: {
              main: :success,
              ci: :success
            },
            gitlab_schema_gitlab_main: {
              # TBD: This allow to selectively modify shared tables in context of a specific DB only
              main: :success,
              ci: :skipped
            }
          }
        },
        "does update data in batches of gitlab_main, but skips gitlab_ci" => {
          migration: ->(klass) do
            def up
              update_column_in_batches(:projects, :archived, true) do |table, query|
                query.where(table[:archived].eq(false))
              end
            end

            def down
              # no-op
            end
          end,
          query_matcher: /FROM "projects"/,
          expected: {
            no_gitlab_schema: {
              main: :dml_not_allowed,
              ci: :dml_not_allowed
            },
            gitlab_schema_gitlab_shared: {
              main: :dml_access_denied,
              ci: :dml_access_denied
            },
            gitlab_schema_gitlab_main: {
              main: :success,
              ci: :skipped
            }
          }
        },
        "does not allow executing mixed DDL and DML migrations" => {
          migration: ->(klass) do
            def up
              execute('UPDATE projects SET hidden=false')
              add_index(:projects, :hidden, name: 'test_index')
            end

            def down
              # no-op
            end
          end,
          expected: {
            no_gitlab_schema: {
              main: :dml_not_allowed,
              ci: :dml_not_allowed
            },
            gitlab_schema_gitlab_shared: {
              main: :dml_access_denied,
              ci: :dml_access_denied
            },
            gitlab_schema_gitlab_main: {
              main: :ddl_not_allowed,
              ci: :skipped
            }
          }
        },
        "does schedule background migrations on gitlab_main" => {
          migration: ->(klass) do
            def up
              queue_background_migration_jobs_by_range_at_intervals(
                define_batchable_model('vulnerability_occurrences'),
                'RemoveDuplicateVulnerabilitiesFindings',
                2.minutes.to_i,
                batch_size: 5_000
              )
            end

            def down
              # no-op
            end
          end,
          query_matcher: /FROM "vulnerability_occurrences"/,
          expected: {
            no_gitlab_schema: {
              main: :dml_not_allowed,
              ci: :dml_not_allowed
            },
            gitlab_schema_gitlab_shared: {
              main: :runtime_error,
              ci: :runtime_error
            },
            gitlab_schema_gitlab_main: {
              main: :dml_access_denied,
              ci: :skipped
            }
          }
        },
        "does support prepare_async_index" => {
          migration: ->(klass) do
            def up
              prepare_async_index :projects, :hidden,
                name: :index_projects_on_hidden
            end

            def down
              unprepare_async_index_by_name :projects, :index_projects_on_hidden
            end
          end,
          query_matcher: /INSERT INTO "postgres_async_indexes"/,
          expected: {
            no_gitlab_schema: {
              main: :success,
              ci: :success
            },
            gitlab_schema_gitlab_shared: {
              main: :dml_not_allowed,
              ci: :dml_not_allowed
            },
            gitlab_schema_gitlab_main: {
              main: :dml_not_allowed,
              ci: :skipped
            }
          }
        },
        "does raise exception when accessing current settings" => {
          migration: ->(klass) do
            def up
              ApplicationSetting.last
            end

            def down; end
          end,
          query_matcher: /FROM "application_settings"/,
          expected: {
            no_gitlab_schema: {
              main: :dml_not_allowed,
              ci: :dml_not_allowed
            },
            gitlab_schema_gitlab_shared: {
              main: :dml_access_denied,
              ci: :dml_access_denied
            },
            gitlab_schema_gitlab_main: {
              main: :success,
              ci: :skipped
            }
          }
        },
        "does raise exception when accessing feature flags" => {
          migration: ->(klass) do
            def up
              Feature.enabled?(:redis_hll_tracking, type: :ops)
            end

            def down; end
          end,
          query_matcher: /FROM "features"/,
          expected: {
            no_gitlab_schema: {
              main: :dml_not_allowed,
              ci: :dml_not_allowed
            },
            gitlab_schema_gitlab_shared: {
              main: :dml_access_denied,
              ci: :dml_access_denied
            },
            gitlab_schema_gitlab_main: {
              main: :success,
              ci: :skipped
            }
          }
        },
        "does raise exception about cross schema access when suppressing restriction to ensure" => {
          migration: ->(klass) do
            # The purpose of this test is to ensure that we use ApplicationRecord
            # a correct connection will be used:
            # - this is a case for finalizing background migrations
            def up
              Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.with_suppressed do
                ::ApplicationRecord.connection.execute("SELECT 1 FROM ci_builds")
              end
            end

            def down; end
          end,
          query_matcher: /FROM ci_builds/,
          setup: ->(_) { skip_if_shared_database(:ci) },
          expected: {
            no_gitlab_schema: {
              main: :cross_schema_error,
              ci: :success
            },
            gitlab_schema_gitlab_shared: {
              main: :cross_schema_error,
              ci: :success
            },
            gitlab_schema_gitlab_main: {
              main: :cross_schema_error,
              ci: :skipped
            }
          }
        }
      }
    end

    with_them do
      let(:migration_class) { Class.new(schema_class, &migration) }

      Gitlab::Database.database_base_models.each do |db_config_name, model|
        context "for db_config_name=#{db_config_name}" do
          around do |example|
            verbose_was = ActiveRecord::Migration.verbose
            ActiveRecord::Migration.verbose = false

            with_reestablished_active_record_base do
              reconfigure_db_connection(model: ActiveRecord::Base, config_model: model)

              example.run
            end
          ensure
            ActiveRecord::Migration.verbose = verbose_was
          end

          before do
            allow_next_instance_of(migration_class) do |migration|
              allow(migration).to receive(:transaction_open?).and_return(false)
            end
          end

          %i[no_gitlab_schema gitlab_schema_gitlab_main gitlab_schema_gitlab_shared].each do |restrict_gitlab_migration|
            context "while restrict_gitlab_migration=#{restrict_gitlab_migration}" do
              it "does run migrate :up and :down" do
                instance_eval(&setup) if setup

                expected_result = expected.fetch(restrict_gitlab_migration)[db_config_name.to_sym]
                skip "not configured" unless expected_result

                case restrict_gitlab_migration
                when :no_gitlab_schema
                  # no-op
                when :gitlab_schema_gitlab_main
                  migration_class.restrict_gitlab_migration gitlab_schema: :gitlab_main
                when :gitlab_schema_gitlab_shared
                  migration_class.restrict_gitlab_migration gitlab_schema: :gitlab_shared
                end

                # In some cases (for :down) we ignore error and expect no other errors
                case expected_result
                when :success
                  expect { migration_class.migrate(:up) }.to make_queries_matching(query_matcher)
                  expect { migration_class.migrate(:down) }.not_to make_queries_matching(query_matcher)

                when :dml_not_allowed
                  expect { migration_class.migrate(:up) }.to raise_error(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas::DMLNotAllowedError)
                  expect { ignore_error(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas::DMLNotAllowedError) { migration_class.migrate(:down) } }.not_to raise_error

                when :dml_access_denied
                  expect { migration_class.migrate(:up) }.to raise_error(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas::DMLAccessDeniedError)
                  expect { ignore_error(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas::DMLAccessDeniedError) { migration_class.migrate(:down) } }.not_to raise_error

                when :runtime_error
                  expect { migration_class.migrate(:up) }.to raise_error(RuntimeError)
                  expect { ignore_error(RuntimeError) { migration_class.migrate(:down) } }.not_to raise_error

                when :ddl_not_allowed
                  expect { migration_class.migrate(:up) }.to raise_error(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas::DDLNotAllowedError)
                  expect { ignore_error(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas::DDLNotAllowedError) { migration_class.migrate(:down) } }.not_to raise_error

                when :cross_schema_error
                  expect { migration_class.migrate(:up) }.to raise_error(Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection::CrossSchemaAccessError)
                  expect { ignore_error(Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection::CrossSchemaAccessError) { migration_class.migrate(:down) } }.not_to raise_error

                when :skipped
                  expect_next_instance_of(migration_class) do |migration_object|
                    expect(migration_object).to receive(:migration_skipped).and_call_original
                    expect(migration_object).not_to receive(:up)
                    expect(migration_object).not_to receive(:down)
                    expect(migration_object).not_to receive(:change)
                  end

                  migration_class.migrate(:up)
                  migration_class.migrate(:down)
                end
              end
            end
          end

          def ignore_error(error)
            yield
          rescue error
          end
        end
      end
    end
  end
end
