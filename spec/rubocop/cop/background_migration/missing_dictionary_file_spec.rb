# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/background_migration/missing_dictionary_file'

RSpec.describe RuboCop::Cop::BackgroundMigration::MissingDictionaryFile, feature_category: :database do
  let(:config) do
    RuboCop::Config.new(
      'BackgroundMigration/MissingDictionaryFile' => {
        'EnforcedSince' => 20230307160251
      }
    )
  end

  context 'for non post migrations' do
    before do
      allow(cop).to receive(:in_post_deployment_migration?).and_return(false)
    end

    it 'does not throw any offense' do
      expect_no_offenses(<<~RUBY)
        class QueueMyMigration < Gitlab::Database::Migration[2.1]
          MIGRATION = 'MyMigration'

          def up
            queue_batched_background_migration(
              MIGRATION,
              :users,
              :id
            )
          end
        end
      RUBY
    end
  end

  context 'for post migrations' do
    before do
      allow(cop).to receive(:in_post_deployment_migration?).and_return(true)
    end

    context 'without enqueuing batched migrations' do
      it 'does not throw any offense' do
        expect_no_offenses(<<~RUBY)
          class CreateTestTable < Gitlab::Database::Migration[2.1]
            def change
              create_table(:tests)
            end
          end
        RUBY
      end
    end

    context 'with enqueuing batched migration' do
      let(:rails_root) { File.expand_path('../../../..', __dir__) }
      let(:dictionary_file_path) { File.join(rails_root, 'db/docs/batched_background_migrations/my_migration.yml') }

      context 'for migrations before enforced time' do
        before do
          allow(cop).to receive(:version).and_return(20230307160250)
        end

        it 'does not throw any offenses' do
          expect_no_offenses(<<~RUBY)
            class QueueMyMigration < Gitlab::Database::Migration[2.1]
              MIGRATION = 'MyMigration'

              def up
                queue_batched_background_migration(
                  MIGRATION,
                  :users,
                  :id
                )
              end
            end
          RUBY
        end
      end

      context 'for migrations after enforced time' do
        before do
          allow(cop).to receive(:version).and_return(20230307160252)
        end

        it 'throws offense on not having the appropriate dictionary file with migration name as a constant' do
          expect_offense(<<~RUBY)
            class QueueMyMigration < Gitlab::Database::Migration[2.1]
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format("Missing %{file_name}. Use the generator 'batched_background_migration' to create dictionary files automatically. For more details refer: https://docs.gitlab.com/ee/development/database/batched_background_migrations.html#generator", file_name: dictionary_file_path)}
              MIGRATION = 'MyMigration'

              def up
                queue_batched_background_migration(
                  MIGRATION,
                  :users,
                  :id
                )
              end
            end
          RUBY
        end

        it 'throws offense on not having the appropriate dictionary file with migration name as a variable' do
          expect_offense(<<~RUBY)
            class QueueMyMigration < Gitlab::Database::Migration[2.1]
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format("Missing %{file_name}. Use the generator 'batched_background_migration' to create dictionary files automatically. For more details refer: https://docs.gitlab.com/ee/development/database/batched_background_migrations.html#generator", file_name: dictionary_file_path)}
              def up
                queue_batched_background_migration(
                  'MyMigration',
                  :users,
                  :id
                )
              end
            end
          RUBY
        end

        it 'does not throw offense with appropriate dictionary file' do
          expect(File).to receive(:exist?).with(dictionary_file_path).and_return(true)

          expect_no_offenses(<<~RUBY)
            class QueueMyMigration < Gitlab::Database::Migration[2.1]
              MIGRATION = 'MyMigration'

              def up
                queue_batched_background_migration(
                  MIGRATION,
                  :users,
                  :id
                )
              end
            end
          RUBY
        end
      end
    end
  end
end
