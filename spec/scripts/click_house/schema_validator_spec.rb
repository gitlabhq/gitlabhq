# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/rspec/stub_env'
require_relative '../../../scripts/click_house/schema_validator'

RSpec.describe ClickHouse::SchemaValidator, feature_category: :database do
  describe '.validate!' do
    let(:schema_filename) { 'db/click_house/main.sql' }
    let(:schema_cache_dir) { 'db/click_house/schema_cache/' }

    before do
      # Suppress puts output during tests
      allow($stdout).to receive(:puts)

      # Default: schema version files are clean unless a context overrides it.
      allow(described_class).to receive(:execute_git_add_dry_run).and_return('')
    end

    context 'when skip validation label is present' do
      before do
        stub_env('CI_MERGE_REQUEST_LABELS', 'backend,pipeline:skip-check-clickhouse-schema,database')
      end

      it 'returns true without running migrations' do
        expect(described_class).not_to receive(:system)
        expect(described_class.validate!).to be true
      end

      it 'prints skip message' do
        expect($stdout).to receive(:puts).with(
          "\e[32mLabel pipeline:skip-check-clickhouse-schema is present, skipping schema validation\e[0m"
        )

        described_class.validate!
      end
    end

    context 'when skip validation label is not present' do
      before do
        stub_env('CI_MERGE_REQUEST_LABELS', 'backend,database')
        allow(described_class).to receive_messages(execute_git_diff: '', schema_cache_diff_output: '',
          validate_migration_checksums: true)
      end

      it 'proceeds with validation' do
        expect(described_class).to receive(:system)
          .with('bundle exec rake gitlab:clickhouse:migrate:main gitlab:clickhouse:schema:dump:main')
          .and_return(true)

        described_class.validate!
      end
    end

    context 'when CI_MERGE_REQUEST_LABELS is not set' do
      before do
        stub_env('CI_MERGE_REQUEST_LABELS', nil)
        allow(described_class).to receive_messages(execute_git_diff: '', schema_cache_diff_output: '',
          validate_migration_checksums: true)
      end

      it 'proceeds with validation' do
        expect(described_class).to receive(:system)
          .with('bundle exec rake gitlab:clickhouse:migrate:main gitlab:clickhouse:schema:dump:main')
          .and_return(true)

        described_class.validate!
      end
    end

    context 'when migration fails' do
      before do
        allow(described_class).to receive(:system)
          .with('bundle exec rake gitlab:clickhouse:migrate:main gitlab:clickhouse:schema:dump:main')
          .and_return(false)
      end

      it 'returns false' do
        expect(described_class.validate!).to be false
      end

      it 'prints error message' do
        expect($stdout).to receive(:puts).with('Running ClickHouse migrations...')
        expect($stdout).to receive(:puts).with('ERROR: ClickHouse migration failed')

        described_class.validate!
      end

      it 'does not check for schema changes' do
        expect(described_class).not_to receive(:execute_git_diff)

        described_class.validate!
      end
    end

    context 'when migration succeeds' do
      before do
        allow(described_class).to receive(:system)
          .with('bundle exec rake gitlab:clickhouse:migrate:main gitlab:clickhouse:schema:dump:main')
          .and_return(true)
        allow(described_class).to receive_messages(schema_cache_diff_output: '',
          validate_migration_checksums: true)
      end

      it 'validates the schema version files after a successful migration' do
        allow(described_class).to receive(:execute_git_diff).and_return('')

        expect(described_class).to receive(:validate_schema_version_files).and_call_original

        described_class.validate!
      end

      context 'when execute_git_diff returns nil (git command failed)' do
        before do
          allow(described_class).to receive(:execute_git_diff).and_return(nil)
        end

        it 'returns false' do
          expect(described_class.validate!).to be false
        end

        it 'prints expected messages' do
          expect($stdout).to receive(:puts).with('Running ClickHouse migrations...')
          expect($stdout).to receive(:puts).with('Checking for schema changes...')

          described_class.validate!
        end
      end

      context 'when schema_cache_diff_output returns nil (git command failed)' do
        before do
          allow(described_class).to receive_messages(execute_git_diff: '', schema_cache_diff_output: nil)
        end

        it 'returns false' do
          expect(described_class.validate!).to be false
        end

        it 'prints expected messages' do
          expect($stdout).to receive(:puts).with('Running ClickHouse migrations...')
          expect($stdout).to receive(:puts).with('Checking for schema changes...')
          expect($stdout).to receive(:puts).with('ERROR: Git diff command failed for schema cache')

          described_class.validate!
        end
      end

      context 'when execute_git_diff succeeds and git command is successful' do
        before do
          allow(described_class).to receive_messages(git_command_successful?: true, schema_cache_diff_output: '')
        end

        context 'when schema has no changes and all checksums exist' do
          before do
            allow(described_class).to receive(:execute_git_diff).and_return('')
          end

          it 'returns true' do
            expect(described_class.validate!).to be true
          end

          it 'prints success message' do
            expect($stdout).to receive(:puts).with('Running ClickHouse migrations...')
            expect($stdout).to receive(:puts).with('Checking for schema changes...')
            expect($stdout).to receive(:puts).with('Schema is up to date - no changes detected')

            described_class.validate!
          end
        end

        context 'when schema has changes' do
          let(:git_diff_output) { "#{schema_filename}\nother_file.rb" }
          let(:schema_diff) { "- old line\n+ new line" }

          before do
            allow(described_class).to receive(:execute_git_diff).and_return(git_diff_output)
            allow(described_class).to receive(:`).with("git diff -- #{schema_filename}").and_return(schema_diff)
          end

          it 'returns false' do
            expect(described_class.validate!).to be false
          end

          it 'prints change detection messages with skip label hint' do
            expect($stdout).to receive(:puts).with('Running ClickHouse migrations...')
            expect($stdout).to receive(:puts).with('Checking for schema changes...')
            expect($stdout).to receive(:puts).with('Schema has uncommitted changes after migration')
            expect($stdout).to receive(:puts).with("Changes detected in: #{schema_filename}")
            expect($stdout).to receive(:puts).with('Diff output:')
            expect($stdout).to receive(:puts).with(schema_diff)
            expect($stdout).to receive(:puts).with(
              "Please investigate. Apply the 'pipeline:skip-check-clickhouse-schema' label to skip this check " \
                "if needed. If you are unsure why this job is failing for your MR, then please refer to this page: " \
                "https://docs.gitlab.com/development/database/clickhouse/reviewer_guidelines.html" \
                "#ensuring-database-schema-consistency"
            )

            described_class.validate!
          end
        end

        context 'when schema cache has changes' do
          let(:cache_diff_output) { "diff --git a/db/click_house/schema_cache/main/new_table.yml ...\n+new content\n" }

          before do
            allow(described_class).to receive_messages(execute_git_diff: '',
              schema_cache_diff_output: cache_diff_output)
          end

          it 'returns false' do
            expect(described_class.validate!).to be false
          end

          it 'prints cache change detection messages with skip label hint' do
            expect($stdout).to receive(:puts).with('Running ClickHouse migrations...')
            expect($stdout).to receive(:puts).with('Checking for schema changes...')
            expect($stdout).to receive(:puts).with('Schema cache has uncommitted changes after migration')
            expect($stdout).to receive(:puts).with("Changes detected in: #{schema_cache_dir}")
            expect($stdout).to receive(:puts).with('Diff output:')
            expect($stdout).to receive(:puts).with(cache_diff_output)
            expect($stdout).to receive(:puts).with(
              "Please investigate. Apply the 'pipeline:skip-check-clickhouse-schema' label to skip this check " \
                "if needed. If you are unsure why this job is failing for your MR, then please refer to this page: " \
                "https://docs.gitlab.com/development/database/clickhouse/reviewer_guidelines.html" \
                "#ensuring-database-schema-consistency"
            )

            described_class.validate!
          end

          it 'does not print success message' do
            expect($stdout).not_to receive(:puts).with('Schema is up to date - no changes detected')

            described_class.validate!
          end
        end

        context 'when both schema file and schema cache have changes' do
          let(:schema_diff) { "- old\n+ new" }
          let(:cache_diff_output) { "db/click_house/schema_cache/main/events.yml\n" }

          before do
            allow(described_class).to receive_messages(execute_git_diff: schema_filename,
              schema_cache_diff_output: cache_diff_output)
            allow(described_class).to receive(:`).with("git diff -- #{schema_filename}").and_return(schema_diff)
          end

          it 'returns false' do
            expect(described_class.validate!).to be false
          end

          it 'reports both failures' do
            expect($stdout).to receive(:puts).with('Schema has uncommitted changes after migration')
            expect($stdout).to receive(:puts).with('Schema cache has uncommitted changes after migration')

            described_class.validate!
          end
        end

        context 'when migration checksum files are missing' do
          let(:missing_version) { '20240101120000' }

          before do
            allow(described_class).to receive_messages(execute_git_diff: '', validate_migration_checksums: false)
          end

          it 'returns false' do
            expect(described_class.validate!).to be false
          end

          it 'does not print success message' do
            expect($stdout).not_to receive(:puts).with('Schema is up to date - no changes detected')

            described_class.validate!
          end
        end

        context 'when git diff output contains schema filename as substring' do
          before do
            allow(described_class).to receive(:execute_git_diff)
              .and_return("some_other_#{schema_filename}_backup")
            allow(described_class).to receive(:`).with("git diff -- #{schema_filename}").and_return('changes')
          end

          it 'correctly identifies schema changes (substring match)' do
            expect(described_class.validate!).to be false
          end
        end

        context 'when git diff output contains exact schema filename' do
          before do
            allow(described_class).to receive(:execute_git_diff).and_return(schema_filename)
            allow(described_class).to receive(:`).with("git diff -- #{schema_filename}").and_return('diff content')
          end

          it 'correctly identifies schema changes' do
            expect(described_class.validate!).to be false
          end
        end

        context 'when git diff output contains schema filename with newlines' do
          before do
            allow(described_class).to receive(:execute_git_diff).and_return("some_file.txt\n#{schema_filename}\n")
            allow(described_class).to receive(:`).with("git diff -- #{schema_filename}").and_return('diff content')
          end

          it 'correctly identifies schema changes' do
            expect(described_class.validate!).to be false
          end
        end
      end

      context 'when schema version files are validated' do
        let(:migrations_dir) { 'db/click_house/schema_migrations/main' }

        before do
          allow(described_class).to receive(:execute_git_diff).and_return('')
        end

        context 'when schema version files are up to date' do
          before do
            allow(described_class).to receive(:execute_git_add_dry_run).and_return('')
          end

          it 'returns true' do
            expect(described_class.validate!).to be true
          end

          it 'prints success message' do
            expect($stdout).to receive(:puts).with('Checking for schema version file changes...')
            expect($stdout).to receive(:puts).with(
              'Schema version files are up to date - no changes detected'
            )

            described_class.validate!
          end
        end

        context 'when schema version files have uncommitted changes' do
          let(:add_dry_run_output) { "add '#{migrations_dir}/20260618182736'" }

          before do
            allow(described_class).to receive(:execute_git_add_dry_run).and_return(add_dry_run_output)
          end

          it 'returns false' do
            expect(described_class.validate!).to be false
          end

          it 'prints change detection messages with skip label hint' do
            expect($stdout).to receive(:puts).with('Checking for schema version file changes...')
            expect($stdout).to receive(:puts).with(
              "The committed files in #{migrations_dir} do not match those expected by the added migrations"
            )
            expect($stdout).to receive(:puts).with('Uncommitted changes:')
            expect($stdout).to receive(:puts).with(add_dry_run_output)
            expect($stdout).to receive(:puts).with(
              "Please investigate. Apply the 'pipeline:skip-check-clickhouse-schema' label to skip this check " \
                "if needed. If you are unsure why this job is failing for your MR, then please refer to this page: " \
                "https://docs.gitlab.com/development/database/clickhouse/reviewer_guidelines.html" \
                "#ensuring-database-schema-consistency"
            )

            described_class.validate!
          end
        end

        context 'when execute_git_add_dry_run returns nil (git command failed)' do
          before do
            allow(described_class).to receive(:execute_git_add_dry_run).and_return(nil)
          end

          it 'returns false' do
            expect(described_class.validate!).to be false
          end
        end

        context 'when the schema file is dirty but version files are clean' do
          before do
            allow(described_class).to receive(:`).with("git diff -- #{schema_filename}").and_return('changes')
            allow(described_class).to receive_messages(
              execute_git_diff: schema_filename,
              execute_git_add_dry_run: ''
            )
          end

          it 'returns false' do
            expect(described_class.validate!).to be false
          end
        end
      end
    end
  end

  describe '.execute_git_add_dry_run' do
    let(:migrations_dir) { 'db/click_house/schema_migrations/main' }
    let(:git_command) { "git add -A -n #{migrations_dir}" }

    before do
      allow($stdout).to receive(:puts)
    end

    context 'when git command succeeds' do
      let(:git_output) { "add '#{migrations_dir}/20260618182736'" }

      before do
        allow(described_class).to receive(:`).with(git_command).and_return(git_output)
        allow(described_class).to receive(:git_command_successful?).and_return(true)
      end

      it 'returns the git output' do
        expect(described_class.execute_git_add_dry_run).to eq(git_output)
      end
    end

    context 'when git command fails' do
      before do
        allow(described_class).to receive(:`).with(git_command).and_return('')
        allow(described_class).to receive(:git_command_successful?).and_return(false)
      end

      it 'returns nil' do
        expect(described_class.execute_git_add_dry_run).to be_nil
      end
    end

    context 'when git command returns empty output but succeeds' do
      before do
        allow(described_class).to receive(:`).with(git_command).and_return('')
        allow(described_class).to receive(:git_command_successful?).and_return(true)
      end

      it 'returns empty string' do
        expect(described_class.execute_git_add_dry_run).to eq('')
      end
    end
  end

  describe '.validate_migration_checksums' do
    let(:schema_migrations_dir) { 'db/click_house/schema_migrations/main' }

    before do
      allow($stdout).to receive(:puts)
    end

    context 'when all migrations have checksum files' do
      before do
        allow(described_class).to receive(:migration_versions_missing_checksums).and_return([])
      end

      it 'returns true' do
        expect(described_class.validate_migration_checksums).to be true
      end

      it 'prints success message' do
        expect($stdout).to receive(:puts).with('Checking migration checksum files...')
        expect($stdout).to receive(:puts).with('All migration checksum files exist')

        described_class.validate_migration_checksums
      end
    end

    context 'when some migration checksum files are missing' do
      let(:missing_versions) { %w[20240101120000 20240202130000] }

      before do
        allow(described_class).to receive(:migration_versions_missing_checksums).and_return(missing_versions)
      end

      it 'returns false' do
        expect(described_class.validate_migration_checksums).to be false
      end

      it 'prints missing file paths' do
        expect($stdout).to receive(:puts).with('Checking migration checksum files...')
        expect($stdout).to receive(:puts).with('Missing migration checksum files:')
        expect($stdout).to receive(:puts).with("  #{schema_migrations_dir}/20240101120000")
        expect($stdout).to receive(:puts).with("  #{schema_migrations_dir}/20240202130000")
        expect($stdout).to receive(:puts).with(
          "Run 'bundle exec rake gitlab:clickhouse:migrate:main' and commit the generated checksum files. " \
            "Apply the 'pipeline:skip-check-clickhouse-schema' label to skip this check if needed."
        )

        described_class.validate_migration_checksums
      end
    end
  end

  describe '.migration_versions_missing_checksums' do
    let(:schema_migrations_dir) { 'db/click_house/schema_migrations/main' }

    before do
      allow(described_class).to receive(:migration_versions).and_return(%w[20230101120000 20230202130000])
    end

    context 'when all checksum files exist' do
      before do
        allow(File).to receive(:exist?).with("#{schema_migrations_dir}/20230101120000").and_return(true)
        allow(File).to receive(:exist?).with("#{schema_migrations_dir}/20230202130000").and_return(true)
      end

      it 'returns an empty array' do
        expect(described_class.migration_versions_missing_checksums).to be_empty
      end
    end

    context 'when some checksum files are missing' do
      before do
        allow(File).to receive(:exist?).with("#{schema_migrations_dir}/20230101120000").and_return(true)
        allow(File).to receive(:exist?).with("#{schema_migrations_dir}/20230202130000").and_return(false)
      end

      it 'returns the missing versions' do
        expect(described_class.migration_versions_missing_checksums).to eq(%w[20230202130000])
      end
    end

    context 'when all checksum files are missing' do
      before do
        allow(File).to receive(:exist?).and_return(false)
      end

      it 'returns all versions' do
        expect(described_class.migration_versions_missing_checksums).to eq(%w[20230101120000 20230202130000])
      end
    end

    context 'when there are no migration versions' do
      before do
        allow(described_class).to receive(:migration_versions).and_return([])
      end

      it 'returns an empty array' do
        expect(described_class.migration_versions_missing_checksums).to be_empty
      end
    end
  end

  describe '.migration_versions' do
    context 'when migration files exist in both dirs' do
      before do
        allow(Dir).to receive(:glob)
          .with('db/click_house/migrate/main/*.rb')
          .and_return([
            'db/click_house/migrate/main/20230101120000_create_events.rb',
            'db/click_house/migrate/main/20230202130000_add_column.rb'
          ])
        allow(Dir).to receive(:glob)
          .with('db/click_house/post_migrate/main/*.rb')
          .and_return([
            'db/click_house/post_migrate/main/20230303140000_drop_old_table.rb'
          ])
      end

      it 'returns all version timestamps from both directories' do
        expect(described_class.migration_versions).to eq(%w[20230101120000 20230202130000 20230303140000])
      end
    end

    context 'when no migration files exist' do
      before do
        allow(Dir).to receive(:glob).and_return([])
      end

      it 'returns an empty array' do
        expect(described_class.migration_versions).to be_empty
      end
    end

    context 'when files have names with underscores in the description' do
      before do
        allow(Dir).to receive(:glob)
          .with('db/click_house/migrate/main/*.rb')
          .and_return(['db/click_house/migrate/main/20230101120000_create_big_events_table.rb'])
        allow(Dir).to receive(:glob)
          .with('db/click_house/post_migrate/main/*.rb')
          .and_return([])
      end

      it 'extracts only the leading numeric version' do
        expect(described_class.migration_versions).to eq(['20230101120000'])
      end
    end
  end

  describe '.execute_git_diff' do
    let(:schema_filename) { 'db/click_house/main.sql' }
    let(:git_command) { "git diff --name-only -- #{schema_filename}" }

    before do
      allow($stdout).to receive(:puts)
    end

    context 'when git command succeeds' do
      let(:git_output) { "#{schema_filename}\nother_file.rb" }

      before do
        allow(described_class).to receive(:`).with(git_command).and_return(git_output)
        allow(described_class).to receive(:git_command_successful?).and_return(true)
      end

      it 'returns the git output' do
        expect(described_class.execute_git_diff).to eq(git_output)
      end

      it 'does not print error message' do
        expect($stdout).not_to receive(:puts).with('ERROR: Git diff command failed')

        described_class.execute_git_diff
      end
    end

    context 'when git command fails' do
      before do
        allow(described_class).to receive(:`).with(git_command).and_return('')
        allow(described_class).to receive(:git_command_successful?).and_return(false)
      end

      it 'returns nil' do
        expect(described_class.execute_git_diff).to be_nil
      end

      it 'does not print error message' do
        expect($stdout).not_to receive(:puts).with('ERROR: Git diff command failed')

        described_class.execute_git_diff
      end
    end

    context 'when git command returns empty output but succeeds' do
      before do
        allow(described_class).to receive(:`).with(git_command).and_return('')
        allow(described_class).to receive(:git_command_successful?).and_return(true)
      end

      it 'returns empty string' do
        expect(described_class.execute_git_diff).to eq('')
      end
    end

    context 'when git command returns whitespace' do
      before do
        allow(described_class).to receive(:`).with(git_command).and_return("   \n  \t  ")
        allow(described_class).to receive(:git_command_successful?).and_return(true)
      end

      it 'returns the whitespace string' do
        expect(described_class.execute_git_diff).to eq("   \n  \t  ")
      end
    end
  end

  describe '.schema_cache_diff_output' do
    let(:schema_cache_dir) { 'db/click_house/schema_cache/' }
    let(:diff_command) { "git diff -- #{schema_cache_dir}" }
    let(:untracked_command) { "git ls-files --others --exclude-standard -- #{schema_cache_dir}" }

    before do
      allow($stdout).to receive(:puts)
    end

    context 'when both git commands succeed with no changes' do
      before do
        allow(described_class).to receive(:`).with(diff_command).and_return('')
        allow(described_class).to receive(:`).with(untracked_command).and_return('')
        allow(described_class).to receive(:git_command_successful?).and_return(true)
      end

      it 'returns empty string' do
        expect(described_class.schema_cache_diff_output).to eq('')
      end
    end

    context 'when diff command detects modified files' do
      let(:diff_output) { "diff --git a/db/click_house/schema_cache/main/events.yml ...\n-old\n+new\n" }

      before do
        allow(described_class).to receive(:`).with(diff_command).and_return(diff_output)
        allow(described_class).to receive(:`).with(untracked_command).and_return('')
        allow(described_class).to receive(:git_command_successful?).and_return(true)
      end

      it 'returns the tracked diff output' do
        expect(described_class.schema_cache_diff_output).to eq(diff_output)
      end
    end

    context 'when untracked command detects new files' do
      let(:untracked_file) { 'db/click_house/schema_cache/main/new_table.yml' }
      let(:untracked_diff) { "diff --git /dev/null b/#{untracked_file}\n+new content\n" }

      before do
        allow(described_class).to receive(:`).with(diff_command).and_return('')
        allow(described_class).to receive(:`).with(untracked_command).and_return("#{untracked_file}\n")
        allow(described_class).to receive(:`).with("git diff --no-index /dev/null #{untracked_file}")
          .and_return(untracked_diff)
        allow(described_class).to receive(:git_command_successful?).and_return(true)
      end

      it 'returns the untracked file diff' do
        expect(described_class.schema_cache_diff_output).to eq(untracked_diff)
      end
    end

    context 'when both commands detect changes' do
      let(:tracked_diff) { "diff --git a/db/click_house/schema_cache/main/events.yml ...\n-old\n+new\n" }
      let(:untracked_file) { 'db/click_house/schema_cache/main/new_table.yml' }
      let(:untracked_diff) { "diff --git /dev/null b/#{untracked_file}\n+new content\n" }

      before do
        allow(described_class).to receive(:`).with(diff_command).and_return(tracked_diff)
        allow(described_class).to receive(:`).with(untracked_command).and_return("#{untracked_file}\n")
        allow(described_class).to receive(:`).with("git diff --no-index /dev/null #{untracked_file}")
          .and_return(untracked_diff)
        allow(described_class).to receive(:git_command_successful?).and_return(true)
      end

      it 'returns the combined output of tracked and untracked diffs' do
        expect(described_class.schema_cache_diff_output).to eq(tracked_diff + untracked_diff)
      end
    end

    context 'when the diff command fails' do
      before do
        allow(described_class).to receive(:`).with(diff_command).and_return('')
        allow(described_class).to receive(:git_command_successful?).and_return(false)
      end

      it 'returns nil without running the untracked command' do
        expect(described_class).not_to receive(:`).with(untracked_command)

        expect(described_class.schema_cache_diff_output).to be_nil
      end
    end

    context 'when the untracked command fails' do
      before do
        allow(described_class).to receive(:`).with(diff_command).and_return('')
        allow(described_class).to receive(:`).with(untracked_command).and_return('')
        # First call (after diff) succeeds, second call (after untracked) fails
        allow(described_class).to receive(:git_command_successful?).and_return(true, false)
      end

      it 'returns nil' do
        expect(described_class.schema_cache_diff_output).to be_nil
      end
    end
  end

  describe '.git_command_successful?' do
    context 'when $? indicates success' do
      before do
        # Simulate successful command execution
        `true` # This sets $? to success
      end

      it 'returns true' do
        expect(described_class.git_command_successful?).to be true
      end
    end

    context 'when $? indicates failure' do
      before do
        # Simulate failed command execution
        `false` # This sets $? to failure
      end

      it 'returns false' do
        expect(described_class.git_command_successful?).to be false
      end
    end
  end

  describe '.skip_validation?' do
    subject(:skip_validation) { described_class.skip_validation? }

    before do
      stub_env('CI_MERGE_REQUEST_LABELS', labels)
    end

    context 'when CI_MERGE_REQUEST_LABELS contains the skip label' do
      let(:labels) { 'backend,pipeline:skip-check-clickhouse-schema,database' }

      it { is_expected.to be true }
    end

    context 'when CI_MERGE_REQUEST_LABELS does not contain the skip label' do
      let(:labels) { 'backend,database' }

      it { is_expected.to be false }
    end

    context 'when CI_MERGE_REQUEST_LABELS is empty' do
      let(:labels) { '' }

      it { is_expected.to be false }
    end

    context 'when CI_MERGE_REQUEST_LABELS is not set' do
      let(:labels) { nil }

      it { is_expected.to be false }
    end

    context 'when CI_MERGE_REQUEST_LABELS contains a partial match' do
      let(:labels) { 'pipeline:skip-check-clickhouse-schema-other' }

      it { is_expected.to be false }
    end
  end

  describe 'constants' do
    it 'defines the correct schema filename' do
      expect(described_class::SCHEMA_FILENAME).to eq('db/click_house/main.sql')
    end

    it 'defines the correct schema cache directory' do
      expect(described_class::SCHEMA_CACHE_DIR).to eq('db/click_house/schema_cache/')
    end

    it 'defines the correct schema migrations directory' do
      expect(described_class::SCHEMA_MIGRATIONS_DIR).to eq('db/click_house/schema_migrations/main')
    end

    it 'defines the correct migrations directories' do
      expect(described_class::MIGRATIONS_DIRS).to eq(%w[
        db/click_house/migrate/main
        db/click_house/post_migrate/main
      ])
    end

    it 'defines the correct skip validation label' do
      expect(described_class::SKIP_VALIDATION_LABEL).to eq('pipeline:skip-check-clickhouse-schema')
    end
  end

  describe 'integration scenarios' do
    let(:schema_filename) { 'db/click_house/main.sql' }

    before do
      allow($stdout).to receive(:puts)
      allow(described_class).to receive(:execute_git_add_dry_run).and_return('')
    end

    context 'when full success flow - no schema changes and all checksums exist' do
      before do
        allow(described_class).to receive(:system)
          .with('bundle exec rake gitlab:clickhouse:migrate:main gitlab:clickhouse:schema:dump:main')
          .and_return(true)
        allow(described_class).to receive_messages(
          execute_git_diff: '',
          schema_cache_diff_output: '',
          validate_migration_checksums: true,
          git_command_successful?: true
        )
      end

      it 'executes all steps in correct order and returns true' do
        expect(described_class).to receive(:system)
          .with('bundle exec rake gitlab:clickhouse:migrate:main gitlab:clickhouse:schema:dump:main')
          .ordered
        expect(described_class).to receive(:execute_git_diff).ordered
        expect(described_class).to receive(:schema_cache_diff_output).ordered
        expect(described_class).to receive(:validate_migration_checksums).ordered

        result = described_class.validate!
        expect(result).to be true
      end

      it 'prints expected success messages' do
        expect($stdout).to receive(:puts).with('Running ClickHouse migrations...').ordered
        expect($stdout).to receive(:puts).with('Checking for schema changes...').ordered
        expect($stdout).to receive(:puts).with('Schema is up to date - no changes detected').ordered

        described_class.validate!
      end
    end

    context 'when full failure flow - schema file has changes' do
      let(:schema_diff) { "- CREATE TABLE old\n+ CREATE TABLE new" }

      before do
        allow(described_class).to receive(:system)
          .with('bundle exec rake gitlab:clickhouse:migrate:main gitlab:clickhouse:schema:dump:main')
          .and_return(true)
        allow(described_class).to receive_messages(
          execute_git_diff: schema_filename,
          schema_cache_diff_output: '',
          validate_migration_checksums: true,
          git_command_successful?: true
        )
        allow(described_class).to receive(:`).with("git diff -- #{schema_filename}").and_return(schema_diff)
      end

      it 'executes all steps and returns false' do
        expect(described_class).to receive(:system)
          .with('bundle exec rake gitlab:clickhouse:migrate:main gitlab:clickhouse:schema:dump:main')
          .ordered
        expect(described_class).to receive(:execute_git_diff).ordered
        expect(described_class).to receive(:`).with("git diff -- #{schema_filename}").ordered

        result = described_class.validate!
        expect(result).to be false
      end

      it 'prints expected failure messages' do
        expect($stdout).to receive(:puts).with('Running ClickHouse migrations...').ordered
        expect($stdout).to receive(:puts).with('Checking for schema changes...').ordered
        expect($stdout).to receive(:puts).with('Schema has uncommitted changes after migration').ordered
        expect($stdout).to receive(:puts).with("Changes detected in: #{schema_filename}").ordered
        expect($stdout).to receive(:puts).with('Diff output:').ordered
        expect($stdout).to receive(:puts).with(schema_diff).ordered

        described_class.validate!
      end
    end

    context 'when full failure flow - schema cache has changes' do
      let(:cache_diff) { "diff --git a/db/click_house/schema_cache/main/new_table.yml ...\n+new content\n" }

      before do
        allow(described_class).to receive(:system)
          .with('bundle exec rake gitlab:clickhouse:migrate:main gitlab:clickhouse:schema:dump:main')
          .and_return(true)
        allow(described_class).to receive_messages(
          execute_git_diff: '',
          schema_cache_diff_output: cache_diff,
          validate_migration_checksums: true,
          git_command_successful?: true
        )
      end

      it 'returns false' do
        result = described_class.validate!
        expect(result).to be false
      end

      it 'prints expected cache failure messages' do
        expect($stdout).to receive(:puts).with('Running ClickHouse migrations...').ordered
        expect($stdout).to receive(:puts).with('Checking for schema changes...').ordered
        expect($stdout).to receive(:puts).with('Schema cache has uncommitted changes after migration').ordered
        expect($stdout).to receive(:puts).with("Changes detected in: db/click_house/schema_cache/").ordered
        expect($stdout).to receive(:puts).with('Diff output:').ordered
        expect($stdout).to receive(:puts).with(cache_diff).ordered

        described_class.validate!
      end
    end

    context 'when full failure flow - migration checksum files are missing' do
      before do
        allow(described_class).to receive(:system)
          .with('bundle exec rake gitlab:clickhouse:migrate:main gitlab:clickhouse:schema:dump:main')
          .and_return(true)
        allow(described_class).to receive_messages(
          execute_git_diff: '',
          schema_cache_diff_output: '',
          validate_migration_checksums: false,
          git_command_successful?: true
        )
      end

      it 'returns false' do
        result = described_class.validate!
        expect(result).to be false
      end

      it 'does not print success message' do
        expect($stdout).not_to receive(:puts).with('Schema is up to date - no changes detected')

        described_class.validate!
      end
    end

    context 'when migration failure flow' do
      before do
        allow(described_class).to receive(:system)
          .with('bundle exec rake gitlab:clickhouse:migrate:main gitlab:clickhouse:schema:dump:main')
          .and_return(false)
      end

      it 'stops at migration step and returns false' do
        expect(described_class).to receive(:system)
          .with('bundle exec rake gitlab:clickhouse:migrate:main gitlab:clickhouse:schema:dump:main')
          .ordered
        expect(described_class).not_to receive(:execute_git_diff)

        result = described_class.validate!
        expect(result).to be false
      end

      it 'prints migration failure messages' do
        expect($stdout).to receive(:puts).with('Running ClickHouse migrations...').ordered
        expect($stdout).to receive(:puts).with('ERROR: ClickHouse migration failed').ordered

        described_class.validate!
      end
    end

    context 'when git diff execution failure flow' do
      before do
        allow(described_class).to receive(:system)
          .with('bundle exec rake gitlab:clickhouse:migrate:main gitlab:clickhouse:schema:dump:main')
          .and_return(true)
        allow(described_class).to receive(:execute_git_diff).and_return(nil)
      end

      it 'stops at git diff step and returns false' do
        expect(described_class).to receive(:system)
          .with('bundle exec rake gitlab:clickhouse:migrate:main gitlab:clickhouse:schema:dump:main')
          .ordered
        expect(described_class).to receive(:execute_git_diff).ordered
        expect(described_class).not_to receive(:git_command_successful?)

        result = described_class.validate!
        expect(result).to be false
      end
    end

    context 'when git diff schema cache execution failure flow' do
      before do
        allow(described_class).to receive(:system)
          .with('bundle exec rake gitlab:clickhouse:migrate:main gitlab:clickhouse:schema:dump:main')
          .and_return(true)
        allow(described_class).to receive_messages(execute_git_diff: '', schema_cache_diff_output: nil)
      end

      it 'returns false' do
        result = described_class.validate!
        expect(result).to be false
      end

      it 'prints schema cache git diff failure message' do
        expect($stdout).to receive(:puts).with('ERROR: Git diff command failed for schema cache')

        described_class.validate!
      end
    end
  end

  describe 'edge cases and boundary conditions' do
    let(:schema_filename) { 'db/click_house/main.sql' }

    before do
      allow($stdout).to receive(:puts)
      allow(described_class).to receive(:system)
        .with('bundle exec rake gitlab:clickhouse:migrate:main gitlab:clickhouse:schema:dump:main')
        .and_return(true)
      allow(described_class).to receive_messages(
        git_command_successful?: true,
        schema_cache_diff_output: '',
        execute_git_add_dry_run: '',
        validate_migration_checksums: true
      )
    end

    context 'when schema filename appears as exact match in a list' do
      before do
        allow(described_class).to receive(:execute_git_diff).and_return("file1.txt\n#{schema_filename}\nfile2.txt")
        allow(described_class).to receive(:`).with("git diff -- #{schema_filename}").and_return('changes')
      end

      it 'correctly identifies schema changes' do
        expect(described_class.validate!).to be false
      end
    end

    context 'when multiple files contain schema filename as substring' do
      before do
        allow(described_class).to receive(:execute_git_diff)
          .and_return("backup_#{schema_filename}\n#{schema_filename}_old\nrandom_file.txt")
        allow(described_class).to receive(:`).with("git diff -- #{schema_filename}").and_return('changes')
      end

      it 'correctly identifies schema changes due to substring matches' do
        expect(described_class.validate!).to be false
      end
    end

    context 'when output contains only unrelated files' do
      before do
        allow(described_class).to receive(:execute_git_diff)
          .and_return("totally_different_file.txt\nanother_file.rb\nthird_file.py")
      end

      it 'correctly identifies no schema changes' do
        expect(described_class.validate!).to be true
      end
    end

    context 'when output is nil (execute_git_diff failed)' do
      before do
        allow(described_class).to receive(:execute_git_diff).and_return(nil)
      end

      it 'returns false immediately' do
        expect(described_class.validate!).to be false
      end
    end

    context 'when schema filename is empty string (edge case)' do
      before do
        stub_const('ClickHouse::SchemaValidator::SCHEMA_FILENAME', '')
        allow(described_class).to receive(:execute_git_diff).and_return('any_file.txt')
      end

      it 'handles empty schema filename gracefully' do
        # With empty string, include? will always return true for any non-empty string
        expect(described_class.validate!).to be false
      end
    end

    context 'when git diff output is exactly the schema filename' do
      before do
        allow(described_class).to receive(:execute_git_diff).and_return(schema_filename)
        allow(described_class).to receive(:`).with("git diff -- #{schema_filename}").and_return('schema changes')
      end

      it 'correctly identifies schema changes' do
        expect(described_class.validate!).to be false
      end
    end

    context 'when git diff output is empty string' do
      before do
        allow(described_class).to receive(:execute_git_diff).and_return('')
      end

      it 'correctly identifies no schema changes' do
        expect(described_class.validate!).to be true
      end
    end

    context 'when git diff output contains only whitespace' do
      before do
        allow(described_class).to receive(:execute_git_diff).and_return("   \n  \t  ")
      end

      it 'correctly identifies no schema changes' do
        expect(described_class.validate!).to be true
      end
    end

    context 'when schema cache diff output contains only whitespace' do
      before do
        allow(described_class).to receive_messages(execute_git_diff: '', schema_cache_diff_output: "   \n  \t  ")
      end

      it 'correctly identifies no schema cache changes' do
        expect(described_class.validate!).to be true
      end
    end
  end
end
