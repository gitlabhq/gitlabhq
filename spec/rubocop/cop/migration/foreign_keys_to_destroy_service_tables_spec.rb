# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/foreign_keys_to_destroy_service_tables'

RSpec.describe RuboCop::Cop::Migration::ForeignKeysToDestroyServiceTables, feature_category: :database do
  let(:projects_offense) { offense_for('projects', 'Projects::DestroyService') }
  let(:namespaces_offense) { offense_for('namespaces', 'Groups::DestroyService') }

  def offense_for(table, service)
    "Records of the `#{table}` table are deleted through #{service}, so the destroy service " \
      "must be updated to handle these new dependent records. The ON DELETE CASCADE on this " \
      "foreign key is only a backstop for a self-managed admin who manually deletes a `#{table}` " \
      "row from the database. Once #{service} handles the cleanup, disable this cop on this line " \
      "with a comment stating where it's handled."
  end

  before do
    allow(cop).to receive(:time_enforced?).and_return(true)
  end

  describe '.destroy_service_tables' do
    subject(:tables) { described_class.destroy_service_tables }

    it 'maps tables to their destroy service classes' do
      expect(tables).to include(
        'projects' => ['Projects::DestroyService'],
        'namespaces' => ['Groups::DestroyService'],
        'users' => ['Users::DestroyService'],
        'deployments' => ['Ci::Deployments::DestroyService']
      )
    end

    it 'keeps every destroy service for tables with multiple owners' do
      expect(tables['deploy_tokens']).to contain_exactly(
        'Groups::DeployTokens::DestroyService', 'Projects::DeployTokens::DestroyService'
      )
      expect(tables['webauthn_registrations']).to contain_exactly(
        'Authn::Passkey::DestroyService', 'TwoFactor::DestroyService', 'Webauthn::DestroyService'
      )
    end

    # Fixture services must be CE-owned so this also passes on FOSS pipelines.
    it 'maps tables owned through the delete_service convention' do
      expect(tables['pages_domains']).to eq(['Pages::Domains::DeleteService'])
      expect(tables['timelogs']).to eq(['Timelogs::DeleteService'])
    end

    it 'excludes destroy services that do not own a table' do
      expect(tables).not_to have_key('tags')
    end

    it 'only contains tables documented in db/docs' do
      expect(tables.keys).to all(satisfy { |table| File.exist?("db/docs/#{table}.yml") })
    end

    it 'includes tables guarded by non-conventional deletion services' do
      expect(tables['organizations']).to eq(['Organizations::HardDeleteService'])
      expect(tables['merge_requests']).to eq(['Issuable::DestroyService'])
      expect(tables['ml_models']).to eq(['Ml::DestroyModelService'])
    end

    it 'accounts for every destroy service namespace' do
      unaccounted = Gitlab::Database::TablesWithDestroyServices.unaccounted_namespaces

      expect(unaccounted).to be_empty,
        "These destroy-service namespaces neither map to a table documented in db/docs nor are " \
          "explicitly excluded: #{unaccounted.join(', ')}. Add a TABLE_OVERRIDES entry pointing at " \
          "the table the service deletes from, or add the namespace to EXCLUDED_NAMESPACES in " \
          "lib/gitlab/database/tables_with_destroy_services.rb with a reason."
    end
  end

  context 'when adding a standalone foreign key to a destroy-service table' do
    it 'registers an offense for add_concurrent_foreign_key' do
      expect_offense(<<~RUBY)
        def up
          add_concurrent_foreign_key :widgets, :projects, column: :project_id
          ^^^^^^^^^^^^^^^^^^^^^^^^^^ #{projects_offense}
        end
      RUBY
    end

    it 'registers an offense for add_foreign_key' do
      expect_offense(<<~RUBY)
        def up
          add_foreign_key :widgets, :projects, column: :project_id
          ^^^^^^^^^^^^^^^ #{projects_offense}
        end
      RUBY
    end

    it 'registers an offense for add_concurrent_partitioned_foreign_key' do
      expect_offense(<<~RUBY)
        def up
          add_concurrent_partitioned_foreign_key :widgets, :projects, column: :project_id
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{projects_offense}
        end
      RUBY
    end

    it 'registers an offense when the table name is a string' do
      expect_offense(<<~RUBY)
        def up
          add_concurrent_foreign_key :widgets, 'projects', column: :project_id
          ^^^^^^^^^^^^^^^^^^^^^^^^^^ #{projects_offense}
        end
      RUBY
    end

    it 'registers an offense for tables guarded by non-conventional deletion services' do
      expect_offense(<<~RUBY)
        def up
          add_concurrent_foreign_key :widgets, :organizations, column: :organization_id
          ^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense_for('organizations', 'Organizations::HardDeleteService')}
        end
      RUBY
    end
  end

  context 'when adding references inside create_table' do
    it 'registers an offense for a pluralized reference with a foreign key' do
      expect_offense(<<~RUBY)
        def change
          create_table :widgets do |t|
            t.references :project, foreign_key: { on_delete: :cascade }
              ^^^^^^^^^^ #{projects_offense}
          end
        end
      RUBY
    end

    it 'registers an offense when the target comes from to_table' do
      expect_offense(<<~RUBY)
        def change
          create_table :widgets do |t|
            t.references :group, foreign_key: { to_table: :namespaces, on_delete: :cascade }
              ^^^^^^^^^^ #{namespaces_offense}
          end
        end
      RUBY
    end

    # Fixture tables must have CE-owned destroy services so the examples also
    # pass on FOSS pipelines, where ee/app/services does not exist.
    it 'registers an offense for references with an irregular -y plural' do
      expect_offense(<<~RUBY)
        def change
          create_table :widgets do |t|
            t.references :container_repository, foreign_key: { on_delete: :cascade }
              ^^^^^^^^^^ #{offense_for('container_repositories', 'Projects::ContainerRepository::DestroyService')}
          end
        end
      RUBY
    end

    it 'registers an offense for references with a -ch plural' do
      expect_offense(<<~RUBY)
        def change
          create_table :widgets do |t|
            t.references :protected_branch, foreign_key: { on_delete: :cascade }
              ^^^^^^^^^^ #{offense_for('protected_branches', 'ProtectedBranches::DestroyService')}
          end
        end
      RUBY
    end

    it 'registers an offense for belongs_to with foreign_key: true' do
      expect_offense(<<~RUBY)
        def change
          create_table :widgets do |t|
            t.belongs_to :project, foreign_key: true
              ^^^^^^^^^^ #{projects_offense}
          end
        end
      RUBY
    end

    it 'registers an offense for t.foreign_key' do
      expect_offense(<<~RUBY)
        def change
          create_table :widgets do |t|
            t.foreign_key :projects, column: :project_id
              ^^^^^^^^^^^ #{projects_offense}
          end
        end
      RUBY
    end

    it 'does not register an offense for a reference without a foreign key' do
      expect_no_offenses(<<~RUBY)
        def change
          create_table :widgets do |t|
            t.references :project, index: true
          end
        end
      RUBY
    end
  end

  context 'when using add_reference' do
    it 'registers an offense when a foreign key is requested' do
      expect_offense(<<~RUBY)
        def up
          add_reference :widgets, :project, foreign_key: { on_delete: :cascade }
          ^^^^^^^^^^^^^ #{projects_offense}
        end
      RUBY
    end

    it 'does not register an offense without a foreign key' do
      expect_no_offenses(<<~RUBY)
        def up
          add_reference :widgets, :project, index: true
        end
      RUBY
    end
  end

  context 'when the target table is referenced through a constant' do
    it 'registers an offense when the constant resolves to a destroy-service table' do
      expect_offense(<<~RUBY)
        TARGET_TABLE = :projects

        def up
          add_concurrent_foreign_key :widgets, TARGET_TABLE, column: :project_id
          ^^^^^^^^^^^^^^^^^^^^^^^^^^ #{projects_offense}
        end
      RUBY
    end

    it 'registers an offense when the constant is defined after its use' do
      expect_offense(<<~RUBY)
        def up
          add_concurrent_foreign_key :widgets, TARGET_TABLE, column: :project_id
          ^^^^^^^^^^^^^^^^^^^^^^^^^^ #{projects_offense}
        end

        TARGET_TABLE = 'projects'
      RUBY
    end

    it 'registers an offense when to_table is a constant' do
      expect_offense(<<~RUBY)
        TARGET_TABLE = :namespaces

        def change
          create_table :widgets do |t|
            t.references :group, foreign_key: { to_table: TARGET_TABLE, on_delete: :cascade }
              ^^^^^^^^^^ #{namespaces_offense}
          end
        end
      RUBY
    end

    it 'does not register an offense when the constant resolves to an unguarded table' do
      expect_no_offenses(<<~RUBY)
        TARGET_TABLE = :merge_request_diffs

        def up
          add_concurrent_foreign_key :widgets, TARGET_TABLE, column: :merge_request_diff_id
        end
      RUBY
    end

    it 'does not register an offense for a constant it cannot resolve' do
      expect_no_offenses(<<~RUBY)
        def up
          add_concurrent_foreign_key :widgets, SomeModule::TARGET_TABLE, column: :project_id
        end
      RUBY
    end
  end

  context 'when the foreign key column is the declared sharding key' do
    it 'does not register an offense for a sharding_key column' do
      expect_no_offenses(<<~RUBY)
        def up
          add_concurrent_foreign_key :merge_request_reviewers, :projects, column: :project_id
        end
      RUBY
    end

    it 'does not register an offense for a desired_sharding_key column' do
      expect_no_offenses(<<~RUBY)
        def up
          add_concurrent_foreign_key :merge_request_diff_commits, :projects, column: :project_id
        end
      RUBY
    end

    it 'does not register an offense when the column is implied by the target table' do
      expect_no_offenses(<<~RUBY)
        def up
          add_foreign_key :merge_request_reviewers, :projects
        end
      RUBY
    end

    it 'does not register an offense for a sharding-key reference in a table block' do
      expect_no_offenses(<<~RUBY)
        def change
          change_table :merge_request_reviewers do |t|
            t.references :project, foreign_key: { on_delete: :cascade }
          end
        end
      RUBY
    end

    it 'registers an offense for a non-sharding-key column on the same table' do
      expect_offense(<<~RUBY)
        def up
          add_concurrent_foreign_key :merge_request_reviewers, :users, column: :user_id
          ^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense_for('users', 'Users::DestroyService')}
        end
      RUBY
    end
  end

  context 'when foreign keys are defined through an array of hashes' do
    it 'registers an offense for each entry targeting a destroy-service table' do
      expect_offense(<<~RUBY)
        FOREIGN_KEYS = [
          { source_table: :widgets, target_table: :projects, column: :project_id },
          { source_table: :widgets, target_table: :merge_request_diffs, column: :merge_request_diff_id }
        ]

        def up
          FOREIGN_KEYS.each do |fk|
            add_concurrent_foreign_key(fk[:source_table], fk[:target_table], column: fk[:column])
            ^^^^^^^^^^^^^^^^^^^^^^^^^^ #{projects_offense}
          end
        end
      RUBY
    end

    it 'does not register an offense when the column is the declared sharding key' do
      expect_no_offenses(<<~RUBY)
        FOREIGN_KEYS = [
          { source_table: :merge_request_reviewers, target_table: :projects, column: :project_id }
        ]

        def up
          FOREIGN_KEYS.each do |fk|
            add_concurrent_foreign_key(fk[:source_table], fk[:target_table], column: fk[:column])
          end
        end
      RUBY
    end

    it 'does not register an offense when the constant cannot be resolved' do
      expect_no_offenses(<<~RUBY)
        def up
          SomeModule::FOREIGN_KEYS.each do |fk|
            add_concurrent_foreign_key(fk[:source_table], fk[:target_table], column: fk[:column])
          end
        end
      RUBY
    end
  end

  context 'when the constrained table was renamed or dropped after the migration ran' do
    it 'does not register an offense for tables documented in db/docs/deleted_tables' do
      expect_no_offenses(<<~RUBY)
        def up
          add_concurrent_foreign_key :abuse_trust_scores, :projects, column: :project_id
        end
      RUBY
    end
  end

  context 'when the referenced table has no destroy service' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        def up
          add_concurrent_foreign_key :widgets, :merge_request_diffs, column: :merge_request_diff_id
        end
      RUBY
    end
  end

  context 'when rolling back a migration' do
    it 'does not register an offense in the down method' do
      expect_no_offenses(<<~RUBY)
        def down
          add_concurrent_foreign_key :widgets, :projects, column: :project_id
        end
      RUBY
    end
  end

  context 'when the migration is older than the enforced version' do
    before do
      allow(cop).to receive(:time_enforced?).and_return(false)
    end

    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        def up
          add_concurrent_foreign_key :widgets, :projects, column: :project_id
        end
      RUBY
    end
  end
end
