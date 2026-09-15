# frozen_string_literal: true

require 'fast_spec_helper'
require './keeps/overdue_finalize_background_migrations/migration_rewriter'

RSpec.describe Keeps::OverdueFinalizeBackgroundMigrations::MigrationRewriter, feature_category: :tooling do
  subject(:rewriter) { described_class.new }

  let(:migration_record) do
    Struct.new(:id, :finished_at, :updated_at, :gitlab_schema)
      .new(id: 1, finished_at: '2023-01-01', updated_at: '2023-01-01', gitlab_schema: 'gitlab_main')
  end

  describe '#find_queue_method_node' do
    let(:tmp_dir) { Pathname(Dir.mktmpdir) }
    let(:migration_file) { tmp_dir.join('queue_migration.rb').to_s }

    after do
      FileUtils.rm_rf(tmp_dir)
    end

    it 'returns the queue_batched_background_migration send node' do
      File.write(migration_file, <<~RUBY)
        class QueueTestMigration < Gitlab::Database::Migration[2.2]
          MIGRATION = 'TestMigration'

          def up
            queue_batched_background_migration(
              MIGRATION,
              :users,
              :id,
              job_interval: 2.minutes
            )
          end

          def down; end
        end
      RUBY

      node = rewriter.find_queue_method_node(migration_file)

      expect(node).to be_a(RuboCop::AST::SendNode)
      expect(node.method_name).to eq(:queue_batched_background_migration)
    end
  end

  describe '#add_ensure_call_to_migration' do
    let(:tmp_dir) { Pathname(Dir.mktmpdir) }
    let(:migration_file) { tmp_dir.join('finalize_migration.rb').to_s }
    let(:queue_migration_file) { tmp_dir.join('queue_migration.rb').to_s }

    after do
      FileUtils.rm_rf(tmp_dir)
    end

    before do
      File.write(migration_file, <<~RUBY)
        # frozen_string_literal: true
        class FinalizeHKTestMigration < Gitlab::Database::Migration[2.2]
          def up
            # placeholder
          end

          def down; end
        end
      RUBY
    end

    def rewrite(queue_source)
      File.write(queue_migration_file, queue_source)
      queue_node = rewriter.find_queue_method_node(queue_migration_file)
      rewriter.add_ensure_call_to_migration(migration_file, queue_node, 'TestMigration', migration_record)
      File.read(migration_file)
    end

    it 'replaces the up method with ensure_batched_background_migration_is_finished call' do
      content = rewrite(<<~RUBY)
        class QueueTestMigration < Gitlab::Database::Migration[2.2]
          MIGRATION = 'TestMigration'

          def up
            queue_batched_background_migration(
              MIGRATION,
              :users,
              :id,
              job_interval: 2.minutes
            )
          end

          def down; end
        end
      RUBY

      expect(content).to include('ensure_batched_background_migration_is_finished')
      expect(content).to include("job_class_name: 'TestMigration'")
      expect(content).to include('table_name: :users')
      expect(content).to include('column_name: :id')
      expect(content).to include('disable_ddl_transaction!')
      expect(content).to include('restrict_gitlab_migration gitlab_schema: :gitlab_main')
    end

    it 'includes job_arguments when present in the queue call' do
      content = rewrite(<<~RUBY)
        class QueueTestMigration < Gitlab::Database::Migration[2.2]
          MIGRATION = 'TestMigration'

          def up
            queue_batched_background_migration(
              MIGRATION,
              :users,
              :id,
              :email,
              job_interval: 2.minutes
            )
          end

          def down; end
        end
      RUBY

      expect(content).to include('job_arguments: [:email]')
    end

    it 'resolves constants referenced in the queue call to their literal values' do
      content = rewrite(<<~RUBY)
        class QueueTestMigration < Gitlab::Database::Migration[2.2]
          MIGRATION = 'TestMigration'
          OLD_PERMISSION = 'write_work_item'
          NEW_PERMISSIONS = %w[create_work_item update_work_item]

          def up
            queue_batched_background_migration(
              MIGRATION,
              :granular_scopes,
              :id,
              OLD_PERMISSION,
              NEW_PERMISSIONS,
              job_interval: 2.minutes
            )
          end

          def down; end
        end
      RUBY

      expect(content).to include('table_name: :granular_scopes')
      expect(content).to include('column_name: :id')
      expect(content).to include("job_arguments: ['write_work_item', %w[create_work_item update_work_item]]")
    end

    it 'resolves constants nested inside composite argument expressions' do
      content = rewrite(<<~RUBY)
        class QueueTestMigration < Gitlab::Database::Migration[2.2]
          MIGRATION = 'TestMigration'
          OLD_PERMISSION = 'write_work_item'
          NEW_PERMISSION = 'create_work_item'

          def up
            queue_batched_background_migration(
              MIGRATION,
              :granular_scopes,
              :id,
              [OLD_PERMISSION, NEW_PERMISSION],
              job_interval: 2.minutes
            )
          end

          def down; end
        end
      RUBY

      expect(content).to include("job_arguments: [['write_work_item', 'create_work_item']]")
    end

    it 'does not rewrite namespaced constants that share a bare name with a local constant' do
      content = rewrite(<<~RUBY)
        class QueueTestMigration < Gitlab::Database::Migration[2.2]
          MIGRATION = 'TestMigration'
          COLUMN = :id

          def up
            queue_batched_background_migration(
              MIGRATION,
              :granular_scopes,
              Other::COLUMN,
              job_interval: 2.minutes
            )
          end

          def down; end
        end
      RUBY

      expect(content).to include('column_name: Other::COLUMN')
    end

    it 'resolves constants that reference other constants to the terminal literal' do
      content = rewrite(<<~RUBY)
        class QueueTestMigration < Gitlab::Database::Migration[2.2]
          MIGRATION = 'TestMigration'
          BASE_PERMISSION = 'write_work_item'
          OLD_PERMISSION = BASE_PERMISSION

          def up
            queue_batched_background_migration(
              MIGRATION,
              :granular_scopes,
              :id,
              OLD_PERMISSION,
              job_interval: 2.minutes
            )
          end

          def down; end
        end
      RUBY

      expect(content).to include("job_arguments: ['write_work_item']")
    end

    it 'resolves constants nested inside a referenced composite constant' do
      content = rewrite(<<~RUBY)
        class QueueTestMigration < Gitlab::Database::Migration[2.2]
          MIGRATION = 'TestMigration'
          OLD_PERMISSION = 'write_work_item'
          PERMISSIONS_LIST = [OLD_PERMISSION, 'create_work_item']

          def up
            queue_batched_background_migration(
              MIGRATION,
              :granular_scopes,
              :id,
              PERMISSIONS_LIST,
              job_interval: 2.minutes
            )
          end

          def down; end
        end
      RUBY

      expect(content).to include("job_arguments: [['write_work_item', 'create_work_item']]")
    end
  end

  describe '#strip_comments' do
    it 'removes comment lines except the first line' do
      code = "# frozen_string_literal: true\n# this is a comment\nclass Foo\nend\n"
      result = rewriter.send(:strip_comments, code)

      expect(result).to eq("# frozen_string_literal: true\nclass Foo\nend\n")
    end

    it 'preserves non-comment lines' do
      code = "line1\nline2\nline3\n"
      result = rewriter.send(:strip_comments, code)

      expect(result).to eq("line1\nline2\nline3\n")
    end

    it 'preserves the first line even if it is a comment' do
      code = "# first line comment\n# second line comment\ncode\n"
      result = rewriter.send(:strip_comments, code)

      expect(result).to eq("# first line comment\ncode\n")
    end
  end
end
