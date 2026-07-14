# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../scripts/lint/unused_code'

RSpec.describe Lint::UnusedCode, feature_category: :tooling do
  describe 'STRATEGIES constant' do
    it 'defines methods strategy' do
      expect(described_class::STRATEGIES).to have_key(:methods)
    end

    it 'defines scopes strategy' do
      expect(described_class::STRATEGIES).to have_key(:scopes)
    end

    described_class::STRATEGIES.each do |type, strategy|
      context "for #{type} strategy" do
        it 'has all required keys', :aggregate_failures do
          expect(strategy).to have_key(:name)
          expect(strategy).to have_key(:excluded_path)
          expect(strategy).to have_key(:potential_path)
          expect(strategy).to have_key(:definition_patterns)
          expect(strategy).to have_key(:definition_regex)
          expect(strategy).to have_key(:usage_regex)
          expect(strategy).to have_key(:skip_commented)
        end

        it 'has callable definition_regex' do
          expect(strategy[:definition_regex]).to respond_to(:call)
        end

        it 'has callable usage_regex' do
          expect(strategy[:usage_regex]).to respond_to(:call)
        end
      end
    end
  end

  describe '#initialize' do
    it 'accepts :methods type' do
      expect { described_class.new(type: :methods) }.not_to raise_error
    end

    it 'accepts :scopes type' do
      expect { described_class.new(type: :scopes) }.not_to raise_error
    end

    it 'raises for unknown type' do
      expect { described_class.new(type: :unknown) }.to raise_error(ArgumentError, /Unknown type/)
    end
  end

  describe 'methods strategy' do
    let(:strategy) { described_class::STRATEGIES[:methods] }
    let(:definition_regex) { strategy[:definition_regex] }
    let(:usage_regex) { strategy[:usage_regex] }

    describe 'definition_regex' do
      it 'matches simple method definitions' do
        expect(definition_regex.call('def foo')).to eq('foo')
      end

      it 'matches method definitions with arguments' do
        expect(definition_regex.call('def bar(arg)')).to eq('bar')
      end

      it 'matches predicate methods' do
        expect(definition_regex.call('def valid?')).to eq('valid?')
      end

      it 'matches bang methods' do
        expect(definition_regex.call('def save!')).to eq('save!')
      end

      it 'matches class methods' do
        expect(definition_regex.call('def self.create')).to eq('self.create')
      end

      it 'matches setter methods' do
        expect(definition_regex.call('def name=(value)')).to eq('name=')
      end

      it 'does not match scope definitions' do
        expect(definition_regex.call('scope :active, -> { }')).to be_nil
      end

      it 'does not match non-method lines' do
        expect(definition_regex.call('puts "hello"')).to be_nil
      end
    end

    describe 'usage_regex' do
      it 'matches method calls', :aggregate_failures do
        regex = usage_regex.call('foo')
        expect(regex).to match('obj.foo ')
        expect(regex).to match('foo(arg)')
      end

      it 'does not match method definitions' do
        regex = usage_regex.call('foo')
        expect(regex).not_to match('def foo')
      end

      it 'handles setter methods', :aggregate_failures do
        regex = usage_regex.call('name=')
        expect(regex).to match('obj.name = value')
        expect(regex).to match('self.name=value')
      end

      it 'handles self. prefix in definition' do
        regex = usage_regex.call('self.create')
        expect(regex).to match('Model.create(')
      end
    end

    describe 'definition_patterns' do
      subject(:pattern) { strategy[:definition_patterns] }

      it 'matches app/helpers files' do
        expect(pattern).to match('app/helpers/application_helper.rb')
      end

      it 'matches app/models files' do
        expect(pattern).to match('app/models/user.rb')
      end

      it 'matches ee/app/helpers files' do
        expect(pattern).to match('ee/app/helpers/ee_helper.rb')
      end

      it 'matches ee/app/models files' do
        expect(pattern).to match('ee/app/models/license.rb')
      end

      it 'does not match app/controllers files' do
        expect(pattern).not_to match('app/controllers/application_controller.rb')
      end

      it 'does not match lib files' do
        expect(pattern).not_to match('lib/gitlab/utils.rb')
      end
    end

    it 'does not skip commented lines' do
      expect(strategy[:skip_commented]).to be false
    end
  end

  describe 'scopes strategy' do
    let(:strategy) { described_class::STRATEGIES[:scopes] }
    let(:definition_regex) { strategy[:definition_regex] }
    let(:usage_regex) { strategy[:usage_regex] }

    describe 'definition_regex' do
      it 'matches single-line scope definitions' do
        expect(definition_regex.call('scope :active, -> { where(active: true) }')).to eq('active')
      end

      it 'matches scope definitions with arguments' do
        expect(definition_regex.call('scope :by_status, ->(status) { where(status: status) }')).to eq('by_status')
      end

      it 'matches multi-line scope definitions' do
        expect(definition_regex.call('scope :complex, ->(arg) do')).to eq('complex')
      end

      it 'matches scope names with underscores' do
        expect(definition_regex.call('scope :with_long_name, -> { }')).to eq('with_long_name')
      end

      it 'matches scope names with numbers' do
        expect(definition_regex.call('scope :version_2, -> { }')).to eq('version_2')
      end

      it 'does not match default_scope' do
        expect(definition_regex.call('default_scope { where(deleted: false) }')).to be_nil
      end

      it 'does not match method definitions' do
        expect(definition_regex.call('def active')).to be_nil
      end
    end

    describe 'usage_regex' do
      it 'matches scope calls', :aggregate_failures do
        regex = usage_regex.call('active')
        expect(regex).to match('.active.')
        expect(regex).to match('User.active ')
        expect(regex).to match('.active(')
      end

      it 'does not match scope definitions' do
        regex = usage_regex.call('active')
        expect(regex).not_to match('scope :active')
      end

      it 'does not match method definitions' do
        regex = usage_regex.call('active')
        expect(regex).not_to match('def active')
      end
    end

    describe 'definition_patterns' do
      subject(:pattern) { strategy[:definition_patterns] }

      it 'matches app/models files' do
        expect(pattern).to match('app/models/user.rb')
      end

      it 'matches app/models/concerns files' do
        expect(pattern).to match('app/models/concerns/issuable.rb')
      end

      it 'matches ee/app/models files' do
        expect(pattern).to match('ee/app/models/license.rb')
      end

      it 'does not match app/helpers files' do
        expect(pattern).not_to match('app/helpers/application_helper.rb')
      end

      it 'does not match lib files' do
        expect(pattern).not_to match('lib/gitlab/database.rb')
      end
    end

    it 'skips commented lines' do
      expect(strategy[:skip_commented]).to be true
    end
  end

  describe '#file_extensions_glob' do
    let(:linter) { described_class.new(type: :methods) }

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

    it 'searches in app, config, gems, and lib directories', :aggregate_failures do
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

  describe '#ee_directory_exists?' do
    let(:linter) { described_class.new(type: :methods) }

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
    let(:linter) { described_class.new(type: :methods) }

    context 'when ee directory does not exist' do
      before do
        allow(linter).to receive(:ee_directory_exists?).and_return(false)
      end

      it 'returns true and exits early without failure', :aggregate_failures do
        expect(linter).not_to receive(:load_source_files)
        expect(linter.run).to be true
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

    context 'in diff mode (default)' do
      before do
        allow(linter).to receive(:ee_directory_exists?).and_return(true)
        allow(Dir).to receive(:glob).and_return([])
        allow(linter).to receive(:print_diff_report)
      end

      it 'returns true when current scan matches baseline' do
        allow(linter).to receive(:compare_with_known) do
          linter.instance_variable_set(:@new_unused, [])
          linter.instance_variable_set(:@removed, [])
        end

        expect(linter.run).to be true
      end

      it 'returns false when new unused code is detected' do
        allow(linter).to receive(:compare_with_known) do
          linter.instance_variable_set(:@new_unused, [['file.rb', 'method_name']])
          linter.instance_variable_set(:@removed, [])
        end

        expect(linter.run).to be false
      end

      it 'returns false when previously unused code was removed' do
        allow(linter).to receive(:compare_with_known) do
          linter.instance_variable_set(:@new_unused, [])
          linter.instance_variable_set(:@removed, [['file.rb', 'old_method']])
        end

        expect(linter.run).to be false
      end
    end
  end

  describe 'commented line handling' do
    let(:model_file) { 'app/models/user.rb' }

    context 'with methods strategy' do
      let(:linter) { described_class.new(type: :methods) }

      before do
        allow(linter).to receive(:ee_directory_exists?).and_return(true)
      end

      it 'includes methods from commented lines (does not skip)' do
        linter.instance_variable_set(:@source_files, {
          model_file => ["# def old_method\n", "def active_method\n"]
        })

        definitions = linter.send(:find_definitions)

        # Methods strategy does NOT skip commented lines (matches existing behavior)
        expect(definitions.map { |d| d[:name] }).to contain_exactly('old_method', 'active_method')
      end
    end

    context 'with scopes strategy' do
      let(:linter) { described_class.new(type: :scopes) }

      before do
        allow(linter).to receive(:ee_directory_exists?).and_return(true)
      end

      it 'skips commented scope definitions' do
        linter.instance_variable_set(:@source_files, {
          model_file => ["# scope :old_scope, -> { }\n", "scope :active_scope, -> { }\n"]
        })

        definitions = linter.send(:find_definitions)

        expect(definitions.map { |d| d[:name] }).to contain_exactly('active_scope')
      end
    end
  end

  describe 'YAML output indentation' do
    let(:linter) { described_class.new(type: :methods) }
    let(:start_time) { Process.clock_gettime(Process::CLOCK_MONOTONIC) }

    before do
      allow(linter).to receive(:ee_directory_exists?).and_return(true)
      linter.unused_collection['app/models/user.rb'] = %w[method_one method_two]
      linter.unused_collection['app/helpers/application_helper.rb'] = ['helper_method?']
    end

    describe '#print_full_report' do
      it 'outputs YAML with properly indented list items' do
        expect { linter.send(:print_full_report, start_time) }
          .to output(/  - method_one.*  - method_two.*  - helper_method\?/m).to_stdout
      end

      it 'does not output unindented list items' do
        expect { linter.send(:print_full_report, start_time) }
          .not_to output(/\n-\s+\S/).to_stdout
      end
    end
  end

  describe 'nil guards on YAML loading' do
    context 'with scopes strategy' do
      let(:linter) { described_class.new(type: :scopes) }

      before do
        allow(linter).to receive(:ee_directory_exists?).and_return(true)
        allow(Dir).to receive(:glob).and_return([])
      end

      it 'handles empty excluded file gracefully' do
        # Create an empty YAML file (returns nil/false from YAML.load_file)
        strategy = described_class::STRATEGIES[:scopes]
        allow(File).to receive(:exist?).with(strategy[:excluded_path]).and_return(true)
        allow(YAML).to receive(:load_file).with(strategy[:excluded_path], symbolize_names: true).and_return(nil)

        definitions = [{ name: 'test', file: 'app/models/test.rb' }]

        expect { linter.send(:filter_excluded, definitions) }.not_to raise_error
      end

      it 'handles empty potential file gracefully' do
        strategy = described_class::STRATEGIES[:scopes]
        allow(File).to receive(:exist?).with(strategy[:potential_path]).and_return(true)
        allow(YAML).to receive(:load_file).with(strategy[:potential_path]).and_return(nil)

        expect { linter.send(:compare_with_known) }.not_to raise_error
      end
    end
  end

  describe 'update_yaml functionality' do
    let(:linter) { described_class.new(type: :scopes) }
    let(:model_file) { 'app/models/user.rb' }

    before do
      allow(linter).to receive(:ee_directory_exists?).and_return(true)
      allow(Dir).to receive(:glob).and_return([model_file])
      allow(File).to receive(:readlines).with(model_file).and_return([
        "scope :unused_one, -> { where(active: true) }\n",
        "scope :unused_two, -> { where(active: false) }\n"
      ])
    end

    describe '#write_potential_file' do
      it 'writes unused items to the YAML file with header and sorted by file path', :aggregate_failures do
        linter.unused_collection['z_file.rb'] = %w[method_z]
        linter.unused_collection['a_file.rb'] = %w[method_a]
        strategy = described_class::STRATEGIES[:scopes]

        expect(File).to receive(:write).with(
          strategy[:potential_path],
          a_string_including(
            '# The scopes listed here',
            'scripts/lint/unused_code.rb --type scopes',
            'excluded_scopes.yml'
          ).and(
            # Verify sorted order: a_file.rb should come before z_file.rb
            satisfy { |content| content.index('a_file.rb') < content.index('z_file.rb') }
          )
        )

        expect { linter.send(:write_potential_file) }.to output(/Updated/).to_stdout
      end

      it 'writes empty YAML with header when no unused items found' do
        strategy = described_class::STRATEGIES[:scopes]

        expect(File).to receive(:write).with(
          strategy[:potential_path],
          a_string_including('# The scopes listed here', "---\n{}")
        )

        expect { linter.send(:write_potential_file) }.to output(/Updated/).to_stdout
      end
    end
  end
end
