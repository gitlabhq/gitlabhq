# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

require_relative '../../scripts/migration_schema_validator'

RSpec.describe MigrationSchemaValidator, feature_category: :database do
  subject(:validator) { described_class.new }

  describe '#validate!' do
    before do
      allow(validator).to receive(:validate_schema_on_rollback!)
      allow(validator).to receive(:validate_schema_on_migrate!)
      allow(validator).to receive(:validate_schema_version_files!)
      allow(validator).to receive(:validate_ignore_columns!)

      allow(validator).to receive_messages(
        committed_migrations: committed_migrations,
        partition_manager_config_changes?: partition_config_changes
      )
    end

    context 'when there are no committed migrations and no partition config changes' do
      let(:committed_migrations) { [] }
      let(:partition_config_changes) { false }

      it 'returns early without running any validations', :aggregate_failures do
        expect(validator.validate!).to be_nil

        expect(validator).not_to have_received(:validate_ignore_columns!)
        expect(validator).not_to have_received(:validate_schema_on_rollback!)
        expect(validator).not_to have_received(:validate_schema_on_migrate!)
        expect(validator).not_to have_received(:validate_schema_version_files!)
      end
    end

    context 'when only partition manager config changes are present' do
      let(:committed_migrations) { [] }
      let(:partition_config_changes) { true }

      it 'runs the validations', :aggregate_failures do
        validator.validate!

        expect(validator).to have_received(:validate_ignore_columns!)
        expect(validator).to have_received(:validate_schema_on_rollback!)
        expect(validator).to have_received(:validate_schema_on_migrate!)
        expect(validator).to have_received(:validate_schema_version_files!)
      end
    end

    context 'when there are committed migrations' do
      let(:committed_migrations) { ['db/migrate/20240101000000_my_migration.rb'] }
      let(:partition_config_changes) { false }

      context 'and no skip-validation label is present' do
        it 'runs the ignore-columns and all schema validations', :aggregate_failures do
          validator.validate!

          expect(validator).to have_received(:validate_ignore_columns!)
          expect(validator).to have_received(:validate_schema_on_rollback!)
          expect(validator).to have_received(:validate_schema_on_migrate!)
          expect(validator).to have_received(:validate_schema_version_files!)
        end
      end

      context 'and a skip-validation label is present' do
        before do
          stub_env('CI_MERGE_REQUEST_LABELS', 'pipeline::skip-check-migrations')
        end

        it 'still runs ignore-columns but skips the schema validations', :aggregate_failures do
          expect(validator.validate!).to be_nil

          expect(validator).to have_received(:validate_ignore_columns!)
          expect(validator).not_to have_received(:validate_schema_on_rollback!)
          expect(validator).not_to have_received(:validate_schema_on_migrate!)
          expect(validator).not_to have_received(:validate_schema_version_files!)
        end
      end
    end
  end

  describe '#skip_validation_label' do
    using RSpec::Parameterized::TableSyntax

    subject(:skip_validation_label) { validator.send(:skip_validation_label) }

    where(:case_name, :labels, :expected) do
      'no labels'      | ''                                                   | nil
      'single-colon'   | 'some::label,pipeline:skip-check-migrations,another' | 'pipeline:skip-check-migrations'
      'double-colon'   | 'pipeline::skip-check-migrations'                    | 'pipeline::skip-check-migrations'
      'unrelated only' | 'type::feature,group::database'                      | nil
    end

    with_them do
      before do
        stub_env('CI_MERGE_REQUEST_LABELS', labels)
      end

      it 'returns the matched skip label or nil' do
        expect(skip_validation_label).to eq(expected)
      end
    end

    it 'memoizes the result' do
      stub_env('CI_MERGE_REQUEST_LABELS', 'pipeline::skip-check-migrations')

      expect(validator.send(:skip_validation_label)).to eq('pipeline::skip-check-migrations')

      stub_env('CI_MERGE_REQUEST_LABELS', '')

      expect(validator.send(:skip_validation_label)).to eq('pipeline::skip-check-migrations')
    end
  end

  describe '#find_migration_version' do
    subject(:find_migration_version) { validator.send(:find_migration_version, filename) }

    context 'when the filename has a valid 14-digit version prefix' do
      let(:filename) { 'db/migrate/20240101000000_foo.rb' }

      it { is_expected.to eq('20240101000000') }
    end

    context 'when the filename has no valid version prefix' do
      let(:filename) { 'db/migrate/foo.rb' }

      it 'terminates the execution' do
        expect { find_migration_version }.to raise_error(SystemExit)
      end
    end

    context 'when the version prefix has too few digits' do
      let(:filename) { 'db/migrate/2024010100_foo.rb' }

      it 'terminates the execution' do
        expect { find_migration_version }.to raise_error(SystemExit)
      end
    end
  end

  describe '#validate_ignore_columns!' do
    let(:migration_file) { 'db/migrate/20240101000000_remove_foo.rb' }
    let(:migration_content) do
      <<~RUBY
        class RemoveFoo < Gitlab::Database::Migration[2.2]
          def up
            remove_column :users, :foo
          end
        end
      RUBY
    end

    let(:model_content) { model_body }

    before do
      allow(validator).to receive(:committed_migrations).and_return([migration_file])

      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(migration_file).and_return(true)
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(migration_file).and_return(migration_content)

      allow(validator).to receive(:model).with('users').and_return('User')
      allow(validator).to receive(:model_path).with('User').and_return('app/models/user.rb')
      allow(File).to receive(:exist?).with('app/models/user.rb').and_return(true)
      allow(File).to receive(:read).with('app/models/user.rb').and_return(model_content)
    end

    context 'when the model properly ignores the removed column' do
      let(:model_body) do
        <<~RUBY
          class User < ApplicationRecord
            ignore_column :foo, remove_with: '16.0', remove_after: '2024-01-01'
          end
        RUBY
      end

      it 'does not terminate the execution' do
        expect { validator.send(:validate_ignore_columns!) }.not_to raise_error
      end
    end

    context 'when the model ignores the removed column via the plural directive' do
      let(:model_body) do
        <<~RUBY
          class User < ApplicationRecord
            ignore_columns %i[foo bar], remove_with: '16.0', remove_after: '2024-01-01'
          end
        RUBY
      end

      it 'does not terminate the execution' do
        expect { validator.send(:validate_ignore_columns!) }.not_to raise_error
      end
    end

    context 'when the model does not ignore the removed column' do
      let(:model_body) do
        <<~RUBY
          class User < ApplicationRecord
          end
        RUBY
      end

      it 'terminates the execution' do
        expect { validator.send(:validate_ignore_columns!) }.to raise_error(SystemExit)
      end
    end
  end

  describe '#partition_manager_config_changes?' do
    subject(:partition_manager_config_changes?) { validator.send(:partition_manager_config_changes?) }

    before do
      allow(validator).to receive(:run).and_return(run_output)
    end

    context 'when the partition manager config file was changed' do
      let(:run_output) { 'config/initializers/postgres_partitioning.rb' }

      it { is_expected.to be(true) }
    end

    context 'when no partition manager config file was changed' do
      let(:run_output) { '' }

      it { is_expected.to be(false) }
    end
  end

  describe '#validate_schema_on_migrate!' do
    subject(:validate_schema_on_migrate!) { validator.send(:validate_schema_on_migrate!) }

    before do
      # run is called for db:migrate, db:schema:dump, and finally the git diff.
      # Only the git diff output determines pass/fail, so stub the migrate/dump
      # calls to succeed and control the final diff output per-context.
      #
      allow(validator).to receive(:run).with('scripts/db_tasks db:migrate').and_return('')
      allow(validator).to receive(:run).with('scripts/db_tasks db:schema:dump').and_return('')
      allow(validator).to receive(:run).with("git diff -- #{described_class::FILENAME}").and_return(diff_output)
    end

    context 'when the generated schema matches the committed one' do
      let(:diff_output) { '' }

      it 'does not terminate the execution' do
        expect { validate_schema_on_migrate! }.not_to raise_error
      end
    end

    context 'when the generated schema differs from the committed one' do
      let(:diff_output) { "@@ -1 +1 @@\n-old\n+new" }

      it 'terminates the execution' do
        expect { validate_schema_on_migrate! }.to raise_error(SystemExit)
      end
    end
  end
end
