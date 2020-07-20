# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployments::OlderDeploymentsDropService do
  let(:environment) { create(:environment) }
  let(:deployment) { create(:deployment, environment: environment) }
  let(:service) { described_class.new(deployment) }

  describe '#execute' do
    subject { service.execute }

    shared_examples 'it does not drop any build' do
      it do
        expect { subject }.to not_change(Ci::Build.failed, :count)
      end
    end

    context 'when deployment is nil' do
      let(:deployment) { nil }

      it_behaves_like 'it does not drop any build'
    end

    context 'when a deployment is passed in' do
      context 'and there is no active deployment for the related environment' do
        let(:deployment) { create(:deployment, :canceled, environment: environment) }
        let(:deployment2) { create(:deployment, :canceled, environment: environment) }

        before do
          deployment
          deployment2
        end

        it_behaves_like 'it does not drop any build'
      end

      context 'and there are active deployment for the related environment' do
        let(:deployment) { create(:deployment, :running, environment: environment) }
        let(:deployment2) { create(:deployment, :running, environment: environment) }

        context 'and there is no older deployment than "deployment"' do
          before do
            deployment
            deployment2
          end

          it_behaves_like 'it does not drop any build'
        end

        context 'and there is an older deployment than "deployment"' do
          let(:older_deployment) { create(:deployment, :running, environment: environment) }

          before do
            older_deployment
            deployment
            deployment2
          end

          it 'drops that older deployment' do
            deployable = older_deployment.deployable
            expect(deployable.failed?).to be_falsey

            subject

            expect(deployable.reload.failed?).to be_truthy
          end

          context 'when older deployable is a manual job' do
            let(:older_deployment) { create(:deployment, :created, environment: environment, deployable: build) }
            let(:build) { create(:ci_build, :manual) }

            it 'does not drop any builds nor track the exception' do
              expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

              expect { subject }.not_to change { Ci::Build.failed.count }
            end
          end

          context 'when deployable.drop raises RuntimeError' do
            before do
              allow_any_instance_of(Ci::Build).to receive(:drop).and_raise(RuntimeError)
            end

            it 'does not drop an older deployment and tracks the exception' do
              expect(Gitlab::ErrorTracking).to receive(:track_exception)
                .with(kind_of(RuntimeError), subject_id: deployment.id, deployment_id: older_deployment.id)

              expect { subject }.not_to change { Ci::Build.failed.count }
            end
          end

          context 'when ActiveRecord::StaleObjectError is raised' do
            before do
              allow_any_instance_of(Ci::Build)
                .to receive(:drop).and_raise(ActiveRecord::StaleObjectError)
            end

            it 'resets the object via Gitlab::OptimisticLocking' do
              allow_any_instance_of(Ci::Build).to receive(:reset).at_least(:once)

              subject
            end
          end

          context 'and there is no deployable for that older deployment' do
            let(:older_deployment) { create(:deployment, :running, environment: environment, deployable: nil) }

            it_behaves_like 'it does not drop any build'
          end
        end
      end
    end
  end
end
