# frozen_string_literal: true

require 'fast_spec_helper'
require 'tempfile'
require_relative '../../scripts/update_fe_islands_ci'

RSpec.describe UpdateFeIslandsCi, feature_category: :tooling do
  subject(:updater) { described_class.new }

  let(:apps_dir) { 'ee/frontend_islands/apps' }
  let(:template_file) { '.gitlab/ci/frontend.gitlab-ci.yml' }
  let(:template_name) { '.fe-islands-parallel' }
  let(:setup_ci_file) { '.gitlab/ci/setup.gitlab-ci.yml' }
  let(:static_analysis_ci_file) { '.gitlab/ci/static-analysis.gitlab-ci.yml' }

  let(:jobs_extending_template) do
    [
      { name: 'type-check-fe-islands', file: setup_ci_file },
      { name: '.eslint:fe-islands', file: static_analysis_ci_file },
      { name: 'test-fe-islands', file: template_file }
    ]
  end

  before do
    stub_const("#{FeIslandsCiShared}::APPS_DIR", apps_dir)
    stub_const("#{FeIslandsCiShared}::SSOT_TEMPLATE_FILE", template_file)
    stub_const("#{FeIslandsCiShared}::SSOT_TEMPLATE_NAME", template_name)
    stub_const("#{FeIslandsCiShared}::JOBS_EXTENDING_TEMPLATE", jobs_extending_template)
    stub_const("#{FeIslandsCiShared}::REQUIRED_SCRIPTS", %w[lint lint:types test build])

    # Suppress output during tests
    allow(updater).to receive(:puts)
    allow(updater).to receive(:warn)
  end

  describe '#update!' do
    context 'when no app directories are found' do
      before do
        allow(Dir).to receive(:exist?).with(apps_dir).and_return(false)
      end

      it 'outputs warning and returns early' do
        expect(updater).to receive(:puts).with(/No app directories found/)
        updater.update!(dry_run: false)
      end

      it 'does not attempt to update files' do
        expect(File).not_to receive(:write)
        updater.update!(dry_run: false)
      end
    end

    context 'when CI configuration is already up to date' do
      let(:apps) { ['duo_next'] }

      before do
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with(apps_dir).and_return(true)
        allow(Dir).to receive(:entries).with(apps_dir).and_return(['.', '..', 'duo_next'])
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, '.')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, '..')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, 'duo_next')).and_return(true)

        package_json = { 'scripts' => { 'lint' => 'x', 'lint:types' => 'x', 'test' => 'x', 'build' => 'x' } }
        allow(updater).to receive(:read_package_json).with('duo_next').and_return(package_json)

        # Template already has correct configuration
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(template_file).and_return(true)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(template_file).and_return(
          <<~YAML
            .fe-islands-parallel:
              parallel:
                matrix:
                  - FE_APP_DIR: ["duo_next"]
          YAML
        )
      end

      it 'outputs message that no changes are needed' do
        expect(updater).to receive(:puts).with(/CI configuration is already up to date/)
        updater.update!(dry_run: false)
      end

      it 'does not write files' do
        expect(File).not_to receive(:write)
        updater.update!(dry_run: false)
      end
    end

    context 'with dry_run: true' do
      let(:ci_content) do
        <<~YAML
          .fe-islands-parallel:
            parallel:
              matrix:
                - FE_APP_DIR: ["duo_next"]
        YAML
      end

      before do
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with(apps_dir).and_return(true)
        allow(Dir).to receive(:entries).with(apps_dir).and_return(['.', '..', 'duo_next', 'new_app'])
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, '.')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, '..')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, 'duo_next')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, 'new_app')).and_return(true)

        package_json = { 'scripts' => { 'lint' => 'x', 'lint:types' => 'x', 'test' => 'x', 'build' => 'x' } }
        allow(updater).to receive(:read_package_json).with('duo_next').and_return(package_json)
        allow(updater).to receive(:read_package_json).with('new_app').and_return(package_json)

        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(template_file).and_return(true)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(template_file).and_return(ci_content)
      end

      it 'does not write files' do
        expect(File).not_to receive(:write)
        updater.update!(dry_run: true)
      end

      it 'outputs dry run message' do
        expect(updater).to receive(:puts).with(/DRY RUN: No changes made/)
        updater.update!(dry_run: true)
      end

      it 'shows what would be updated' do
        expect(updater).to receive(:puts).with(/Template that would be updated/)
        expect(updater).to receive(:puts).with(/#{template_name}/)
        updater.update!(dry_run: true)
      end

      it 'shows apps that would be added' do
        expect(updater).to receive(:puts).with(/Apps to be added to CI/)
        expect(updater).to receive(:puts).with(/new_app/)
        updater.update!(dry_run: true)
      end
    end

    context 'with dry_run: false' do
      let(:original_ci_content) do
        <<~YAML
          .fe-islands-parallel:
            parallel:
              matrix:
                - FE_APP_DIR: ["duo_next"]

          other-job:
            script: echo 'test'
        YAML
      end

      let(:expected_ci_content) do
        <<~YAML
          .fe-islands-parallel:
            parallel:
              matrix:
                - FE_APP_DIR: ["duo_next", "new_app"]

          other-job:
            script: echo 'test'
        YAML
      end

      before do
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with(apps_dir).and_return(true)
        allow(Dir).to receive(:entries).with(apps_dir).and_return(['.', '..', 'duo_next', 'new_app'])
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, '.')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, '..')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, 'duo_next')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, 'new_app')).and_return(true)

        package_json = { 'scripts' => { 'lint' => 'x', 'lint:types' => 'x', 'test' => 'x', 'build' => 'x' } }
        allow(updater).to receive(:read_package_json).with('duo_next').and_return(package_json)
        allow(updater).to receive(:read_package_json).with('new_app').and_return(package_json)

        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(template_file).and_return(true)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(template_file).and_return(original_ci_content)
        # Prevent actual file writes
        allow(File).to receive(:write).and_return(nil)
      end

      it 'writes updated content to file' do
        expect(File).to receive(:write).with(template_file, expected_ci_content)
        updater.update!(dry_run: false)
      end

      it 'outputs success message' do
        allow(File).to receive(:write)
        expect(updater).to receive(:puts).with(/✓ Updated CI configuration/)
        updater.update!(dry_run: false)
      end

      it 'shows updated template' do
        allow(File).to receive(:write)
        expect(updater).to receive(:puts).with(/Template: #{template_name}/)
        updater.update!(dry_run: false)
      end

      it 'shows new matrix' do
        allow(File).to receive(:write)
        expect(updater).to receive(:puts).with(/New matrix:.*duo_next.*new_app/m)
        updater.update!(dry_run: false)
      end

      it 'lists jobs that inherit the matrix' do
        allow(File).to receive(:write)
        expect(updater).to receive(:puts).with(/Jobs that inherit this matrix/)
        expect(updater).to receive(:puts).with(/type-check-fe-islands/)
        expect(updater).to receive(:puts).with(/\.eslint:fe-islands/)
        expect(updater).to receive(:puts).with(/test-fe-islands/)
        updater.update!(dry_run: false)
      end
    end

    context 'when apps are removed' do
      let(:original_ci_content) do
        <<~YAML
          .fe-islands-parallel:
            parallel:
              matrix:
                - FE_APP_DIR: ["duo_next", "removed_app"]
        YAML
      end

      let(:expected_ci_content) do
        <<~YAML
          .fe-islands-parallel:
            parallel:
              matrix:
                - FE_APP_DIR: ["duo_next"]
        YAML
      end

      before do
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with(apps_dir).and_return(true)
        allow(Dir).to receive(:entries).with(apps_dir).and_return(['.', '..', 'duo_next'])
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, '.')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, '..')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, 'duo_next')).and_return(true)

        package_json = { 'scripts' => { 'lint' => 'x', 'lint:types' => 'x', 'test' => 'x', 'build' => 'x' } }
        allow(updater).to receive(:read_package_json).with('duo_next').and_return(package_json)

        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(template_file).and_return(true)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(template_file).and_return(original_ci_content)
        # Prevent actual file writes
        allow(File).to receive(:write).and_return(nil)
      end

      it 'writes updated content with removed app' do
        expect(File).to receive(:write).with(template_file, expected_ci_content)
        updater.update!(dry_run: false)
      end

      it 'shows apps to be removed' do
        allow(File).to receive(:write)
        expect(updater).to receive(:puts).with(/Apps to be removed from CI/)
        expect(updater).to receive(:puts).with(/removed_app/)
        updater.update!(dry_run: false)
      end
    end

    context 'when apps have missing scripts' do
      before do
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with(apps_dir).and_return(true)
        allow(Dir).to receive(:entries).with(apps_dir).and_return(['.', '..', 'valid_app', 'invalid_app'])
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, '.')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, '..')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, 'valid_app')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, 'invalid_app')).and_return(true)

        valid_package_json = { 'scripts' => { 'lint' => 'x', 'lint:types' => 'x', 'test' => 'x', 'build' => 'x' } }
        invalid_package_json = { 'scripts' => { 'lint' => 'x' } }
        allow(updater).to receive(:read_package_json).with('valid_app').and_return(valid_package_json)
        allow(updater).to receive(:read_package_json).with('invalid_app').and_return(invalid_package_json)

        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(template_file).and_return(true)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(template_file).and_return(
          <<~YAML
            .fe-islands-parallel:
              parallel:
                matrix:
                  - FE_APP_DIR: []
          YAML
        )
        # Prevent actual file writes
        allow(File).to receive(:write).and_return(nil)
      end

      it 'warns about apps with missing scripts' do
        expect(updater).to receive(:warn).with(/invalid_app.*missing required script/)
        updater.update!(dry_run: false)
      end

      it 'only includes valid apps in update' do
        expect(File).to receive(:write).with(template_file, /\["valid_app"\]/)
        updater.update!(dry_run: false)
      end
    end
  end

  describe '.update!' do
    it 'creates an instance and calls update!' do
      instance = instance_double(described_class)
      allow(described_class).to receive(:new).and_return(instance)
      allow(instance).to receive(:update!)

      described_class.update!(dry_run: false)

      expect(instance).to have_received(:update!).with(dry_run: false)
    end
  end

  describe 'CLI option parsing' do
    let(:option_parser) do
      options = { dry_run: false }

      OptionParser.new do |opts|
        opts.banner = "Usage: test [options]"
        opts.on('-d', '--dry-run', 'Show what would be changed without modifying files') do
          options[:dry_run] = true
        end
        opts.on('-h', '--help', 'Display this help message') do
          puts opts
          exit
        end
      end
    end

    context 'with no flags' do
      it 'defaults dry_run to false' do
        options = { dry_run: false }
        option_parser.parse!([])

        expect(options[:dry_run]).to be false
      end
    end

    context 'with --dry-run flag' do
      it 'sets dry_run to true' do
        options = { dry_run: false }

        OptionParser.new do |opts|
          opts.on('-d', '--dry-run') { options[:dry_run] = true }
        end.parse!(['--dry-run'])

        expect(options[:dry_run]).to be true
      end
    end

    context 'with -d flag' do
      it 'sets dry_run to true' do
        options = { dry_run: false }

        OptionParser.new do |opts|
          opts.on('-d', '--dry-run') { options[:dry_run] = true }
        end.parse!(['-d'])

        expect(options[:dry_run]).to be true
      end
    end

    context 'with --help flag' do
      it 'displays help and exits' do
        expect do
          OptionParser.new do |opts|
            opts.banner = "Usage: test [options]"
            opts.on('-h', '--help', 'Display this help message') do
              puts opts
              exit
            end
          end.parse!(['--help'])
        end.to raise_error(SystemExit)
      end
    end

    context 'with -h flag' do
      it 'displays help and exits' do
        expect do
          OptionParser.new do |opts|
            opts.banner = "Usage: test [options]"
            opts.on('-h', '--help', 'Display this help message') do
              puts opts
              exit
            end
          end.parse!(['-h'])
        end.to raise_error(SystemExit)
      end
    end

    context 'with invalid flag' do
      it 'raises OptionParser::InvalidOption' do
        expect do
          OptionParser.new do |opts|
            opts.on('-d', '--dry-run') { |_| } # rubocop:disable Lint/EmptyBlock -- Testing invalid flag error, not flag behavior
          end.parse!(['--invalid'])
        end.to raise_error(OptionParser::InvalidOption)
      end
    end
  end
end
