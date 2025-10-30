# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../scripts/click_house/schema_validator'

RSpec.describe ClickHouse::SchemaValidator, feature_category: :database do
  describe '.validate!' do
    let(:schema_filename) { 'db/click_house/main.sql' }

    before do
      # Suppress puts output during tests
      allow($stdout).to receive(:puts)
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

      context 'when execute_git_diff succeeds and git command is successful' do
        before do
          allow(described_class).to receive(:git_command_successful?).and_return(true)
        end

        context 'when schema has no changes' do
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

          it 'prints change detection messages' do
            expect($stdout).to receive(:puts).with('Running ClickHouse migrations...')
            expect($stdout).to receive(:puts).with('Checking for schema changes...')
            expect($stdout).to receive(:puts).with('Schema has uncommitted changes after migration')
            expect($stdout).to receive(:puts).with("Changes detected in: #{schema_filename}")
            expect($stdout).to receive(:puts).with('Diff output:')
            expect($stdout).to receive(:puts).with(schema_diff)

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

  describe 'constants' do
    it 'defines the correct schema filename' do
      expect(described_class::SCHEMA_FILENAME).to eq('db/click_house/main.sql')
    end
  end

  describe 'integration scenarios' do
    let(:schema_filename) { 'db/click_house/main.sql' }

    before do
      allow($stdout).to receive(:puts)
    end

    context 'when full success flow - no schema changes' do
      before do
        allow(described_class).to receive(:system)
          .with('bundle exec rake gitlab:clickhouse:migrate:main gitlab:clickhouse:schema:dump:main')
          .and_return(true)
        allow(described_class).to receive_messages(
          execute_git_diff: '',
          git_command_successful?: true
        )
      end

      it 'executes all steps in correct order and returns true' do
        expect(described_class).to receive(:system)
          .with('bundle exec rake gitlab:clickhouse:migrate:main gitlab:clickhouse:schema:dump:main')
          .ordered
        expect(described_class).to receive(:execute_git_diff).ordered

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

    context 'when full failure flow - schema has changes' do
      let(:schema_diff) { "- CREATE TABLE old\n+ CREATE TABLE new" }

      before do
        allow(described_class).to receive(:system)
          .with('bundle exec rake gitlab:clickhouse:migrate:main gitlab:clickhouse:schema:dump:main')
          .and_return(true)
        allow(described_class).to receive_messages(
          execute_git_diff: schema_filename,
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
  end

  describe 'edge cases and boundary conditions' do
    let(:schema_filename) { 'db/click_house/main.sql' }

    before do
      allow($stdout).to receive(:puts)
      allow(described_class).to receive(:system)
        .with('bundle exec rake gitlab:clickhouse:migrate:main gitlab:clickhouse:schema:dump:main')
        .and_return(true)
      allow(described_class).to receive(:git_command_successful?).and_return(true)
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
  end
end
