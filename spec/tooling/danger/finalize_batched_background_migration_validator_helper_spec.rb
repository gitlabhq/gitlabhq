# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'
require_relative '../../../tooling/danger/finalize_batched_background_migration_validator_helper'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::FinalizeBatchedBackgroundMigrationValidatorHelper, feature_category: :database do
  include_context "with dangerfile"
  let(:fake_project_helper) { instance_double(Tooling::Danger::ProjectHelper) }
  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:valid_file_path) { 'db/post_migrate/20230101000000_finalize_migration.rb' }
  let(:invalid_file_path) { 'app/models/user.rb' }
  let(:helper) { fake_danger.new(helper: fake_project_helper) }

  describe '#validate_migrations' do
    context 'when no post migrate files are present' do
      it 'returns early' do
        expect(helper).not_to receive(:display_errors)

        helper.validate_migrations([invalid_file_path])
      end
    end

    context 'when post migrate files are present' do
      before do
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(valid_file_path).and_return(file_content)
      end

      context 'with no ensure_batched_background_migration_is_finished call' do
        let(:file_content) do
          <<~RUBY
            class QueueMigration < Gitlab::Database::Migration[2.2]
              def up
                queue_batched_background_migration(
                )
              end
            end
          RUBY
        end

        it 'does not report any errors' do
          expect(helper).to receive(:display_errors).with([])

          helper.validate_migrations([valid_file_path])
        end
      end

      context 'with valid content' do
        let(:file_content) do
          <<~RUBY
            class FinalizeMigration < Gitlab::Database::Migration[2.2]
              def up
                ensure_batched_background_migration_is_finished(
                  job_class_name: 'MigrationClass',
                  table_name: :users,
                  column_name: :id,
                  job_arguments: []
                )
              end
            end
          RUBY
        end

        it 'does not report any errors' do
          expect(helper).to receive(:display_errors).with([])

          helper.validate_migrations([valid_file_path])
        end
      end

      context 'with a constant instead of string for job_class_name' do
        let(:file_content) do
          <<~RUBY
            class FinalizeMigration < Gitlab::Database::Migration[2.2]
              def up
                ensure_batched_background_migration_is_finished(
                  job_class_name: MyMigrationClass,
                  table_name: :users,
                  column_name: :id,
                  job_arguments: []
                )
              end
            end
          RUBY
        end

        it 'reports an error about job_class_name' do
          expect(helper).to receive(:display_errors) do |errors|
            expect(errors.length).to eq(1)
            expect(errors.first[:message]).to include('The value of job_class_name should be a string in PascalCase')
          end

          helper.validate_migrations([valid_file_path])
        end
      end

      context 'with multiple ensure_batched_background_migration_is_finished calls' do
        let(:file_content) do
          <<~RUBY
            class FinalizeMigration < Gitlab::Database::Migration[2.2]

              def up
                first_finalize_migration
                second_finalize_migration
              end

              def first_finalize_migration
                ensure_batched_background_migration_is_finished(
                  job_class_name: 'MigrationClass1',
                  table_name: :users,
                  column_name: :id,
                  job_arguments: []
                )
              end
              def second_finalize_migration
                ensure_batched_background_migration_is_finished(
                  job_class_name: 'MigrationClass2',
                  table_name: :projects,
                  column_name: :id,
                  job_arguments: []
                )
              end
            end
          RUBY
        end

        it 'reports an error about multiple migrations' do
          expect(helper).to receive(:display_errors) do |errors|
            expect(errors.length).to eq(1)
            expect(errors.first[:message]).to include('There should only be one finalize batched background migration')
          end

          helper.validate_migrations([valid_file_path])
        end
      end

      context 'with multiple errors' do
        let(:file_content) do
          <<~RUBY
            class FinalizeMigration < Gitlab::Database::Migration[2.2]

              def up
                first_finalize_migration
                second_finalize_migration
              end

              def first_finalize_migration
                ensure_batched_background_migration_is_finished(
                  job_class_name: MigrationClass1,
                  table_name: :users,
                  column_name: :id,
                  job_arguments: []
                )
              end
              def second_finalize_migration
                ensure_batched_background_migration_is_finished(
                  job_class_name: MigrationClass2,
                  table_name: :projects,
                  column_name: :id,
                  job_arguments: []
                )
              end
            end
          RUBY
        end

        it 'reports both errors' do
          expect(helper).to receive(:display_errors) do |errors|
            expect(errors.length).to eq(2)
            expect(errors.pluck(:message)).to include(
              a_string_matching('There should only be one finalize batched background migration'),
              a_string_matching('The value of job_class_name should be a string in PascalCase')
            )
          end

          helper.validate_migrations([valid_file_path])
        end
      end
    end
  end

  describe '#validate_job_class_name_format' do
    it 'returns nil when job_class_name is a string' do
      file_content = <<~RUBY
        ensure_batched_background_migration_is_finished(
          job_class_name: "MigrationClass",
          table_name: :users
        )
      RUBY

      expect(helper.validate_job_class_name_format(valid_file_path, file_content)).to be_nil
    end

    it 'returns an error when job_class_name value is a constant' do
      file_content = <<~RUBY
        ensure_batched_background_migration_is_finished(
          job_class_name: MigrationClass,
          table_name: :users
        )
      RUBY

      result = helper.validate_job_class_name_format(valid_file_path, file_content)
      expect(result).to be_a(Hash)
      expect(result[:message]).to include('The value of job_class_name should be a string in PascalCase')
    end
  end

  describe '#validate_migration_count' do
    it 'returns nil when exactly one migration is present' do
      file_content = <<~RUBY
        ensure_batched_background_migration_is_finished(
          job_class_name: 'MigrationClass',
          table_name: :users
        )
      RUBY

      expect(helper.validate_migration_count(valid_file_path, file_content)).to be_nil
    end

    it 'returns an error when multiple migrations are present' do
      file_content = <<~RUBY
        ensure_batched_background_migration_is_finished(job_class_name: 'First')
        ensure_batched_background_migration_is_finished(job_class_name: 'Second')
      RUBY

      result = helper.validate_migration_count(valid_file_path, file_content)
      expect(result).to be_a(Hash)
      expect(result[:message]).to include('There should only be one finalize batched background migration')
    end
  end

  describe '#display_errors' do
    it 'returns nil when no errors are present' do
      expect(helper.display_errors([])).to be_nil
    end

    it 'calls fail with formatted error messages when errors are present' do
      errors = [
        { file: 'file1.rb', message: 'Error 1' },
        { file: 'file2.rb', message: 'Error 2' }
      ]

      expected_messages = [
        '**file1.rb**: Error 1',
        '**file2.rb**: Error 2'
      ]

      expect(helper).to receive(:fail).with(expected_messages)

      helper.display_errors(errors)
    end
  end
end
