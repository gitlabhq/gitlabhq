# frozen_string_literal: true

require 'gitlab/dangerfiles/spec_helper'
require 'gitlab/rspec/stub_env'
require_relative '../../../tooling/danger/batched_background_migration_modification_checks_helper'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::BatchedBackgroundMigrationModificationChecksHelper, feature_category: :database do
  include StubENV

  include_context "with dangerfile"
  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:current_gitlab_version) { '18.0.0' }
  let(:fake_project_helper) { instance_double(Tooling::Danger::ProjectHelper) }
  let(:batched_background_checks) { fake_danger.new(helper: fake_helper) }

  describe '#ast_parser' do
    it 'creates an ASTParser instance' do
      file_content = 'class TestClass; end'
      parser = batched_background_checks.ast_parser(file_content)

      expect(parser).to be_a(Tooling::Danger::AstParser)
    end
  end

  describe '#find_migrations' do
    let(:changed_files) { [] }

    context 'when no batched background migration files are modified or deleted' do
      let(:changed_files) { ['app/models/user.rb'] }

      it 'returns early without processing' do
        expect(batched_background_checks).not_to receive(:find_class_or_module_names)
        batched_background_checks.find_migrations(changed_files)
      end
    end

    context 'when batched background migration files are modified or deleted' do
      let(:changed_files) { ['lib/gitlab/background_migration/alter_webhook_deleted_audit_event.rb'] }
      let(:migration_class_names) { { 'AlterWebhookDeletedAuditEvent' => changed_files.first } }

      before do
        allow(batched_background_checks).to receive(:find_class_or_module_names)
                                              .with(changed_files).and_return(migration_class_names)
      end

      context 'when there are no unremovable migrations' do
        let(:unremovable_migrations) do
          [[{
            batched_background_migration_file: changed_files.first,
            comment: described_class::MISSING_FINALIZED_MIGRATION
          }]]
        end

        before do
          allow(batched_background_checks).to receive(:find_unremovable_migrations)
                                                .with(migration_class_names).and_return(unremovable_migrations)
        end

        it 'displays unremovable migrations' do
          expect(batched_background_checks).to receive(:display_unremovable_migrations) do |migrations|
            expect(migrations.flatten.size).to eq(1)
            expect(migrations.flatten.first[:batched_background_migration_file]).to eq(changed_files.first)
            expect(migrations.flatten.first[:comment]).to eq(described_class::MISSING_FINALIZED_MIGRATION)
          end

          batched_background_checks.find_migrations(changed_files)
        end
      end

      context 'when all migrations can be removed' do
        before do
          allow(batched_background_checks).to receive(:find_unremovable_migrations)
                                                .with(migration_class_names).and_return([])
        end

        it 'does not display any errors' do
          expect(batched_background_checks).not_to receive(:display_unremovable_migrations)

          batched_background_checks.find_migrations(changed_files)
        end
      end
    end
  end

  describe '#find_class_or_module_names' do
    let(:temp_file) { Tempfile.new(['test_migration', '.rb']) }
    let(:ast_parser_instance) { instance_double(Tooling::Danger::AstParser) }

    before do
      allow(batched_background_checks).to receive(:ast_parser).and_return(ast_parser_instance)
      # Allow all file reads to happen normally by default
      allow(File).to receive(:read).and_call_original
    end

    after do
      temp_file.close
      temp_file.unlink
    end

    it 'extracts class names from Ruby files' do
      allow(File).to receive(:read).with(temp_file.path).and_return("file content")
      allow(ast_parser_instance).to receive(:extract_class_or_module_name).and_return('BackfillUserData')

      changed_files = [temp_file.path]
      result = batched_background_checks.find_class_or_module_names(changed_files)

      expect(result).to eq({ 'BackfillUserData' => temp_file.path })
    end

    it 'handles files without class definitions' do
      allow(File).to receive(:read).with(temp_file.path).and_return("file content")
      allow(ast_parser_instance).to receive(:extract_class_or_module_name).and_return(nil)

      changed_files = [temp_file.path]
      result = batched_background_checks.find_class_or_module_names(changed_files)

      expect(result).to be_empty
    end

    it 'handles file read errors gracefully' do
      nonexistent_file = '/nonexistent/file.rb'

      allow(File).to receive(:read).with(nonexistent_file).and_raise(StandardError.new("File not found"))

      changed_files = [nonexistent_file]
      result = batched_background_checks.find_class_or_module_names(changed_files)

      expect(result).to be_empty
    end
  end

  describe '#find_unremovable_migrations' do
    let(:migration_class_names) do
      { 'BackfillUserData' => 'lib/gitlab/background_migration/backfill_user_data.rb' }
    end

    let(:finalized_migrations) do
      { 'BackfillUserData' => 'lib/gitlab/background_migration/backfill_user_data.rb' }
    end

    let(:unremovable_migrations) do
      [{
        batched_background_migration_file: 'lib/gitlab/background_migration/backfill_user_data.rb',
        comment: described_class::MISSING_FINALIZED_MIGRATION
      }]
    end

    let(:bbms_and_finalized_files) do
      {
        'BackfillUserData' => [{
          batched_background_migration_file: 'lib/gitlab/background_migration/backfill_user_data.rb',
          finalized_migration_file: 'db/post_migrate/20240101000000_finalize_user_data_backfill.rb',
          finalized_migration_milestone: '17.2'
        }]
      }
    end

    let(:migrations_before_required_stop) do
      [{
        batched_background_migration_file: 'lib/gitlab/background_migration/backfill_user_data.rb',
        finalized_migration_file: 'db/post_migrate/20240101000000_finalize_user_data_backfill.rb',
        finalized_migration_milestone: '17.2',
        comment: described_class::BEFORE_NEXT_REQUIRED_STOP
      }]
    end

    context 'when there are migrations that have not been finalized yet' do
      before do
        allow(batched_background_checks).to receive(:categorize_batched_background_migrations)
                                              .with(migration_class_names).and_return([{}, unremovable_migrations])
      end

      it 'returns unremovable migrations' do
        result = batched_background_checks.find_unremovable_migrations(migration_class_names)

        expect(result).to eq([unremovable_migrations])
      end
    end

    context 'when there are finalized migrations that cannot be removed yet' do
      before do
        allow(batched_background_checks).to receive(:categorize_batched_background_migrations)
                                              .with(migration_class_names).and_return([finalized_migrations, []])
        allow(batched_background_checks).to receive(:find_finalized_migration_files)
                                              .with(finalized_migrations).and_return(bbms_and_finalized_files)
        allow(batched_background_checks).to receive(:find_unremovable_bbms)
                                              .with(bbms_and_finalized_files)
                                              .and_return(migrations_before_required_stop)
      end

      it 'returns migrations that cannot be removed before the required stops' do
        result = batched_background_checks.find_unremovable_migrations(migration_class_names)

        expect(result).to eq([migrations_before_required_stop])
      end
    end

    context 'when all migrations can be removed' do
      before do
        allow(batched_background_checks).to receive(:categorize_batched_background_migrations)
                                              .with(migration_class_names).and_return([finalized_migrations, []])
        allow(batched_background_checks).to receive(:find_finalized_migration_files)
                                              .with(finalized_migrations).and_return(bbms_and_finalized_files)
        allow(batched_background_checks).to receive(:find_unremovable_bbms)
                                              .with(bbms_and_finalized_files).and_return([])
      end

      it 'returns an empty array' do
        result = batched_background_checks.find_unremovable_migrations(migration_class_names)

        expect(result).to be_empty
      end
    end

    context 'when there is an error processing a milestone' do
      before do
        allow(batched_background_checks).to receive(:categorize_batched_background_migrations)
                                              .with(migration_class_names).and_return([finalized_migrations, []])
        allow(batched_background_checks).to receive(:find_finalized_migration_files)
                                              .with(finalized_migrations).and_return(bbms_and_finalized_files)

        allow(File).to receive(:read).and_call_original

        allow(File).to receive(:read).with('VERSION').and_return("unknown\n")

        allow(Gitlab::VersionInfo).to receive(:parse_from_milestone)
                                        .with('17.2')
                                        .and_raise(StandardError.new("Invalid milestone"))
      end

      it 'captures the error and adds the migration to unremovable migrations' do
        expect(batched_background_checks).to receive(:warn)
                                               .with("Failed to process milestone 17.2 for \
db/post_migrate/20240101000000_finalize_user_data_backfill.rb: Invalid milestone")

        result = batched_background_checks.find_unremovable_migrations(migration_class_names)

        expect(result).to eq([[{
          batched_background_migration_file: 'lib/gitlab/background_migration/backfill_user_data.rb',
          finalized_migration_file: 'db/post_migrate/20240101000000_finalize_user_data_backfill.rb',
          finalized_migration_milestone: '17.2',
          next_required_stop: "unknown",
          current_gitlab_version: "unknown",
          comment: "Error processing milestone: Invalid milestone"
        }]])
      end
    end
  end

  describe '#categorize_batched_background_migrations' do
    let(:migration_class_names) do
      {
        'BackfillUserData' => 'lib/gitlab/background_migration/backfill_user_data.rb',
        'ProcessOrders' => 'lib/gitlab/background_migration/process_orders.rb',
        'InvalidMigration' => 'lib/gitlab/background_migration/invalid_migration.rb'
      }
    end

    let(:temp_dir) { Dir.mktmpdir }
    let(:yaml_dir) { File.join(temp_dir, 'db/docs/batched_background_migrations') }

    before do
      FileUtils.mkdir_p(yaml_dir)
      stub_const("#{described_class}::DB_DOC_BBM_DIRECTORY", [yaml_dir])

      finalized_yaml = {
        'migration_job_name' => 'BackfillUserData',
        'finalized_by' => '20240101000000'
      }
      File.write(File.join(yaml_dir, 'backfill_user_data.yml'), finalized_yaml.to_yaml)

      unremovable_yaml = {
        'migration_job_name' => 'ProcessOrders',
        'finalized_by' => nil
      }
      File.write(File.join(yaml_dir, 'process_orders.yml'), unremovable_yaml.to_yaml)

      File.write(File.join(yaml_dir, 'invalid_migration.yml'), "{ invalid: yaml: content")
    end

    after do
      FileUtils.rm_rf(temp_dir)
    end

    it 'categorizes migrations correctly' do
      expect(batched_background_checks).to receive(:warn).with(/Failed to parse YAML file.*invalid_migration\.yml/)

      finalized, unremovable = batched_background_checks.categorize_batched_background_migrations(migration_class_names)

      expect(finalized).to eq({
        'BackfillUserData' => [{
          background_migration_class_name: 'lib/gitlab/background_migration/backfill_user_data.rb',
          finalized_migration_timestamp: '20240101000000'
        }]
      })

      expect(unremovable).to contain_exactly(
        hash_including(
          batched_background_migration_file: 'lib/gitlab/background_migration/process_orders.rb',
          comment: described_class::MISSING_FINALIZED_MIGRATION
        )
      )
    end

    it 'handles YAML parsing errors' do
      expect(batched_background_checks).to receive(:warn).with(/Failed to parse YAML file.*invalid_migration\.yml/)

      finalized, unremovable = batched_background_checks.categorize_batched_background_migrations(migration_class_names)

      expect(finalized).to have_key('BackfillUserData')
      expect(unremovable).not_to be_empty
    end
  end

  describe '#find_finalized_migration_files' do
    let(:finalized_migrations) do
      {
        'BackfillUserData' => [{
          background_migration_class_name: 'lib/gitlab/background_migration/backfill_user_data.rb',
          finalized_migration_timestamp: '20240101000000'
        }]
      }
    end

    let(:temp_dir) { Dir.mktmpdir }
    let(:post_migrate_dir) { File.join(temp_dir, 'db/post_migrate') }
    let(:invalid_migration_content) do
      "class InvalidMigration < Gitlab::Database::Migration[2.1]"
    end

    let(:finalized_migration_content) do
      <<~RUBY
        class FinalizeBackfillUserData < Gitlab::Database::Migration[2.1]
          milestone '17.2'

          def up
            ensure_batched_background_migration_is_finished(
              job_class_name: 'BackfillUserData',
              table_name: :users,
              column_name: :id
            )
          end
        end
      RUBY
    end

    before do
      FileUtils.mkdir_p(post_migrate_dir)
      stub_const("#{described_class}::POST_MIGRATE_DIRECTORIES", [post_migrate_dir])

      File.write(
        File.join(post_migrate_dir, '20240101000000_finalize_backfill_user_data.rb'),
        finalized_migration_content
      )
    end

    after do
      FileUtils.rm_rf(temp_dir)
    end

    it 'finds finalized migration files' do
      result = batched_background_checks.find_finalized_migration_files(finalized_migrations)

      expect(result).to have_key('BackfillUserData')
      expect(result['BackfillUserData']).to contain_exactly(
        hash_including(
          batched_background_migration_file: 'lib/gitlab/background_migration/backfill_user_data.rb',
          finalized_migration_file: File.join(post_migrate_dir,
            '20240101000000_finalize_backfill_user_data.rb'),
          finalized_migration_milestone: '17.2'
        )
      )
    end

    it 'returns empty hash when no finalized migrations are provided' do
      result = batched_background_checks.find_finalized_migration_files({})
      expect(result).to be_empty
    end

    it 'handles errors when processing files' do
      parser = instance_double(Tooling::Danger::AstParser)
      allow(parser).to receive(:has_ensure_batched_background_migration_is_finished_call?).and_raise(StandardError,
        "Parsing error")

      allow(batched_background_checks).to receive(:ast_parser).and_return(parser)

      expect(batched_background_checks).to receive(:warn).with(/Could not process file/)

      batched_background_checks.find_finalized_migration_files(finalized_migrations)
    end
  end

  describe '#find_unremovable_bbms' do
    let(:finalized_migrations) do
      {
        'BackfillUserData' => [{
          batched_background_migration_file: 'lib/gitlab/background_migration/backfill_user_data.rb',
          finalized_migration_file: 'db/post_migrate/20240101000000_finalize.rb',
          finalized_migration_milestone: '17.2'
        }]
      }
    end

    context 'when current version is before the required stop' do
      before do
        allow(batched_background_checks).to receive(:current_gitlab_version).and_return("17.0.0-pre")
      end

      it 'identifies migrations that cannot be removed yet' do
        result = batched_background_checks.find_unremovable_bbms(finalized_migrations)

        expect(result).to contain_exactly(
          hash_including(
            batched_background_migration_file: 'lib/gitlab/background_migration/backfill_user_data.rb',
            finalized_migration_file: 'db/post_migrate/20240101000000_finalize.rb',
            finalized_migration_milestone: '17.2',
            current_gitlab_version: '17.0.0-pre',
            next_required_stop: '17.2.0',
            comment: described_class::BEFORE_NEXT_REQUIRED_STOP
          )
        )
      end
    end

    context 'when current version is past the required stop' do
      before do
        allow(batched_background_checks).to receive(:current_gitlab_version).and_return("18.0.0-pre")
      end

      it 'allows removal when the current GitLab version is past the next required stop' do
        result = batched_background_checks.find_unremovable_bbms(finalized_migrations)
        expect(result).to be_empty
      end
    end

    it 'handles missing milestones' do
      finalized_migrations['BackfillUserData'][0][:finalized_migration_milestone] = nil

      result = batched_background_checks.find_unremovable_bbms(finalized_migrations)
      expect(result).to be_empty
    end
  end

  describe '#current_gitlab_version' do
    it 'reads and strips the VERSION file content' do
      version_content = "17.5.0-pre\n"

      allow(File).to receive(:read).and_call_original

      allow(File).to receive(:read).with('VERSION').and_return(version_content)

      expect(batched_background_checks.current_gitlab_version).to eq('17.5.0-pre')
    end
  end

  describe '#format_migration_message' do
    it 'formats basic migration messages' do
      migration = {
        batched_background_migration_file: 'lib/gitlab/background_migration/test.rb',
        comment: described_class::MISSING_FINALIZED_MIGRATION
      }

      result = batched_background_checks.format_migration_message(migration)

      expected = "**lib/gitlab/background_migration/test.rb**: " \
        "#{described_class::MISSING_FINALIZED_MIGRATION}"
      expect(result).to eq(expected)
    end

    it 'includes additional info for finalized migrations' do
      migration = {
        batched_background_migration_file: 'lib/gitlab/background_migration/test.rb',
        comment: described_class::BEFORE_NEXT_REQUIRED_STOP,
        finalized_migration_file: 'db/post_migrate/finalize.rb',
        finalized_migration_milestone: '17.2',
        current_gitlab_version: '17.1.0',
        next_required_stop: '17.5.0'
      }

      result = batched_background_checks.format_migration_message(migration)

      expected = "**lib/gitlab/background_migration/test.rb**: " \
        "#{described_class::BEFORE_NEXT_REQUIRED_STOP}"
      expect(result).to include(expected)
      expect(result).to include('Finalized migration: db/post_migrate/finalize.rb')
      expect(result).to include('Finalized migration milestone: 17.2')
      expect(result).to include('Current GitLab version: 17.1.0')
      expect(result).to include('Next required stop: 17.5.0')
    end
  end

  describe '#display_unremovable_migrations' do
    let(:unremovable_migrations) do
      [{
        batched_background_migration_file: 'lib/gitlab/background_migration/test.rb',
        comment: described_class::BEFORE_NEXT_REQUIRED_STOP,
        finalized_migration_file: 'db/post_migrate/finalize.rb',
        finalized_migration_milestone: '17.2',
        current_gitlab_version: '17.1.0',
        next_required_stop: '17.5.0'
      }]
    end

    it 'returns an empty array when migration code can be modified or deleted' do
      expect { batched_background_checks.display_unremovable_migrations([]) }.not_to raise_error
    end

    it 'fails with formatted error message' do
      expect(batched_background_checks).to receive(:warn)
                                             .with(a_string_including(described_class::BEFORE_NEXT_REQUIRED_STOP))

      batched_background_checks.display_unremovable_migrations(unremovable_migrations)
    end
  end
end
