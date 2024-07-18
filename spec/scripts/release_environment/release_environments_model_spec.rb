# frozen_string_literal: true

require 'fast_spec_helper'
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
        ENV.delete('DEPLOY_ENV')
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
end
