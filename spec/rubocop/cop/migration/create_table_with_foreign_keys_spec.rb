# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/create_table_with_foreign_keys'

RSpec.describe RuboCop::Cop::Migration::CreateTableWithForeignKeys do
  context 'outside of a migration' do
    it 'does not register any offenses' do
      expect_no_offenses(<<~RUBY)
        def up
          create_table(:foo) do |t|
            t.references :bar, foreign_key: { on_delete: 'cascade' }
            t.references :zoo, foreign_key: { on_delete: 'cascade' }
          end
        end
      RUBY
    end
  end

  context 'when in a migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    context 'without foreign key' do
      it 'does not register any offenses' do
        expect_no_offenses(<<~RUBY)
          def up
            create_table(:foo) do |t|
              t.references :bar
            end
          end
        RUBY
      end
    end

    context 'with foreign key' do
      context 'with just one foreign key' do
        context 'when the foreign_key targets a high traffic table' do
          context 'when the foreign_key has to_table option set' do
            it 'does not register any offenses' do
              expect_no_offenses(<<~RUBY)
                def up
                  create_table(:foo) do |t|
                    t.references :project, "foreign_key" => { on_delete: 'cascade', to_table: 'projects' }
                  end
                end
              RUBY
            end
          end

          context 'when the foreign_key does not have to_table option set' do
            it 'does not register any offenses' do
              expect_no_offenses(<<~RUBY)
                def up
                  create_table(:foo) do |t|
                    t.references :project, foreign_key: { on_delete: 'cascade' }
                  end
                end
              RUBY
            end
          end
        end

        context 'when the foreign_key does not target a high traffic table' do
          it 'does not register any offenses' do
            expect_no_offenses(<<~RUBY)
              def up
                create_table(:foo) do |t|
                  t.references :bar, foreign_key: { on_delete: 'cascade' }
                end
              end
            RUBY
          end
        end
      end

      context 'with more than one foreign keys' do
        let(:offense) do
          'Creating a table with more than one foreign key at once violates our migration style guide. ' \
          'For more details check the https://docs.gitlab.com/ee/development/migration_style_guide.html#creating-a-new-table-when-we-have-two-foreign-keys'
        end

        shared_examples 'target to high traffic table' do |dsl_method, table_name|
          context 'when the target is defined as option' do
            it 'registers an offense' do
              expect_offense(<<~RUBY)
                def up
                  create_table(:foo) do |t|
                  ^^^^^^^^^^^^^^^^^^ #{offense}
                    t.#{dsl_method} :#{table_name.singularize} #{explicit_target_opts}
                    t.#{dsl_method} :zoo #{implicit_target_opts}
                  end
                end
              RUBY
            end
          end

          context 'when the target has implicit definition' do
            it 'registers an offense' do
              expect_offense(<<~RUBY)
                def up
                  create_table(:foo) do |t|
                  ^^^^^^^^^^^^^^^^^^ #{offense}
                    t.#{dsl_method} :#{table_name.singularize} #{implicit_target_opts}
                    t.#{dsl_method} :zoo #{implicit_target_opts}
                  end
                end
              RUBY
            end
          end
        end

        shared_context 'when there is a target to a high traffic table' do |dsl_method|
          %w[
            audit_events
            ci_builds
            ci_builds_metadata
            ci_job_artifacts
            ci_pipeline_variables
            ci_pipelines
            ci_stages
            deployments
            events
            gitlab_subscriptions
            issues
            merge_request_diff_commits
            merge_request_diff_files
            merge_request_diffs
            merge_request_metrics
            merge_requests
            namespaces
            note_diff_files
            notes
            project_authorizations
            projects
            project_ci_cd_settings
            project_features
            push_event_payloads
            resource_label_events
            routes
            sent_notifications
            system_note_metadata
            taggings
            todos
            users
            web_hook_logs
          ].each do |table|
            context "with #{table}" do
              let(:table_name) { table }

              it_behaves_like 'target to high traffic table', dsl_method, table
            end
          end
        end

        context 'when the foreign keys are defined as options' do
          context 'when there is no target to a high traffic table' do
            it 'does not register any offenses' do
              expect_no_offenses(<<~RUBY)
                def up
                  create_table(:foo) do |t|
                    t.references :bar, foreign_key: { on_delete: 'cascade', to_table: :bars }
                    t.references :zoo, 'foreign_key' => { on_delete: 'cascade' }
                    t.references :john, 'foreign_key' => { on_delete: 'cascade' }
                    t.references :doe, 'foreign_key' => { on_delete: 'cascade', to_table: 'doe' }
                  end
                end
              RUBY
            end
          end

          include_context 'when there is a target to a high traffic table', :references do
            let(:explicit_target_opts) { ", foreign_key: { to_table: :#{table_name} }" }
            let(:implicit_target_opts) { ", foreign_key: true" }
          end
        end

        context 'when the foreign keys are defined by standlone migration helper' do
          context 'when there is no target to a high traffic table' do
            it 'does not register any offenses' do
              expect_no_offenses(<<~RUBY)
                def up
                  create_table(:foo) do |t|
                    t.foreign_key :bar
                    t.foreign_key :zoo, to_table: 'zoos'
                  end
                end
              RUBY
            end
          end

          include_context 'when there is a target to a high traffic table', :foreign_key do
            let(:explicit_target_opts) { ", to_table: :#{table_name}" }
            let(:implicit_target_opts) {}
          end
        end
      end
    end
  end
end
