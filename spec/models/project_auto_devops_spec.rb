# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectAutoDevops, feature_category: :auto_devops do
  let_it_be(:project) { build(:project) }

  it_behaves_like 'having unique enum values'

  it { is_expected.to belong_to(:project) }

  it { is_expected.to define_enum_for(:deploy_strategy) }

  it { is_expected.to respond_to(:created_at) }
  it { is_expected.to respond_to(:updated_at) }

  describe '#predefined_variables' do
    let(:auto_devops) { build_stubbed(:project_auto_devops, project: project) }

    context 'when deploy_strategy is manual' do
      let(:auto_devops) { build_stubbed(:project_auto_devops, :manual_deployment, project: project) }
      let(:expected_variables) do
        [
          { key: 'INCREMENTAL_ROLLOUT_MODE', value: 'manual' },
          { key: 'STAGING_ENABLED', value: '1' },
          { key: 'INCREMENTAL_ROLLOUT_ENABLED', value: '1' },
          { key: 'AUTO_DEVOPS_EXPLICITLY_ENABLED', value: '1' }
        ]
      end

      it { expect(auto_devops.predefined_variables).to include(*expected_variables) }
    end

    context 'when deploy_strategy is continuous' do
      let(:auto_devops) { build_stubbed(:project_auto_devops, :continuous_deployment, project: project) }

      it { expect(auto_devops.predefined_variables).to include(key: 'AUTO_DEVOPS_EXPLICITLY_ENABLED', value: '1') }

      it do
        expect(auto_devops.predefined_variables.map { |var| var[:key] })
          .not_to include("STAGING_ENABLED", "INCREMENTAL_ROLLOUT_ENABLED")
      end
    end

    context 'when deploy_strategy is timed_incremental' do
      let(:auto_devops) { build_stubbed(:project_auto_devops, :timed_incremental_deployment, project: project) }

      it { expect(auto_devops.predefined_variables).to include(key: 'INCREMENTAL_ROLLOUT_MODE', value: 'timed') }

      it { expect(auto_devops.predefined_variables).to include(key: 'AUTO_DEVOPS_EXPLICITLY_ENABLED', value: '1') }

      it do
        expect(auto_devops.predefined_variables.map { |var| var[:key] })
          .not_to include("STAGING_ENABLED", "INCREMENTAL_ROLLOUT_ENABLED")
      end
    end

    context 'when auto-devops is explicitly disabled' do
      let(:auto_devops) { build_stubbed(:project_auto_devops, :disabled, project: project) }

      it { expect(auto_devops.predefined_variables.to_hash).to be_empty }
    end
  end

  describe '#create_gitlab_deploy_token' do
    let(:auto_devops) { build(:project_auto_devops, project: project) }

    shared_examples 'does not create a gitlab deploy token' do
      it do
        expect { auto_devops.save! }.not_to change { project.deploy_tokens.count }
      end
    end

    shared_examples 'creates a gitlab deploy token' do
      it do
        expect { auto_devops.save! }.to change { project.deploy_tokens.count }.by(1)

        token = project.deploy_tokens.last
        expect(token).to have_attributes(
          name: DeployToken::GITLAB_DEPLOY_TOKEN_NAME,
          read_registry: true,
          project_id: project.id
        )
      end
    end

    context 'when the project is public' do
      let(:project) { create(:project, :repository, :public) }

      include_examples 'does not create a gitlab deploy token'
    end

    context 'when the project is internal' do
      let(:project) { create(:project, :repository, :internal) }

      include_examples 'creates a gitlab deploy token'
    end

    context 'when the project is private' do
      let(:project) { create(:project, :repository, :private) }

      include_examples 'creates a gitlab deploy token'
    end

    context 'when autodevops is enabled at project level' do
      let(:project) { create(:project, :repository, :internal) }
      let(:auto_devops) { build(:project_auto_devops, project: project) }

      include_examples 'creates a gitlab deploy token'
    end

    context 'when autodevops is enabled at instance level' do
      let(:project) { create(:project, :repository, :internal) }
      let(:auto_devops) { build(:project_auto_devops, enabled: nil, project: project) }

      before do
        allow(Gitlab::CurrentSettings).to receive(:auto_devops_enabled?).and_return(true)
      end

      include_examples 'creates a gitlab deploy token'
    end

    context 'when autodevops is disabled' do
      let(:project) { create(:project, :repository, :internal) }
      let(:auto_devops) { build(:project_auto_devops, :disabled, project: project) }

      include_examples 'does not create a gitlab deploy token'
    end

    context 'when the project already has an active gitlab-deploy-token' do
      let(:project) { create(:project, :repository, :internal) }
      let!(:deploy_token) { create(:deploy_token, :gitlab_deploy_token, projects: [project]) }
      let(:auto_devops) { build(:project_auto_devops, project: project) }

      include_examples 'does not create a gitlab deploy token'
    end

    context 'when the project already has a revoked gitlab-deploy-token' do
      let(:project) { create(:project, :repository, :internal) }
      let!(:deploy_token) { create(:deploy_token, :gitlab_deploy_token, :expired, projects: [project]) }
      let(:auto_devops) { build(:project_auto_devops, project: project) }

      include_examples 'does not create a gitlab deploy token'
    end
  end
end
