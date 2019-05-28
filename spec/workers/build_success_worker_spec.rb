# frozen_string_literal: true

require 'spec_helper'

describe BuildSuccessWorker do
  describe '#perform' do
    subject { described_class.new.perform(build.id) }

    before do
      allow_any_instance_of(Deployment).to receive(:create_ref)
    end

    context 'when build exists' do
      context 'when deployment was not created with the build creation' do # An edge case during the transition period
        let!(:build) { create(:ci_build, :deploy_to_production) }

        before do
          allow(Deployments::FinishedWorker).to receive(:perform_async)
          Deployment.delete_all
          build.reload
        end

        it 'creates a successful deployment' do
          expect(build).not_to be_has_deployment

          subject

          build.reload
          expect(build).to be_has_deployment
          expect(build.deployment).to be_success
        end
      end

      context 'when deployment was created with the build creation' do # Counter part of the above edge case
        let!(:build) { create(:ci_build, :deploy_to_production) }

        it 'does not create a new deployment' do
          expect(build).to be_has_deployment

          expect { subject }.not_to change { Deployment.count }
        end
      end

      context 'when build is not associated with project' do
        let!(:build) { create(:ci_build, project: nil) }

        it 'does not create deployment' do
          subject

          expect(build.reload).not_to be_has_deployment
        end
      end

      context 'when the build will stop an environment' do
        let!(:build) { create(:ci_build, :stop_review_app, environment: environment.name, project: environment.project) }
        let(:environment) { create(:environment, state: :available) }

        it 'stops the environment' do
          expect(environment).to be_available

          subject

          expect(environment.reload).to be_stopped
        end
      end
    end

    context 'when build does not exist' do
      it 'does not raise exception' do
        expect { described_class.new.perform(123) }
          .not_to raise_error
      end
    end
  end
end
