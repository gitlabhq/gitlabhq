# frozen_string_literal: true

require 'fast_spec_helper'
require 'tempfile'
require_relative '../../../scripts/release_environment/construct-release-environments-versions'

RSpec.describe ReleaseEnvironmentsModel, feature_category: :delivery do
  let(:model) { described_class.new }

  describe '#generate_json' do
    it 'generates the correct JSON' do
      stub_env('CI_COMMIT_SHORT_SHA', 'abcdef')
      stub_env('CI_COMMIT_REF_NAME', '15-10-stable')
      expected_json = {
        'gitaly' => '15-10-stable-abcdef',
        'registry' => '15-10-stable-abcdef',
        'kas' => '15-10-stable-abcdef',
        'mailroom' => '15-10-stable-abcdef',
        'pages' => '15-10-stable-abcdef',
        'gitlab' => '15-10-stable-abcdef',
        'shell' => '15-10-stable-abcdef',
        'praefect' => '15-10-stable-abcdef'
      }.to_json

      expect(model.generate_json).to eq(expected_json)
    end
  end

  describe '#set_required_env_vars?' do
    context 'when required env vars are present' do
      it 'returns true' do
        stub_env('DEPLOY_ENV', 'test.env')
        expect(model.set_required_env_vars?).to be true
      end
    end

    context 'when required env vars are missing' do
      it 'returns false' do
        stub_env('DEPLOY_ENV', nil)
        expect(model.set_required_env_vars?).to be false
      end
    end
  end

  describe '#environment' do
    context 'when CI_PROJECT_PATH is not gitlab-org/security/gitlab' do
      before do
        stub_env('CI_PROJECT_PATH', 'gitlab-org/gitlab')
      end

      context 'for stable branch' do
        it 'returns the correct environment' do
          stub_env('CI_COMMIT_REF_NAME', '15-10-stable-ee')
          expect(model.environment).to eq('15-10-stable')
        end
      end

      context 'for RC tag' do
        it 'returns the correct environment' do
          stub_env('CI_COMMIT_REF_NAME', 'v15.10.3-rc42-ee')
          expect(model.environment).to eq('15-10-stable')
        end
      end

      context 'for release tag' do
        it 'returns the correct environment' do
          stub_env('CI_COMMIT_REF_NAME', 'v15.10.3-ee')
          expect(model.environment).to eq('15-10-stable')
        end
      end
    end

    context 'when CI_PROJECT_PATH is gitlab-org/security/gitlab' do
      before do
        stub_env('CI_PROJECT_PATH', 'gitlab-org/security/gitlab')
        stub_env('CI_COMMIT_REF_NAME', '15-10-stable-ee')
      end

      it 'returns the environment with -security' do
        expect(model.environment).to eq('15-10-stable-security')
      end
    end
  end

  describe '#omnibus_package_version' do
    context 'when running in a branch pipeline' do
      it 'generates the correct omnibus package name' do
        stub_env('CI_COMMIT_REF_NAME', '15-10-stable-ee')
        stub_env('CI_COMMIT_BRANCH', '15-10-stable-ee')
        stub_env('CI_PIPELINE_ID', '12345')
        stub_env('CI_COMMIT_SHORT_SHA', 'abcdef')

        expected_package = '15.10+stable.12345.abcdef'
        expect(model.omnibus_package_version).to eq(expected_package)
      end
    end

    context 'when running in an RC tag pipeline' do
      it 'generates the correct omnibus package name from the RC tag' do
        stub_env('CI_COMMIT_REF_NAME', 'v15.10.3-rc42-ee')
        stub_env('CI_COMMIT_BRANCH', nil) # This would be nil for tag pipelines
        stub_env('CI_PIPELINE_ID', '12345')
        stub_env('CI_COMMIT_SHORT_SHA', 'abcdef')

        expected_package = '15.10+stable.12345.abcdef'
        expect(model.omnibus_package_version).to eq(expected_package)
      end
    end
  end

  describe '#write_deploy_env_file' do
    let(:temp_file) { Tempfile.new('deploy_env_test') }

    before do
      stub_env('DEPLOY_ENV', temp_file.path)
      stub_env('CI_COMMIT_SHORT_SHA', 'abc123')
      stub_env('CI_COMMIT_REF_NAME', '16-0-stable-ee')
      stub_env('CI_PROJECT_PATH', 'gitlab-org/gitlab')
      stub_env('CI_PIPELINE_ID', '98765')
      stub_env('CI_COMMIT_BRANCH', '16-0-stable-ee')
    end

    after do
      temp_file.close
      temp_file.unlink
    end

    context 'when all env vars are present' do
      it 'writes the correct content to the DEPLOY_ENV file' do
        expect { model.write_deploy_env_file }.to output(/ENVIRONMENT=16-0-stable/).to_stdout

        content = File.read(temp_file.path)
        expect(content).to include('ENVIRONMENT=16-0-stable')
        expect(content).to include('VERSIONS={"gitaly":"16-0-stable-abc123"')
        expect(content).to include('OMNIBUS_PACKAGE_VERSION=16.0+stable.98765.abc123')
      end
    end

    context 'when required env vars are missing' do
      it 'raises an error' do
        stub_env('DEPLOY_ENV', nil)

        expect { model.write_deploy_env_file }.to raise_error(RuntimeError, "Missing required environment variable.")
      end
    end
  end
end
