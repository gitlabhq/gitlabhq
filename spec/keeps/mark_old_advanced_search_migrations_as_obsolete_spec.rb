# frozen_string_literal: true

require 'spec_helper'
require './keeps/mark_old_advanced_search_migrations_as_obsolete'

RSpec.describe Keeps::MarkOldAdvancedSearchMigrationsAsObsolete, feature_category: :global_search do
  let(:groups) do
    {
      foo: {
        label: 'group::global search',
        engineers: %w[@john_doe @jane_doe],
        backend_engineers: ['@john_doe'],
        frontend_engineers: ['@jane_doe']
      }
    }
  end

  let(:tmp_dir) { Pathname(Dir.mktmpdir) }
  let(:migration_version) { '20231130202203' }
  let(:migration_name) { 'ReindexIssueToUpdateAnalyzer' }
  let(:migration_milestone) { '15.8' }
  let(:cutoff_milestone) { '16.0' }

  let(:migration_file) do
    file_path = tmp_dir.join(described_class::MIGRATIONS_PATH, "#{migration_version}_#{migration_name.underscore}.rb")
    FileUtils.mkdir_p(File.dirname(file_path))

    File.write(file_path, <<~RUBY)
      # frozen_string_literal: true

      class #{migration_name} < Elastic::Migration
        def migrate
          # migration logic
        end
      end
    RUBY

    file_path.to_s
  end

  let(:yaml_file) do
    file_path = tmp_dir.join(
      described_class::MIGRATION_DOCS_PATH,
      "#{migration_version}_#{migration_name.underscore}.yml"
    )
    FileUtils.mkdir_p(File.dirname(file_path))

    File.write(file_path, {
      'name' => migration_name,
      'version' => migration_version,
      'milestone' => migration_milestone,
      'group' => groups.dig(:foo, :label)
    }.to_yaml)

    file_path.to_s
  end

  let(:spec_file) do
    file_path = tmp_dir.join(
      described_class::MIGRATIONS_SPECS_PATH,
      "#{migration_version}_#{migration_name.underscore}_spec.rb"
    )
    FileUtils.mkdir_p(File.dirname(file_path))

    File.write(file_path, <<~RUBY)
      # frozen_string_literal: true

      require 'spec_helper'

      RSpec.describe #{migration_name}, feature_category: :global_search do
        it 'does something' do
          expect(true).to be true
        end
      end
    RUBY

    file_path.to_s
  end

  let(:keep) do
    # Stub load_migrations_to_process before creating the instance
    # rubocop:disable RSpec/AnyInstanceOf -- Need to stub initializer behavior
    allow_any_instance_of(described_class).to receive(:load_migrations_to_process)
    # rubocop:enable RSpec/AnyInstanceOf
    described_class.new
  end

  before do
    # Load the Groups helper to ensure the constant is available
    require './keeps/helpers/groups'
    stub_request(:get, Keeps::Helpers::Groups::GROUPS_JSON_URL).to_return(status: 200, body: groups.to_json)

    # Stub the VERSION file
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with('VERSION').and_return('16.5.0')

    keeps_groups_helper = instance_double(Keeps::Helpers::Groups, group_for_group_label: groups[:foo].to_json,
      available_reviewers_for_group: groups.dig(:foo, :backend_engineers))

    allow(Keeps::Helpers::Groups).to receive(:instance).and_return(keeps_groups_helper)
  end

  after do
    FileUtils.rm_rf(tmp_dir)
  end

  describe '#each_identified_change' do
    before do
      # Create the test files
      migration_file
      yaml_file
      spec_file

      # Set cutoff milestone
      allow(keep).to receive(:cutoff_milestone).and_return(Gitlab::VersionInfo.new(16, 0, 0))

      # Stub each_advanced_search_migration to yield the test files
      allow(keep).to receive(:each_advanced_search_migration).and_yield(
        migration_file,
        spec_file,
        yaml_file,
        YAML.load_file(yaml_file)
      )

      # Allow load_migrations_to_process to run with the stubbed method
      allow(keep).to receive(:load_migrations_to_process).and_call_original

      # Manually load migrations for this test
      keep.send(:load_migrations_to_process)
    end

    it 'yields a change for migrations before the cutoff milestone' do
      changes = []
      keep.each_identified_change { |change| changes << change }

      expect(changes.size).to eq(1)
      expect(changes.first.title).to eq("Mark #{migration_version} as obsolete")
      expect(changes.first.identifiers).to eq(['mark_obsolete', migration_version, migration_name])
    end

    it 'sets the correct labels on the change' do
      changes = []
      keep.each_identified_change { |change| changes << change }

      expect(changes.first.labels).to include('maintenance::refactor', groups.dig(:foo, :label))
    end

    it 'includes a comprehensive description' do
      changes = []
      keep.each_identified_change { |change| changes << change }

      description = changes.first.description
      expect(description).to include("marks the #{migration_version} #{migration_name}")
      expect(description).to include('migration_has_finished?')
      expect(description).to include(migration_name.underscore)
      expect(description).to include('Review Checklist')
    end

    context 'when migration is already obsolete' do
      before do
        yaml_content = YAML.load_file(yaml_file)
        yaml_content['obsolete'] = true
        File.write(yaml_file, yaml_content.to_yaml)

        # Clear existing migrations and reload with the updated YAML
        keep.instance_variable_set(:@migrations_to_be_marked_obsolete, {})
        allow(keep).to receive(:each_advanced_search_migration).and_yield(
          migration_file,
          spec_file,
          yaml_file,
          YAML.load_file(yaml_file)
        )
        keep.send(:load_migrations_to_process)
      end

      it 'does not yield a change' do
        changes = []
        keep.each_identified_change { |change| changes << change }

        expect(changes).to be_empty
      end
    end

    context 'when migration is after the cutoff milestone' do
      let(:migration_milestone) { '16.1' }

      it 'does not yield a change' do
        changes = []
        keep.each_identified_change { |change| changes << change }

        expect(changes).to be_empty
      end
    end
  end

  describe '#make_change!' do
    let(:change) { ::Gitlab::Housekeeper::Change.new }

    let(:migration_data) do
      {
        file: migration_file,
        spec_file: spec_file,
        yaml_filename: yaml_file,
        yaml_content: YAML.load_file(yaml_file)
      }
    end

    before do
      change.context = { version: migration_version, migration_data: migration_data }
      allow(keep).to receive(:ai_patch).and_return(true)
    end

    it 'updates the YAML file with obsolete flag' do
      keep.make_change!(change)

      yaml_content = YAML.load_file(yaml_file)
      expect(yaml_content['obsolete']).to be true
      expect(yaml_content['marked_obsolete_in_milestone']).to eq('16.5')
    end

    it 'adds prepend statement to migration file' do
      keep.make_change!(change)

      migration_content = File.read(migration_file)
      expect(migration_content).to include("#{migration_name}.prepend ::Search::Elastic::MigrationObsolete")
    end

    it 'updates the spec file with deprecated shared example' do
      keep.make_change!(change)

      spec_content = File.read(spec_file)
      expect(spec_content).to include("it_behaves_like 'a deprecated Advanced Search migration', #{migration_version}")
    end

    it 'includes all changed files in the change object' do
      keep.make_change!(change)

      expect(change.changed_files).to include(yaml_file, migration_file, spec_file)
    end

    it 'calls ai_patch to clean up references' do
      expect(keep).to receive(:ai_patch).with(migration_data, change).and_return(true)

      keep.make_change!(change)
    end

    context 'when spec file does not exist' do
      before do
        FileUtils.rm_f(spec_file)
      end

      it 'does not include spec file in changed files' do
        keep.make_change!(change)

        expect(change.changed_files).not_to include(spec_file)
      end
    end

    context 'when ai_patch returns false' do
      let(:logger) { instance_double(Gitlab::Housekeeper::Logger).as_null_object }

      before do
        allow(keep).to receive(:ai_patch).and_return(false)
        keep.instance_variable_set(:@logger, logger)
      end

      it 'logs a warning but continues' do
        expect(logger).to receive(:puts).with(/Warning: AI patching was not fully successful/)

        keep.make_change!(change)
      end

      it 'still completes the manual changes' do
        keep.make_change!(change)

        yaml_content = YAML.load_file(yaml_file)
        expect(yaml_content['obsolete']).to be true
      end
    end
  end

  describe '#ai_patch' do
    let(:migration_data) do
      # Ensure files are created before loading yaml
      migration_file
      spec_file
      yaml_file

      {
        file: migration_file,
        spec_file: spec_file,
        yaml_filename: yaml_file,
        yaml_content: YAML.load_file(yaml_file)
      }
    end

    let(:change) { ::Gitlab::Housekeeper::Change.new }
    let(:ai_helper) { instance_double(Keeps::Helpers::AiEditor) }
    let(:prompt_generator) { instance_double(Keeps::Prompts::RemoveObsoleteMigrations) }
    let(:logger) { instance_double(Gitlab::Housekeeper::Logger).as_null_object }

    before do
      change.changed_files = []
      allow(keep).to receive_messages(
        ai_helper: ai_helper,
        remove_obsolete_migration_prompts: prompt_generator,
        files_mentioning_migration: []
      )
      keep.instance_variable_set(:@logger, logger)
    end

    context 'when no files mention the migration' do
      it 'returns true' do
        result = keep.send(:ai_patch, migration_data, change)

        expect(result).to be true
      end

      it 'logs that no files were found' do
        expect(logger).to receive(:puts).with(/No additional files found/)

        keep.send(:ai_patch, migration_data, change)
      end
    end

    context 'when files mention the migration' do
      let(:reference_file) { tmp_dir.join('app/services/search_service.rb').to_s }

      before do
        FileUtils.mkdir_p(File.dirname(reference_file))
        File.write(reference_file, <<~RUBY)
          class SearchService
            def search
              if ::Elastic::DataMigrationService.migration_has_finished?(:#{migration_name.underscore})
                # new code
              else
                # old code
              end
            end
          end
        RUBY

        allow(keep).to receive(:files_mentioning_migration)
          .and_return([reference_file])
      end

      it 'generates prompts for each file' do
        expect(prompt_generator).to receive(:fetch)
          .with(migration_name, migration_name.underscore, reference_file)
          .and_return('prompt text')

        allow(ai_helper).to receive(:ask_for_and_apply_patch).and_return(true)
        allow(::Gitlab::Housekeeper::Shell).to receive(:rubocop_autocorrect)

        keep.send(:ai_patch, migration_data, change)
      end

      it 'applies AI patches to each file' do
        allow(prompt_generator).to receive(:fetch).and_return('prompt text')
        expect(ai_helper).to receive(:ask_for_and_apply_patch)
          .with('prompt text', reference_file)
          .and_return(true)

        allow(::Gitlab::Housekeeper::Shell).to receive(:rubocop_autocorrect)

        keep.send(:ai_patch, migration_data, change)
      end

      it 'runs rubocop autocorrect on Ruby files' do
        allow(prompt_generator).to receive(:fetch).and_return('prompt text')
        allow(ai_helper).to receive(:ask_for_and_apply_patch).and_return(true)

        expect(::Gitlab::Housekeeper::Shell).to receive(:rubocop_autocorrect)
          .with(reference_file)

        keep.send(:ai_patch, migration_data, change)
      end

      it 'adds successfully patched files to changed_files' do
        allow(prompt_generator).to receive(:fetch).and_return('prompt text')
        allow(ai_helper).to receive(:ask_for_and_apply_patch).and_return(true)
        allow(::Gitlab::Housekeeper::Shell).to receive(:rubocop_autocorrect)

        keep.send(:ai_patch, migration_data, change)

        expect(change.changed_files).to include(reference_file)
      end

      context 'when AI patch fails' do
        before do
          allow(prompt_generator).to receive(:fetch).and_return('prompt text')
          allow(ai_helper).to receive(:ask_for_and_apply_patch).and_return(false)
        end

        it 'returns false' do
          result = keep.send(:ai_patch, migration_data, change)

          expect(result).to be false
        end

        it 'does not add the file to changed_files' do
          keep.send(:ai_patch, migration_data, change)

          expect(change.changed_files).not_to include(reference_file)
        end

        it 'logs the failure' do
          expect(logger).to receive(:puts).with(/Failed to apply AI patch/)

          keep.send(:ai_patch, migration_data, change)
        end
      end

      context 'when rubocop fails' do
        before do
          allow(prompt_generator).to receive(:fetch).and_return('prompt text')
          allow(ai_helper).to receive(:ask_for_and_apply_patch).and_return(true)
          allow(::Gitlab::Housekeeper::Shell).to receive(:rubocop_autocorrect)
            .and_raise(::Gitlab::Housekeeper::Shell::Error.new('rubocop error'))
        end

        it 'logs the error but continues' do
          expect(logger).to receive(:puts).with(/Rubocop error/)

          keep.send(:ai_patch, migration_data, change)
        end

        it 'still adds the file to changed_files' do
          keep.send(:ai_patch, migration_data, change)

          expect(change.changed_files).to include(reference_file)
        end
      end

      context 'when file is markdown' do
        let(:reference_file) { tmp_dir.join('doc/development/search.md').to_s }

        before do
          FileUtils.mkdir_p(File.dirname(reference_file))
          File.write(reference_file, "# Search\nReferences #{migration_name}")

          allow(keep).to receive(:files_mentioning_migration).and_return([reference_file])
          allow(prompt_generator).to receive(:fetch).and_return('prompt text')
          allow(ai_helper).to receive(:ask_for_and_apply_patch).and_return(true)
        end

        it 'does not run rubocop on markdown files' do
          expect(::Gitlab::Housekeeper::Shell).not_to receive(:rubocop_autocorrect)

          keep.send(:ai_patch, migration_data, change)
        end
      end
    end

    context 'when too many files mention the migration' do
      before do
        files = (1..60).map { |i| "file_#{i}.rb" }
        allow(keep).to receive(:files_mentioning_migration).and_return(files)
      end

      it 'returns false' do
        result = keep.send(:ai_patch, migration_data, change)

        expect(result).to be false
      end

      it 'logs that there are too many files' do
        expect(logger).to receive(:puts).with(/More than #{described_class::MAX_FILES_LIMIT}/o)

        keep.send(:ai_patch, migration_data, change)
      end

      it 'does not attempt to patch any files' do
        expect(ai_helper).not_to receive(:ask_for_and_apply_patch)

        keep.send(:ai_patch, migration_data, change)
      end
    end

    context 'when files include the migration files themselves' do
      before do
        allow(keep).to receive(:files_mentioning_migration)
          .and_return([migration_file, spec_file, yaml_file, 'other_file.rb'])
      end

      it 'excludes migration, spec, and yaml files from patching' do
        # Should only generate prompt for 'other_file.rb'
        expect(prompt_generator).to receive(:fetch).once
          .with(migration_name, migration_name.underscore, 'other_file.rb')
          .and_return(nil)

        keep.send(:ai_patch, migration_data, change)
      end
    end
  end

  describe '#git_patterns' do
    it 'returns patterns for class name, snake_case, migration check, and version' do
      patterns = keep.send(:git_patterns, migration_name, migration_version)

      expect(patterns).to include(migration_name)
      expect(patterns).to include(migration_name.underscore)
      expect(patterns).to include("migration_has_finished?(:#{migration_name.underscore})")
      expect(patterns).to include(migration_version)
    end
  end

  describe '#files_mentioning_migration' do
    before do
      allow(keep).to receive(:find_files_with_pattern).and_return([])
    end

    it 'searches for all patterns' do
      patterns = [
        migration_name,
        migration_name.underscore,
        "migration_has_finished?(:#{migration_name.underscore})",
        migration_version
      ]

      patterns.each do |pattern|
        expect(keep).to receive(:find_files_with_pattern).with(pattern).and_return([])
      end

      keep.send(:files_mentioning_migration, migration_name, migration_version)
    end

    it 'returns unique files' do
      allow(keep).to receive(:find_files_with_pattern)
        .with(migration_name).and_return(['file1.rb', 'file2.rb'])
      allow(keep).to receive(:find_files_with_pattern)
        .with(migration_name.underscore).and_return(['file2.rb', 'file3.rb'])
      allow(keep).to receive(:find_files_with_pattern)
        .with("migration_has_finished?(:#{migration_name.underscore})").and_return(['file1.rb'])
      allow(keep).to receive(:find_files_with_pattern)
        .with(migration_version).and_return([])

      files = keep.send(:files_mentioning_migration, migration_name, migration_version)

      expect(files).to match_array(['file1.rb', 'file2.rb', 'file3.rb'])
    end
  end

  describe '#find_files_with_pattern' do
    before do
      allow(keep).to receive(:execute_grep).and_return("")
    end

    it 'calls execute_grep with the pattern' do
      expect(keep).to receive(:execute_grep).with('test_pattern')

      keep.send(:find_files_with_pattern, 'test_pattern')
    end

    it 'returns an array of files' do
      allow(keep).to receive(:execute_grep).and_return("file1.rb\nfile2.rb\nfile3.rb")

      files = keep.send(:find_files_with_pattern, 'test_pattern')

      expect(files).to eq(['file1.rb', 'file2.rb', 'file3.rb'])
    end

    it 'returns empty array when no files found' do
      allow(keep).to receive(:execute_grep).and_return("")

      files = keep.send(:find_files_with_pattern, 'test_pattern')

      expect(files).to eq([])
    end

    context 'when git grep raises an error' do
      let(:logger) { instance_double(Gitlab::Housekeeper::Logger).as_null_object }

      before do
        allow(keep).to receive(:execute_grep).and_raise(::Gitlab::Housekeeper::Shell::Error.new('error'))
        keep.instance_variable_set(:@logger, logger)
      end

      it 'returns empty array' do
        files = keep.send(:find_files_with_pattern, 'test_pattern')

        expect(files).to eq([])
      end

      it 'logs the error' do
        expect(logger).to receive(:puts).with(/No files found for pattern/)

        keep.send(:find_files_with_pattern, 'test_pattern')
      end
    end
  end

  describe '#execute_grep' do
    it 'calls git grep with the pattern and ignore paths' do
      expect(::Gitlab::Housekeeper::Shell).to receive(:execute)
        .with('git', 'grep', '--name-only', 'test_pattern', '--', ':^locale/', ':^db/structure.sql')

      keep.send(:execute_grep, 'test_pattern')
    end

    it 'returns empty string when git grep finds nothing' do
      allow(::Gitlab::Housekeeper::Shell).to receive(:execute)
        .and_raise(::Gitlab::Housekeeper::Shell::Error.new('error'))

      result = keep.send(:execute_grep, 'test_pattern')

      expect(result).to eq("")
    end
  end

  describe '#before_cutoff_milestone?' do
    it 'returns true when milestone is before cutoff' do
      allow(keep).to receive(:cutoff_milestone).and_return(Gitlab::VersionInfo.new(16, 0, 0))

      expect(keep.send(:before_cutoff_milestone?, '15.8')).to be true
    end

    it 'returns false when milestone is at cutoff' do
      allow(keep).to receive(:cutoff_milestone).and_return(Gitlab::VersionInfo.new(16, 0, 0))

      expect(keep.send(:before_cutoff_milestone?, '16.0')).to be false
    end

    it 'returns false when milestone is after cutoff' do
      allow(keep).to receive(:cutoff_milestone).and_return(Gitlab::VersionInfo.new(16, 0, 0))

      expect(keep.send(:before_cutoff_milestone?, '16.1')).to be false
    end
  end

  describe '#ai_helper' do
    it 'returns an instance of AiEditor' do
      stub_env('ANTHROPIC_API_KEY', 'fake-api-key')

      helper = keep.send(:ai_helper)

      expect(helper).to be_a(Keeps::Helpers::AiEditor)
    end
  end

  describe '#remove_obsolete_migration_prompts' do
    it 'returns an instance of RemoveObsoleteMigrations' do
      prompts = keep.send(:remove_obsolete_migration_prompts)

      expect(prompts).to be_a(Keeps::Prompts::RemoveObsoleteMigrations)
    end

    it 'memoizes the instance' do
      prompts1 = keep.send(:remove_obsolete_migration_prompts)
      prompts2 = keep.send(:remove_obsolete_migration_prompts)

      expect(prompts1).to be(prompts2)
    end
  end
end
