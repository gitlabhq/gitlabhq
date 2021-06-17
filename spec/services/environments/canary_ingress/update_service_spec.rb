# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environments::CanaryIngress::UpdateService, :clean_gitlab_redis_cache do
  include KubernetesHelpers

  let_it_be(:project, refind: true) { create(:project) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:reporter) { create(:user) }

  let(:user) { maintainer }
  let(:params) { {} }
  let(:service) { described_class.new(project, user, params) }

  before_all do
    project.add_maintainer(maintainer)
    project.add_reporter(reporter)
  end

  shared_examples_for 'failed request' do
    it 'returns an error' do
      expect(subject[:status]).to eq(:error)
      expect(subject[:message]).to eq(message)
    end
  end

  describe '#execute_async' do
    subject { service.execute_async(environment) }

    let(:environment) { create(:environment, project: project) }
    let(:params) { { weight: 50 } }
    let(:canary_ingress) { ::Gitlab::Kubernetes::Ingress.new(kube_ingress(track: :canary)) }

    context 'when the actor does not have permission to update environment' do
      let(:user) { reporter }

      it_behaves_like 'failed request' do
        let(:message) { "You do not have permission to update the environment." }
      end
    end

    context 'when weight parameter is invalid' do
      let(:params) { { weight: 'unknown' } }

      it_behaves_like 'failed request' do
        let(:message) { 'Canary weight must be specified and valid range (0..100).' }
      end
    end

    context 'when no parameters exist' do
      let(:params) { {} }

      it_behaves_like 'failed request' do
        let(:message) { 'Canary weight must be specified and valid range (0..100).' }
      end
    end

    context 'when environment has a running deployment' do
      before do
        allow(environment).to receive(:has_running_deployments?) { true }
      end

      it_behaves_like 'failed request' do
        let(:message) { 'There are running deployments on the environment. Please retry later.' }
      end
    end

    context 'when canary ingress was updated recently' do
      before do
        allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?) { true }
      end

      it_behaves_like 'failed request' do
        let(:message) { "This environment's canary ingress has been updated recently. Please retry later." }
      end
    end
  end

  describe '#execute' do
    subject { service.execute(environment) }

    let(:environment) { create(:environment, project: project) }
    let(:params) { { weight: 50 } }
    let(:canary_ingress) { ::Gitlab::Kubernetes::Ingress.new(kube_ingress(track: :canary)) }

    context 'when canary ingress is present in the environment' do
      before do
        allow(environment).to receive(:ingresses) { [canary_ingress] }
      end

      context 'when patch request succeeds' do
        let(:patch_data) do
          {
            metadata: {
              annotations: {
                Gitlab::Kubernetes::Ingress::ANNOTATION_KEY_CANARY_WEIGHT => params[:weight].to_s
              }
            }
          }
        end

        before do
          allow(environment).to receive(:patch_ingress).with(canary_ingress, patch_data) { true }
        end

        it 'returns success' do
          expect(subject[:status]).to eq(:success)
          expect(subject[:message]).to be_nil
        end

        it 'clears all caches' do
          expect(environment).to receive(:clear_all_caches)

          subject
        end
      end

      context 'when patch request does not succeed' do
        before do
          allow(environment).to receive(:patch_ingress) { false }
        end

        it_behaves_like 'failed request' do
          let(:message) { 'Failed to update the Canary Ingress.' }
        end
      end
    end

    context 'when canary ingress is not present in the environment' do
      it_behaves_like 'failed request' do
        let(:message) { 'Canary Ingress does not exist in the environment.' }
      end
    end
  end
end
