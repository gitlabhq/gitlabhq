require 'spec_helper'

describe CreateDeploymentService, services: true do
  let(:build) { create(:ci_build) }
  let(:project) { build.project }
  let(:user) { create(:user) }

  let(:service) { described_class.new(project, user, params) }

  describe '#execute' do
    let(:params) do
      { environment: 'production',
        ref: 'master',
        sha: build.sha,
      }
    end

    subject { service.execute }

    context 'when no environments exist' do
      it 'does create a new environment' do
        expect { subject }.to change { Environment.count }.by(1)
      end

      it 'does create a deployment' do
        expect(subject).to be_persisted
      end
    end

    context 'when environment exist' do
      before { create(:environment, project: project, name: 'production') }

      it 'does not create a new environment' do
        expect { subject }.not_to change { Environment.count }
      end

      it 'does create a deployment' do
        expect(subject).to be_persisted
      end
    end

    context 'for environment with invalid name' do
      let(:params) do
        { environment: 'name with spaces',
          ref: 'master',
          sha: build.sha,
        }
      end

      it 'does not create a new environment' do
        expect { subject }.not_to change { Environment.count }
      end

      it 'does not create a deployment' do
        expect(subject).not_to be_persisted
      end
    end
  end
end
