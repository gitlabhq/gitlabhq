# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::CiConfiguration::SecretDetectionCreateService, :snowplow, feature_category: :container_scanning do
  describe '#execute' do
    let_it_be(:project) { create(:project, :repository) }
    let(:snowplow_event) do
      {
        category: 'Security::CiConfiguration::SecretDetectionCreateService',
        action: 'create',
        label: 'false'
      }
    end

    let_it_be(:user) { create(:user) }
    let(:branch_name) { 'set-secret-detection-config-1' }
    let(:params) { {} }
    let(:commit_on_default) { false }

    subject(:result) { described_class.new(project, user, params, commit_on_default: commit_on_default).execute }

    # Include the shared examples that test basic functionality
    include_examples 'services security ci configuration create service', true

    context 'when user belongs to project' do
      before_all do
        project.add_developer(user)
      end

      context 'with initialize_with_secret_detection parameter' do
        let(:params) { { initialize_with_secret_detection: true } }
        let(:build_action_instance) { instance_double(Security::CiConfiguration::SecretDetectionBuildAction) }

        before do
          allow(Security::CiConfiguration::SecretDetectionBuildAction).to receive(:new)
            .and_return(build_action_instance)
          allow(build_action_instance).to receive(:generate).and_return({
            action: 'create',
            file_path: '.gitlab-ci.yml',
            content: 'content',
            default_values_overwritten: true
          })
        end

        it 'passes the parameter to SecretDetectionBuildAction' do
          expect(Security::CiConfiguration::SecretDetectionBuildAction).to receive(:new)
            .with(anything, hash_including(initialize_with_secret_detection: true), anything, anything)
            .and_return(build_action_instance)

          result
        end

        it 'returns success' do
          expect(result.status).to eq(:success)
        end
      end

      context 'with sast_also_enabled parameter' do
        let(:params) { { sast_also_enabled: true } }
        let(:build_action_instance) { instance_double(Security::CiConfiguration::SecretDetectionBuildAction) }

        before do
          allow(Security::CiConfiguration::SecretDetectionBuildAction).to receive(:new)
            .and_return(build_action_instance)
          allow(build_action_instance).to receive(:generate).and_return({
            action: 'create',
            file_path: '.gitlab-ci.yml',
            content: 'content',
            default_values_overwritten: true
          })
        end

        it 'creates appropriate commit message' do
          service = described_class.new(project, user, params)

          expect(service.send(:message)).to eq(
            'Configure SAST and Secret Detection in `.gitlab-ci.yml`, creating this file if it does not already exist'
          )
        end
      end

      context 'with commit_on_default parameter' do
        let(:params) { { initialize_with_secret_detection: true } }
        let(:commit_on_default) { true }

        it 'uses the project default branch' do
          service = described_class.new(project, user, params, commit_on_default: true)

          expect(service.branch_name).to eq(project.default_branch)
        end

        it 'returns success' do
          # Setup expectations for the repository API
          allow(project.repository).to receive(:add_branch)
          allow_next_instance_of(Files::MultiService) do |multi_service|
            expect(multi_service).to receive(:execute).and_return(status: :success)
          end

          expect(result.status).to eq(:success)
        end
      end

      context 'with no commit_on_default parameter' do
        let(:commit_on_default) { false }

        it 'uses the generated branch name' do
          service = described_class.new(project, user, {})

          expect(service.branch_name).to start_with('set-secret-detection-config')
        end
      end
    end
  end
end
