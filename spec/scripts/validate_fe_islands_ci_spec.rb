# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../scripts/validate_fe_islands_ci'

RSpec.describe ValidateFeIslandsCi, feature_category: :tooling do
  subject(:validator) { described_class.new }

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
    allow(validator).to receive(:puts)
  end

  describe '#validate!' do
    context 'when everything is valid and in sync' do
      let(:apps) { ['duo_next'] }

      before do
        # Mock app directory discovery
        allow(validator).to receive_messages(discover_all_app_directories: ['duo_next'],
          discover_app_directories: ['duo_next'])

        # Mock package.json validation
        package_json = { 'scripts' => { 'lint' => 'x', 'lint:types' => 'x', 'test' => 'x', 'build' => 'x' } }
        allow(validator).to receive(:read_package_json).with('duo_next').and_return(package_json)
        allow(validator).to receive(:has_required_scripts?).with('duo_next').and_return(true)
        allow(validator).to receive(:get_missing_scripts).with('duo_next').and_return([])

        # Mock template extraction
        allow(validator).to receive(:extract_template_matrix).with(template_file,
          template_name).and_return(['duo_next'])

        # Mock job extension checks
        jobs_extending_template.each do |job|
          allow(validator).to receive(:job_extends_template?).with(job[:file], job[:name],
            template_name).and_return(true)
        end
      end

      it 'exits with status 0' do
        expect { validator.validate! }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(0)
        end
      end

      it 'outputs success message' do
        expect(validator).to receive(:puts).with(/✓ Frontend Islands CI configuration is up to date/)
        expect { validator.validate! }.to raise_error(SystemExit)
      end
    end

    context 'when template is not found' do
      before do
        allow(validator).to receive_messages(discover_all_app_directories: ['duo_next'],
          discover_app_directories: ['duo_next'])

        # Template not found
        allow(validator).to receive(:extract_template_matrix).with(template_file, template_name).and_return(nil)
      end

      it 'exits with status 1' do
        expect { validator.validate! }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end

      it 'outputs error message about missing template' do
        expect(validator).to receive(:puts).with(/Could not find #{template_name}/)
        expect { validator.validate! }.to raise_error(SystemExit)
      end
    end

    context 'when jobs do not extend the template' do
      before do
        allow(validator).to receive_messages(discover_all_app_directories: ['duo_next'],
          discover_app_directories: ['duo_next'])

        # Template found
        allow(validator).to receive(:extract_template_matrix).with(template_file,
          template_name).and_return(['duo_next'])

        # Jobs don't extend template
        jobs_extending_template.each do |job|
          allow(validator).to receive(:job_extends_template?).with(job[:file], job[:name],
            template_name).and_return(false)
        end
      end

      it 'exits with status 1' do
        expect { validator.validate! }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end

      it 'outputs error about jobs not extending template' do
        expect(validator).to receive(:puts).with(/Jobs not extending template/)
        expect { validator.validate! }.to raise_error(SystemExit)
      end
    end

    context 'when apps have missing scripts' do
      before do
        # duo_next is valid, incomplete_app is missing scripts
        allow(validator).to receive_messages(discover_all_app_directories: %w[duo_next incomplete_app],
          discover_app_directories: ['duo_next'])

        # Mock get_missing_scripts
        allow(validator).to receive(:get_missing_scripts).with('incomplete_app').and_return(['lint:types', 'test',
          'build'])

        # Template found
        allow(validator).to receive(:extract_template_matrix).with(template_file,
          template_name).and_return(['duo_next'])

        # Jobs extend template
        jobs_extending_template.each do |job|
          allow(validator).to receive(:job_extends_template?).with(job[:file], job[:name],
            template_name).and_return(true)
        end
      end

      it 'exits with status 1' do
        expect { validator.validate! }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end

      it 'outputs error about apps with missing scripts' do
        expect(validator).to receive(:puts).with(/Apps with invalid or missing scripts/)
        expect { validator.validate! }.to raise_error(SystemExit)
      end
    end

    context 'when apps are missing from CI configuration' do
      before do
        # Both apps have valid scripts
        allow(validator).to receive_messages(discover_all_app_directories: %w[duo_next new_app],
          discover_app_directories: %w[duo_next new_app])

        # Template only has duo_next, missing new_app
        allow(validator).to receive(:extract_template_matrix).with(template_file,
          template_name).and_return(['duo_next'])

        # Jobs extend template
        jobs_extending_template.each do |job|
          allow(validator).to receive(:job_extends_template?).with(job[:file], job[:name],
            template_name).and_return(true)
        end
      end

      it 'exits with status 1' do
        expect { validator.validate! }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end

      it 'outputs error about configuration being out of sync' do
        expect(validator).to receive(:puts).with(/CI configuration is out of sync/)
        expect { validator.validate! }.to raise_error(SystemExit)
      end

      it 'outputs missing apps' do
        expect(validator).to receive(:puts).with(/Missing in CI configuration/)
        expect(validator).to receive(:puts).with(/new_app/)
        expect { validator.validate! }.to raise_error(SystemExit)
      end
    end

    context 'when CI has extra apps not in directory' do
      before do
        # Only duo_next exists and has valid scripts
        allow(validator).to receive_messages(discover_all_app_directories: ['duo_next'],
          discover_app_directories: ['duo_next'])

        # Template has extra app (removed_app)
        allow(validator).to receive(:extract_template_matrix).with(template_file,
          template_name).and_return(%w[duo_next removed_app])

        # Jobs extend template
        jobs_extending_template.each do |job|
          allow(validator).to receive(:job_extends_template?).with(job[:file], job[:name],
            template_name).and_return(true)
        end
      end

      it 'exits with status 1' do
        expect { validator.validate! }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end

      it 'outputs error about extra apps in configuration' do
        expect(validator).to receive(:puts).with(/Configured but not found in directory/)
        expect(validator).to receive(:puts).with(/removed_app/)
        expect { validator.validate! }.to raise_error(SystemExit)
      end
    end

    context 'when actual apps array is empty' do
      before do
        # No apps in directory
        allow(validator).to receive_messages(discover_all_app_directories: [],
          discover_app_directories: [])

        # Template has apps configured
        allow(validator).to receive(:extract_template_matrix).with(template_file,
          template_name).and_return(['duo_next'])

        # Jobs extend template
        jobs_extending_template.each do |job|
          allow(validator).to receive(:job_extends_template?).with(job[:file], job[:name],
            template_name).and_return(true)
        end
      end

      it 'exits with status 1' do
        expect { validator.validate! }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end

      it 'outputs (none) for actual apps' do
        expect(validator).to receive(:puts).with('  (none)')
        expect { validator.validate! }.to raise_error(SystemExit)
      end

      it 'outputs error about extra apps in configuration' do
        expect(validator).to receive(:puts).with(/Configured but not found in directory/)
        expect { validator.validate! }.to raise_error(SystemExit)
      end
    end

    context 'when configured apps array is empty' do
      before do
        # Apps exist in directory
        allow(validator).to receive_messages(discover_all_app_directories: ['duo_next'],
          discover_app_directories: ['duo_next'])

        # Template has no apps configured
        allow(validator).to receive(:extract_template_matrix).with(template_file,
          template_name).and_return([])

        # Jobs extend template
        jobs_extending_template.each do |job|
          allow(validator).to receive(:job_extends_template?).with(job[:file], job[:name],
            template_name).and_return(true)
        end
      end

      it 'exits with status 1' do
        expect { validator.validate! }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end

      it 'outputs (none) for configured apps' do
        # We expect (none) to be output twice - once for the configured apps section
        # Since there are two (none) outputs in the method (actual and configured),
        # we need to check that at least one matches our expectation
        allow(validator).to receive(:puts).and_call_original
        expect(validator).to receive(:puts).with('  (none)').at_least(:once)
        expect { validator.validate! }.to raise_error(SystemExit)
      end

      it 'outputs error about missing apps in configuration' do
        expect(validator).to receive(:puts).with(/Missing in CI configuration/)
        expect { validator.validate! }.to raise_error(SystemExit)
      end
    end

    context 'when both actual and configured apps are empty' do
      before do
        # No apps anywhere
        allow(validator).to receive_messages(discover_all_app_directories: [],
          discover_app_directories: [])

        # Template has no apps
        allow(validator).to receive(:extract_template_matrix).with(template_file,
          template_name).and_return([])

        # Jobs extend template
        jobs_extending_template.each do |job|
          allow(validator).to receive(:job_extends_template?).with(job[:file], job[:name],
            template_name).and_return(true)
        end
      end

      it 'exits with status 0' do
        expect { validator.validate! }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(0)
        end
      end

      it 'outputs success message' do
        expect(validator).to receive(:puts).with(/✓/)
        expect { validator.validate! }.to raise_error(SystemExit)
      end
    end
  end

  describe '#discover_all_app_directories' do
    context 'when directory exists with multiple apps' do
      before do
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with(apps_dir).and_return(true)
        allow(Dir).to receive(:entries).with(apps_dir).and_return(['.', '..', 'duo_next', 'app_two', '.hidden'])

        allow(Dir).to receive(:exist?).with(File.join(apps_dir, '.')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, '..')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, 'duo_next')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, 'app_two')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, '.hidden')).and_return(true)
      end

      it 'returns all non-hidden directories sorted' do
        result = validator.send(:discover_all_app_directories)

        expect(result).to eq(%w[app_two duo_next])
      end

      it 'filters out . and .. entries' do
        result = validator.send(:discover_all_app_directories)

        expect(result).not_to include('.', '..')
      end

      it 'filters out hidden directories starting with .' do
        result = validator.send(:discover_all_app_directories)

        expect(result).not_to include('.hidden')
      end
    end

    context 'when directory exists but is empty' do
      before do
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with(apps_dir).and_return(true)
        allow(Dir).to receive(:entries).with(apps_dir).and_return(['.', '..'])

        allow(Dir).to receive(:exist?).with(File.join(apps_dir, '.')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, '..')).and_return(true)
      end

      it 'returns empty array' do
        result = validator.send(:discover_all_app_directories)

        expect(result).to eq([])
      end
    end

    context 'when directory only has hidden directories' do
      before do
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with(apps_dir).and_return(true)
        allow(Dir).to receive(:entries).with(apps_dir).and_return(['.', '..', '.git', '.vscode'])

        allow(Dir).to receive(:exist?).with(File.join(apps_dir, '.')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, '..')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, '.git')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, '.vscode')).and_return(true)
      end

      it 'returns empty array' do
        result = validator.send(:discover_all_app_directories)

        expect(result).to eq([])
      end
    end

    context 'when directory does not exist' do
      before do
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with(apps_dir).and_return(false)
      end

      it 'returns empty array' do
        result = validator.send(:discover_all_app_directories)

        expect(result).to eq([])
      end
    end

    context 'when directory contains files (not directories)' do
      before do
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with(apps_dir).and_return(true)
        allow(Dir).to receive(:entries).with(apps_dir).and_return(['.', '..', 'duo_next', 'readme.txt'])

        allow(Dir).to receive(:exist?).with(File.join(apps_dir, '.')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, '..')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, 'duo_next')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, 'readme.txt')).and_return(false)
      end

      it 'only includes directories, not files' do
        result = validator.send(:discover_all_app_directories)

        expect(result).to eq(['duo_next'])
        expect(result).not_to include('readme.txt')
      end
    end
  end

  describe '.validate!' do
    it 'creates an instance and calls validate!' do
      instance = instance_double(described_class)
      allow(described_class).to receive(:new).and_return(instance)
      allow(instance).to receive(:validate!)

      described_class.validate!

      expect(instance).to have_received(:validate!)
    end
  end
end
