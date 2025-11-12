# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../scripts/fe_islands_ci_shared'

RSpec.describe FeIslandsCiShared, feature_category: :tooling do
  include described_class

  describe '#discover_app_directories' do
    let(:apps_dir) { 'ee/frontend_islands/apps' }

    before do
      stub_const("#{described_class}::APPS_DIR", apps_dir)
    end

    context 'when directory exists with valid apps' do
      before do
        allow(Dir).to receive(:exist?).with(apps_dir).and_return(true)
        allow(Dir).to receive(:entries).with(apps_dir).and_return(['.', '..', 'duo_next', 'app_two'])
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with(apps_dir).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, '.')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, '..')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, 'duo_next')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, 'app_two')).and_return(true)

        allow(self).to receive(:has_required_scripts?).with('duo_next').and_return(true)
        allow(self).to receive(:has_required_scripts?).with('app_two').and_return(true)
      end

      it 'returns sorted list of valid apps' do
        expect(discover_app_directories).to eq(%w[app_two duo_next])
      end
    end

    context 'when directory does not exist' do
      before do
        allow(Dir).to receive(:exist?).with(apps_dir).and_return(false)
      end

      it 'returns empty array' do
        expect(discover_app_directories).to eq([])
      end
    end

    context 'when some apps have missing scripts' do
      before do
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with(apps_dir).and_return(true)
        allow(Dir).to receive(:entries).with(apps_dir).and_return(['.', '..', 'valid_app', 'invalid_app'])
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, '.')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, '..')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, 'valid_app')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, 'invalid_app')).and_return(true)

        allow(self).to receive(:has_required_scripts?).with('valid_app').and_return(true)
        allow(self).to receive(:has_required_scripts?).with('invalid_app').and_return(false)
      end

      it 'excludes apps without required scripts' do
        expect(discover_app_directories).to eq(['valid_app'])
      end
    end

    context 'when directory contains hidden directories' do
      before do
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with(apps_dir).and_return(true)
        allow(Dir).to receive(:entries).with(apps_dir).and_return(['.', '..', '.hidden', 'duo_next'])
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, '.')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, '..')).and_return(true)
        allow(Dir).to receive(:exist?).with(File.join(apps_dir, 'duo_next')).and_return(true)

        allow(self).to receive(:has_required_scripts?).with('duo_next').and_return(true)
      end

      it 'excludes hidden directories' do
        expect(discover_app_directories).to eq(['duo_next'])
      end
    end
  end

  describe '#has_required_scripts?' do
    let(:app_dir) { 'duo_next' }
    let(:package_json_path) { 'ee/frontend_islands/apps/duo_next/package.json' }
    let(:required_scripts) { %w[lint lint:types test build] }

    before do
      stub_const("#{described_class}::APPS_DIR", 'ee/frontend_islands/apps')
      stub_const("#{described_class}::REQUIRED_SCRIPTS", required_scripts)
    end

    context 'when all required scripts are present' do
      let(:package_json) do
        {
          'scripts' => {
            'lint' => 'eslint .',
            'lint:types' => 'tsc --noEmit',
            'test' => 'jest',
            'build' => 'vite build'
          }
        }
      end

      before do
        allow(self).to receive(:read_package_json).with(app_dir).and_return(package_json)
      end

      it 'returns true' do
        expect(has_required_scripts?(app_dir)).to be true
      end

      it 'does not print warnings' do
        expect(self).not_to receive(:warn)
        has_required_scripts?(app_dir, warn_on_missing: true)
      end
    end

    context 'when some required scripts are missing' do
      let(:package_json) do
        {
          'scripts' => {
            'lint' => 'eslint .',
            'test' => 'jest'
          }
        }
      end

      before do
        allow(self).to receive(:read_package_json).with(app_dir).and_return(package_json)
      end

      it 'returns false' do
        expect(has_required_scripts?(app_dir)).to be false
      end

      context 'with warn_on_missing: true' do
        it 'prints warning' do
          expect(self).to receive(:warn).with(/duo_next.*missing required script.*lint:types, build/)
          has_required_scripts?(app_dir, warn_on_missing: true)
        end
      end

      context 'with warn_on_missing: false' do
        it 'does not print warning' do
          expect(self).not_to receive(:warn)
          has_required_scripts?(app_dir, warn_on_missing: false)
        end
      end
    end

    context 'when package.json does not exist' do
      before do
        allow(self).to receive(:read_package_json).with(app_dir).and_return(nil)
      end

      it 'returns false' do
        expect(has_required_scripts?(app_dir)).to be false
      end
    end
  end

  describe '#read_package_json' do
    let(:app_dir) { 'duo_next' }
    let(:package_json_path) { 'ee/frontend_islands/apps/duo_next/package.json' }

    before do
      stub_const("#{described_class}::APPS_DIR", 'ee/frontend_islands/apps')
    end

    context 'when file exists and is valid JSON' do
      let(:package_json_content) { '{"name": "duo_next", "version": "1.0.0"}' }
      let(:expected_hash) { { 'name' => 'duo_next', 'version' => '1.0.0' } }

      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(package_json_path).and_return(true)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(package_json_path).and_return(package_json_content)
      end

      it 'returns parsed JSON' do
        expect(read_package_json(app_dir)).to eq(expected_hash)
      end
    end

    context 'when file does not exist' do
      before do
        allow(File).to receive(:exist?).with(package_json_path).and_return(false)
      end

      it 'returns nil' do
        expect(read_package_json(app_dir)).to be_nil
      end
    end

    context 'when file contains invalid JSON' do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(package_json_path).and_return(true)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(package_json_path).and_return('invalid json {')
      end

      it 'returns nil' do
        expect(read_package_json(app_dir)).to be_nil
      end

      context 'with warn_on_error: true' do
        it 'prints warning' do
          expect(self).to receive(:warn).with(/Could not parse.*package\.json/)
          read_package_json(app_dir, warn_on_error: true)
        end
      end
    end
  end

  describe '#extract_template_matrix' do
    let(:file_path) { '.gitlab/ci/frontend.gitlab-ci.yml' }
    let(:template_name) { '.fe-islands-parallel' }

    context 'when template exists with app list' do
      let(:ci_content) do
        <<~YAML
          .fe-islands-parallel:
            parallel:
              matrix:
                - FE_APP_DIR: ["duo_next", "app_two"]

          other-job:
            script: echo "test"
        YAML
      end

      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(file_path).and_return(true)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(file_path).and_return(ci_content)
      end

      it 'returns sorted array of apps' do
        expect(extract_template_matrix(file_path, template_name)).to eq(%w[app_two duo_next])
      end
    end

    context 'when file does not exist' do
      before do
        allow(File).to receive(:exist?).with(file_path).and_return(false)
      end

      it 'returns nil' do
        expect(extract_template_matrix(file_path, template_name)).to be_nil
      end
    end

    context 'when template is not found in file' do
      let(:ci_content) do
        <<~YAML
          other-job:
            script: echo "test"
        YAML
      end

      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(file_path).and_return(true)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(file_path).and_return(ci_content)
      end

      it 'returns nil' do
        expect(extract_template_matrix(file_path, template_name)).to be_nil
      end
    end

    context 'when template exists with single app' do
      let(:ci_content) do
        <<~YAML
          .fe-islands-parallel:
            parallel:
              matrix:
                - FE_APP_DIR: ["duo_next"]
        YAML
      end

      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(file_path).and_return(true)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(file_path).and_return(ci_content)
      end

      it 'returns array with single app' do
        expect(extract_template_matrix(file_path, template_name)).to eq(['duo_next'])
      end
    end
  end

  describe '#job_extends_template?' do
    let(:file_path) { '.gitlab/ci/frontend.gitlab-ci.yml' }
    let(:job_name) { 'test-fe-islands' }
    let(:template_name) { '.fe-islands-parallel' }

    context 'when job extends the template' do
      let(:ci_content) do
        <<~YAML
          test-fe-islands:
            extends:
              - .frontend-test-base
              - .fe-islands-parallel
            script:
              - yarn test
        YAML
      end

      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(file_path).and_return(true)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(file_path).and_return(ci_content)
      end

      it 'returns true' do
        expect(job_extends_template?(file_path, job_name, template_name)).to be true
      end
    end

    context 'when job does not extend the template' do
      let(:ci_content) do
        <<~YAML
          test-fe-islands:
            extends:
              - .frontend-test-base
            script:
              - yarn test
        YAML
      end

      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(file_path).and_return(true)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(file_path).and_return(ci_content)
      end

      it 'returns false' do
        expect(job_extends_template?(file_path, job_name, template_name)).to be false
      end
    end

    context 'when job is not found in file' do
      let(:ci_content) do
        <<~YAML
          other-job:
            script: echo "test"
        YAML
      end

      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(file_path).and_return(true)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(file_path).and_return(ci_content)
      end

      it 'returns false' do
        expect(job_extends_template?(file_path, job_name, template_name)).to be false
      end
    end

    context 'when file does not exist' do
      before do
        allow(File).to receive(:exist?).with(file_path).and_return(false)
      end

      it 'returns false' do
        expect(job_extends_template?(file_path, job_name, template_name)).to be false
      end
    end
  end

  describe '#get_missing_scripts' do
    let(:app_dir) { 'duo_next' }
    let(:package_json_path) { 'ee/frontend_islands/apps/duo_next/package.json' }
    let(:required_scripts) { %w[lint lint:types test build] }

    before do
      stub_const("#{described_class}::APPS_DIR", 'ee/frontend_islands/apps')
      stub_const("#{described_class}::REQUIRED_SCRIPTS", required_scripts)
    end

    context 'when all scripts are present' do
      let(:package_json_content) do
        Gitlab::Json.generate({
          'scripts' => {
            'lint' => 'eslint .',
            'lint:types' => 'tsc --noEmit',
            'test' => 'jest',
            'build' => 'vite build'
          }
        })
      end

      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(package_json_path).and_return(true)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(package_json_path).and_return(package_json_content)
      end

      it 'returns empty array' do
        expect(get_missing_scripts(app_dir)).to eq([])
      end
    end

    context 'when some scripts are missing' do
      let(:package_json_content) do
        Gitlab::Json.generate({
          'scripts' => {
            'lint' => 'eslint .',
            'test' => 'jest'
          }
        })
      end

      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(package_json_path).and_return(true)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(package_json_path).and_return(package_json_content)
      end

      it 'returns array of missing scripts' do
        expect(get_missing_scripts(app_dir)).to eq(['lint:types', 'build'])
      end
    end

    context 'when package.json does not exist' do
      before do
        allow(File).to receive(:exist?).with(package_json_path).and_return(false)
      end

      it 'returns array with package.json marker' do
        expect(get_missing_scripts(app_dir)).to eq(['package.json'])
      end
    end

    context 'when package.json contains invalid JSON' do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(package_json_path).and_return(true)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(package_json_path).and_return('invalid json {')
      end

      it 'returns array with invalid JSON marker' do
        expect(get_missing_scripts(app_dir)).to eq(['package.json (invalid JSON)'])
      end
    end
  end
end
