# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployments::CreateForBuildService do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:service) { described_class.new }

  describe '#execute' do
    subject { service.execute(build) }

    context 'with a deployment job' do
      let!(:build) { create(:ci_build, :start_review_app, project: project) }
      let!(:environment) { create(:environment, project: project, name: build.expanded_environment_name) }

      it 'creates a deployment record' do
        expect { subject }.to change { Deployment.count }.by(1)

        build.reset
        expect(build.deployment.project).to eq(build.project)
        expect(build.deployment.ref).to eq(build.ref)
        expect(build.deployment.sha).to eq(build.sha)
        expect(build.deployment.deployable).to eq(build)
        expect(build.deployment.deployable_type).to eq('CommitStatus')
        expect(build.deployment.environment).to eq(build.persisted_environment)
        expect(build.deployment.valid?).to be_truthy
      end

      context 'when creation failure occures' do
        before do
          allow(build).to receive(:create_deployment!) { raise ActiveRecord::RecordInvalid }
        end

        it 'trackes the exception' do
          expect { subject }.to raise_error(described_class::DeploymentCreationError)

          expect(Deployment.count).to eq(0)
        end
      end

      context 'when the corresponding environment does not exist' do
        let!(:environment) { }

        it 'does not create a deployment record' do
          expect { subject }.not_to change { Deployment.count }

          expect(build.deployment).to be_nil
        end
      end
    end

    context 'with a teardown job' do
      let!(:build) { create(:ci_build, :stop_review_app, project: project) }
      let!(:environment) { create(:environment, name: build.expanded_environment_name) }

      it 'does not create a deployment record' do
        expect { subject }.not_to change { Deployment.count }

        expect(build.deployment).to be_nil
      end
    end

    context 'with a normal job' do
      let!(:build) { create(:ci_build, project: project) }

      it 'does not create a deployment record' do
        expect { subject }.not_to change { Deployment.count }

        expect(build.deployment).to be_nil
      end
    end

    context 'with a bridge' do
      let!(:build) { create(:ci_bridge, project: project) }

      it 'does not create a deployment record' do
        expect { subject }.not_to change { Deployment.count }
      end
    end
  end
end
