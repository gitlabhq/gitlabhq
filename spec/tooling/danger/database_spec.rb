# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/database'

RSpec.describe Tooling::Danger::Database, feature_category: :tooling do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:migration_files) do
    [
      # regular migrations
      'db/migrate/20220901010203_add_widgets_table.rb',
      'db/migrate/20220909010203_add_properties_column.rb',
      'db/migrate/20220910010203_drop_tools_table.rb',
      'db/migrate/20220912010203_add_index_to_widgets_table.rb',

      # post migrations
      'db/post_migrate/20220901010203_add_widgets_table.rb',
      'db/post_migrate/20220909010203_add_properties_column.rb',
      'db/post_migrate/20220910010203_drop_tools_table.rb',
      'db/post_migrate/20220912010203_add_index_to_widgets_table.rb',

      # ee migrations
      'ee/db/migrate/20220901010203_add_widgets_table.rb',
      'ee/db/migrate/20220909010203_add_properties_column.rb',
      'ee/db/migrate/20220910010203_drop_tools_table.rb',
      'ee/db/migrate/20220912010203_add_index_to_widgets_table.rb',

      # geo migrations
      'ee/db/geo/migrate/20220901010203_add_widgets_table.rb',
      'ee/db/geo/migrate/20220909010203_add_properties_column.rb',
      'ee/db/geo/migrate/20220910010203_drop_tools_table.rb',
      'ee/db/geo/migrate/20220912010203_add_index_to_widgets_table.rb'
    ]
  end

  let(:cutoff) { Date.parse('2022-10-01') - 21 }

  subject(:database) { fake_danger.new(helper: fake_helper) }

  describe '#find_migration_files_before' do
    it 'returns migrations that are before the cutoff' do
      expect(database.find_migration_files_before(migration_files, cutoff).length).to eq(8)
    end
  end

  describe '#changes' do
    using RSpec::Parameterized::TableSyntax

    where do
      {
        'with database changes to a migration file' => {
          modified_files: %w[
            db/migrate/20230720114001_test_migration.rb
            db/schema_migrations/20230720114001
            db/structure.sql
            app/models/test.rb
          ],
          changed_lines: [],
          changes_by_category: {
            database: %w[
              db/migrate/20230720114001_test_migration.rb
              db/schema_migrations/20230720114001
              db/structure.sql
            ]
          },
          impacted_files: %w[
            db/migrate/20230720114001_test_migration.rb
            db/schema_migrations/20230720114001
            db/structure.sql
          ]
        },
        'with non-database changes' => {
          modified_files: %w[
            app/models/test.rb
          ],
          changed_lines: %w[
            +# Comment explaining scope :blah
          ],
          changes_by_category: {
            database: []
          },
          impacted_files: []
        },
        'with database changes in a doc' => {
          modified_files: %w[doc/development/database/test.md],
          changed_lines: [
            '+scope :blah, ->() { where(hidden: false) }'
          ],
          changes_by_category: {
            database: []
          },
          impacted_files: []
        },
        'with database changes in a model' => {
          modified_files: %w[app/models/test.rb],
          changed_lines: [
            '+# Comment explaining scope :blah',
            '+scope :blah, ->() { where(hidden: false) }'
          ],
          changes_by_category: {
            database: []
          },
          impacted_files: %w[app/models/test.rb]
        },
        'with database changes in a concern' => {
          modified_files: %w[app/models/concerns/test.rb],
          changed_lines: [
            '-  .where(hidden: false)',
            '+  .where(hidden: true)'
          ],
          changes_by_category: {
            database: []
          },
          impacted_files: %w[app/models/concerns/test.rb]
        }
      }
    end

    with_them do
      before do
        allow(fake_helper).to receive(:modified_files).and_return(modified_files)
        allow(fake_helper).to receive(:all_changed_files).and_return(modified_files)
        allow(fake_helper).to receive(:changed_lines).and_return(changed_lines)
        allow(fake_helper).to receive(:changes_by_category).and_return(changes_by_category)
      end

      it 'returns database changes' do
        expect(database.changes).to match impacted_files
      end
    end
  end

  describe '#check_migration_type_on_stable_branch' do
    subject(:check_migration_type) do
      database.check_migration_type_on_stable_branch(file_names)
    end

    context 'when no migrations are added' do
      let(:file_names) { ['app/models/user.rb', 'lib/utils.rb'] }

      it 'does not warn' do
        expect(database).not_to receive(:warn)
        check_migration_type
      end
    end

    context 'when migrations are added' do
      let(:file_names) do
        [
          'db/migrate/20250128120000_add_column_to_users.rb',
          'app/models/user.rb'
        ]
      end

      it 'warns about migration type' do
        expect(database).to receive(:warn)
          .with(described_class::MIGRATION_TYPE_WARNING_MESSAGE)
        check_migration_type
      end
    end

    context 'when post migrations are added' do
      let(:file_names) do
        [
          'db/post_migrate/20250128120000_remove_column_from_users.rb',
          'app/models/user.rb'
        ]
      end

      it 'warns about migration type' do
        expect(database).to receive(:warn)
          .with(described_class::MIGRATION_TYPE_WARNING_MESSAGE)
        check_migration_type
      end
    end

    context 'when geo migrations are added' do
      let(:file_names) do
        [
          'ee/db/geo/migrate/20250128120000_add_column_to_geo_table.rb',
          'app/models/user.rb'
        ]
      end

      it 'warns about migration type' do
        expect(database).to receive(:warn)
          .with(described_class::MIGRATION_TYPE_WARNING_MESSAGE)
        check_migration_type
      end
    end

    context 'when geo post migrations are added' do
      let(:file_names) do
        [
          'ee/db/geo/post_migrate/20250128120000_remove_column_from_geo_table.rb',
          'app/models/user.rb'
        ]
      end

      it 'warns about migration type' do
        expect(database).to receive(:warn)
          .with(described_class::MIGRATION_TYPE_WARNING_MESSAGE)
        check_migration_type
      end
    end
  end
end
