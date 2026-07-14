# frozen_string_literal: true

require 'fast_spec_helper'
require 'tmpdir'
require 'fileutils'
require_relative '../../../scripts/lint/unused_scopes'

RSpec.describe Lint::UnusedScopes, feature_category: :tooling do
  let(:temp_dir) { Dir.mktmpdir }
  let(:excluded_scopes_path) { File.join(temp_dir, 'excluded_scopes.yml') }
  let(:potential_scopes_path) { File.join(temp_dir, 'potential_scopes_to_remove.yml') }

  let(:linter) do
    described_class.new(
      excluded_scopes_path: excluded_scopes_path,
      potential_scopes_path: potential_scopes_path
    )
  end

  before do
    # Create empty config files
    File.write(excluded_scopes_path, {}.to_yaml)
    File.write(potential_scopes_path, {}.to_yaml)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe '#file_extensions_glob' do
    it 'includes .rb files' do
      expect(linter.file_extensions_glob).to include('{ee/,}app/**/*.rb')
    end

    it 'includes .haml files' do
      expect(linter.file_extensions_glob).to include('{ee/,}app/**/*.haml')
    end

    it 'includes .erb files' do
      expect(linter.file_extensions_glob).to include('{ee/,}app/**/*.erb')
    end

    it 'includes .builder files' do
      expect(linter.file_extensions_glob).to include('{ee/,}app/**/*.builder')
    end

    it 'searches in app, config, gems, and lib directories' do
      globs = linter.file_extensions_glob

      expect(globs).to include('{ee/,}app/**/*.rb')
      expect(globs).to include('config/**/*.rb')
      expect(globs).to include('gems/**/*.rb')
      expect(globs).to include('{ee/,}lib/**/*.rb')
    end
  end

  describe 'EXTENSIONS constant' do
    it 'includes builder extension for Atom feed templates' do
      expect(described_class::EXTENSIONS).to include('builder')
    end

    it 'includes all expected extensions' do
      expect(described_class::EXTENSIONS).to contain_exactly('rb', 'haml', 'erb', 'builder')
    end
  end

  describe 'SCOPE_DEFINITION_PATTERNS constant' do
    subject(:pattern) { described_class::SCOPE_DEFINITION_PATTERNS }

    it 'matches app/models files' do
      expect(pattern).to match('app/models/user.rb')
    end

    it 'matches ee/app/models files' do
      expect(pattern).to match('ee/app/models/license.rb')
    end

    it 'matches app/models/concerns files' do
      expect(pattern).to match('app/models/concerns/issuable.rb')
    end

    it 'does not match app/helpers files' do
      expect(pattern).not_to match('app/helpers/application_helper.rb')
    end

    it 'does not match lib files' do
      expect(pattern).not_to match('lib/gitlab/database.rb')
    end
  end

  describe '#ee_directory_exists?' do
    context 'when ee directory exists' do
      before do
        allow(Dir).to receive(:exist?).with('ee').and_return(true)
      end

      it 'returns true' do
        expect(linter.ee_directory_exists?).to be true
      end
    end

    context 'when ee directory does not exist' do
      before do
        allow(Dir).to receive(:exist?).with('ee').and_return(false)
      end

      it 'returns false' do
        expect(linter.ee_directory_exists?).to be false
      end
    end
  end

  describe '#run' do
    context 'when ee directory does not exist' do
      before do
        allow(linter).to receive(:ee_directory_exists?).and_return(false)
      end

      it 'returns false and exits early' do
        expect(linter).not_to receive(:load_source_files)
        expect(linter.run).to be false
      end
    end

    context 'when ee directory exists' do
      before do
        allow(linter).to receive(:ee_directory_exists?).and_return(true)
        allow(Dir).to receive(:glob).and_return([])
      end

      it 'loads source files' do
        expect(linter).to receive(:load_source_files).and_call_original
        linter.run
      end
    end
  end

  describe 'scope definition detection' do
    let(:model_file) { 'app/models/user.rb' }

    before do
      allow(linter).to receive(:ee_directory_exists?).and_return(true)
    end

    describe 'single-line lambda syntax' do
      it 'detects scope :name, -> { }' do
        linter.instance_variable_set(:@source_files, {
          model_file => ["scope :active, -> { where(active: true) }\n"]
        })

        scopes = linter.send(:find_defined_scopes)

        expect(scopes).to include(a_hash_including(scope: 'active', file: model_file))
      end

      it 'detects scope :name, ->(arg) { }' do
        linter.instance_variable_set(:@source_files, {
          model_file => ["scope :by_status, ->(status) { where(status: status) }\n"]
        })

        scopes = linter.send(:find_defined_scopes)

        expect(scopes).to include(a_hash_including(scope: 'by_status', file: model_file))
      end
    end

    describe 'multi-line do/end syntax' do
      it 'detects scope :name, ->(arg) do' do
        linter.instance_variable_set(:@source_files, {
          model_file => [
            "scope :complex_query, ->(arg) do\n",
            "  where(foo: arg)\n",
            "end\n"
          ]
        })

        scopes = linter.send(:find_defined_scopes)

        expect(scopes).to include(a_hash_including(scope: 'complex_query', file: model_file))
      end

      it 'detects scope :name, -> do' do
        linter.instance_variable_set(:@source_files, {
          model_file => [
            "scope :all_active, -> do\n",
            "  where(active: true)\n",
            "end\n"
          ]
        })

        scopes = linter.send(:find_defined_scopes)

        expect(scopes).to include(a_hash_including(scope: 'all_active', file: model_file))
      end
    end

    describe 'edge cases' do
      it 'handles scope names with underscores' do
        linter.instance_variable_set(:@source_files, {
          model_file => ["scope :with_long_name_here, -> { all }\n"]
        })

        scopes = linter.send(:find_defined_scopes)

        expect(scopes).to include(a_hash_including(scope: 'with_long_name_here', file: model_file))
      end

      it 'handles scope names with numbers' do
        linter.instance_variable_set(:@source_files, {
          model_file => ["scope :version_2, -> { where(version: 2) }\n"]
        })

        scopes = linter.send(:find_defined_scopes)

        expect(scopes).to include(a_hash_including(scope: 'version_2', file: model_file))
      end

      it 'ignores default_scope' do
        linter.instance_variable_set(:@source_files, {
          model_file => ["default_scope { where(deleted: false) }\n"]
        })

        scopes = linter.send(:find_defined_scopes)

        expect(scopes).to be_empty
      end

      it 'ignores commented scope definitions' do
        linter.instance_variable_set(:@source_files, {
          model_file => ["# scope :old_scope, -> { all }\n"]
        })

        scopes = linter.send(:find_defined_scopes)

        expect(scopes).to be_empty
      end
    end

    describe 'multiple scopes in one file' do
      it 'detects all scopes' do
        linter.instance_variable_set(:@source_files, {
          model_file => [
            "scope :active, -> { where(active: true) }\n",
            "scope :inactive, -> { where(active: false) }\n",
            "scope :by_name, ->(name) { where(name: name) }\n"
          ]
        })

        scopes = linter.send(:find_defined_scopes)

        expect(scopes.map { |s| s[:scope] }).to contain_exactly('active', 'inactive', 'by_name')
      end
    end
  end

  describe 'scope usage detection' do
    let(:model_file) { 'app/models/user.rb' }
    let(:controller_file) { 'app/controllers/users_controller.rb' }

    before do
      allow(linter).to receive(:ee_directory_exists?).and_return(true)
    end

    describe '#build_usage_regex' do
      subject(:regex) { linter.send(:build_usage_regex, 'active') }

      it 'creates regex that matches scope calls', :aggregate_failures do
        expect(regex).to match('.active.')
        expect(regex).to match('User.active ')
        expect(regex).to match('.active.recent')
      end

      it 'does not match scope definitions' do
        expect(regex).not_to match('scope :active')
      end

      it 'does not match method definitions' do
        expect(regex).not_to match('def active')
      end

      it 'handles scope names that are substrings of other words', :aggregate_failures do
        # Should match .active followed by non-word character
        expect(regex).to match('.active.')
        expect(regex).to match('.active(')
        expect(regex).to match('.active ')
      end
    end

    describe 'finding unused scopes' do
      it 'marks scope as unused when no callers exist', :aggregate_failures do
        linter.instance_variable_set(:@source_files, {
          model_file => ["scope :orphaned, -> { all }\n"],
          controller_file => ["User.all\n"]
        })

        scopes = [{ scope: 'orphaned', file: model_file }]
        linter.send(:find_unused_scopes, scopes)

        expect(linter.unused_scope_collection[model_file]).to include('orphaned')
      end

      it 'does not mark scope as unused when callers exist', :aggregate_failures do
        linter.instance_variable_set(:@source_files, {
          model_file => ["scope :active, -> { where(active: true) }\n"],
          controller_file => ["User.active.first\n"]
        })

        scopes = [{ scope: 'active', file: model_file }]
        linter.send(:find_unused_scopes, scopes)

        expect(linter.unused_scope_collection[model_file]).not_to include('active')
      end

      it 'detects usage in chained scope calls' do
        linter.instance_variable_set(:@source_files, {
          model_file => [
            "scope :active, -> { where(active: true) }\n",
            "scope :recent, -> { order(created_at: :desc) }\n"
          ],
          controller_file => ["User.active.recent.first\n"]
        })

        scopes = [
          { scope: 'active', file: model_file },
          { scope: 'recent', file: model_file }
        ]
        linter.send(:find_unused_scopes, scopes)

        expect(linter.unused_scope_collection[model_file]).to be_empty
      end

      it 'detects usage in association lambdas' do
        linter.instance_variable_set(:@source_files, {
          model_file => ["scope :visible, -> { where(visible: true) }\n"],
          'app/models/project.rb' => ["has_many :users, -> { visible }\n"]
        })

        scopes = [{ scope: 'visible', file: model_file }]
        linter.send(:find_unused_scopes, scopes)

        expect(linter.unused_scope_collection[model_file]).not_to include('visible')
      end

      it 'detects usage via merge' do
        linter.instance_variable_set(:@source_files, {
          model_file => ["scope :active, -> { where(active: true) }\n"],
          controller_file => ["Project.joins(:users).merge(User.active)\n"]
        })

        scopes = [{ scope: 'active', file: model_file }]
        linter.send(:find_unused_scopes, scopes)

        expect(linter.unused_scope_collection[model_file]).not_to include('active')
      end
    end
  end

  describe 'excluded scopes filtering' do
    let(:model_file) { 'app/models/user.rb' }

    before do
      allow(linter).to receive(:ee_directory_exists?).and_return(true)
    end

    it 'filters out excluded scopes' do
      File.write(excluded_scopes_path, {
        model_file => [{ 'active' => 'Used via metaprogramming' }]
      }.to_yaml)

      scopes = [
        { scope: 'active', file: model_file },
        { scope: 'inactive', file: model_file }
      ]

      filtered = linter.send(:filter_excluded_scopes, scopes)

      expect(filtered.map { |s| s[:scope] }).to contain_exactly('inactive')
    end

    it 'returns all scopes when no exclusions file exists' do
      FileUtils.rm_f(excluded_scopes_path)

      scopes = [{ scope: 'active', file: model_file }]
      filtered = linter.send(:filter_excluded_scopes, scopes)

      expect(filtered).to eq(scopes)
    end
  end

  describe 'YAML output indentation' do
    describe '#print_full_report' do
      let(:start_time) { Process.clock_gettime(Process::CLOCK_MONOTONIC) }

      before do
        allow(linter).to receive(:ee_directory_exists?).and_return(true)
        linter.unused_scope_collection['app/models/user.rb'] = %w[scope_one scope_two]
        linter.unused_scope_collection['app/models/project.rb'] = ['another_scope']
      end

      it 'outputs YAML with properly indented list items' do
        expect { linter.send(:print_full_report, start_time) }
          .to output(/  - scope_one.*  - scope_two.*  - another_scope/m).to_stdout
      end

      it 'does not output unindented list items' do
        expect { linter.send(:print_full_report, start_time) }
          .not_to output(/\n-\s+\S/).to_stdout
      end
    end

    describe '#print_new_unused_scopes' do
      before do
        linter.instance_variable_set(:@new_unused_scopes, [
          ['app/models/user.rb', 'unused_scope'],
          ['app/models/user.rb', 'another_unused']
        ])
      end

      it 'outputs YAML with properly indented list items' do
        expect { linter.send(:print_new_unused_scopes) }
          .to output(/  - unused_scope.*  - another_unused/m).to_stdout
      end
    end

    describe '#print_removed_scopes' do
      before do
        linter.instance_variable_set(:@removed_scopes, [
          ['app/models/project.rb', 'removed_scope'],
          ['app/models/project.rb', 'another_removed']
        ])
      end

      it 'outputs YAML with properly indented list items' do
        expect { linter.send(:print_removed_scopes) }
          .to output(/  - removed_scope.*  - another_removed/m).to_stdout
      end
    end
  end

  describe 'diff comparison' do
    let(:model_file) { 'app/models/user.rb' }

    before do
      allow(linter).to receive(:ee_directory_exists?).and_return(true)
    end

    it 'identifies newly unused scopes' do
      File.write(potential_scopes_path, {
        model_file => ['old_unused']
      }.to_yaml)

      linter.unused_scope_collection[model_file] = %w[old_unused new_unused]
      linter.send(:compare_with_known_scopes)

      expect(linter.new_unused_scopes).to include([model_file, 'new_unused'])
    end

    it 'identifies removed scopes' do
      File.write(potential_scopes_path, {
        model_file => %w[was_unused now_used]
      }.to_yaml)

      linter.unused_scope_collection[model_file] = ['was_unused']
      linter.send(:compare_with_known_scopes)

      expect(linter.removed_scopes).to include([model_file, 'now_used'])
    end
  end

  describe 'UPDATE_YAML functionality' do
    let(:model_file) { 'app/models/user.rb' }

    before do
      allow(linter).to receive(:ee_directory_exists?).and_return(true)
      allow(Dir).to receive(:glob).and_return([model_file])
      allow(File).to receive(:readlines).with(model_file).and_return([
        "scope :unused_one, -> { where(active: true) }\n",
        "scope :unused_two, -> { where(active: false) }\n"
      ])
    end

    describe '#write_potential_scopes_file' do
      it 'writes unused scopes to the YAML file' do
        linter.unused_scope_collection[model_file] = %w[unused_one unused_two]

        expect(File).to receive(:write).with(
          potential_scopes_path,
          a_string_including('unused_one', 'unused_two')
        )

        expect { linter.send(:write_potential_scopes_file) }.to output.to_stdout
      end

      it 'does not write if no unused scopes found' do
        expect(File).not_to receive(:write)

        linter.send(:write_potential_scopes_file)
      end

      it 'outputs success message when writing', :aggregate_failures do
        linter.unused_scope_collection[model_file] = %w[unused_one]
        allow(File).to receive(:write)

        expect { linter.send(:write_potential_scopes_file) }
          .to output(/Updated.*potential_scopes_to_remove\.yml/).to_stdout
      end
    end

    describe '#run with update_yaml: true' do
      it 'writes to YAML file when print_report and update_yaml are true' do
        expect(linter).to receive(:write_potential_scopes_file)

        expect { linter.run(print_report: true, update_yaml: true) }.to output.to_stdout
      end

      it 'does not write to YAML file when update_yaml is false' do
        expect(linter).not_to receive(:write_potential_scopes_file)

        expect { linter.run(print_report: true, update_yaml: false) }.to output.to_stdout
      end

      it 'does not write to YAML file when print_report is false' do
        File.write(potential_scopes_path, {}.to_yaml)
        expect(linter).not_to receive(:write_potential_scopes_file)

        linter.run(print_report: false, update_yaml: true)
      end
    end
  end
end
