# frozen_string_literal: true

require 'spec_helper'

describe Deployments::OlderDeploymentsDropService do
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

          context 'and there is no deployable for that older deployment' do
            let(:older_deployment) { create(:deployment, :running, environment: environment, deployable: nil) }

            it_behaves_like 'it does not drop any build'
          end
        end
      end
    end
  end
end
