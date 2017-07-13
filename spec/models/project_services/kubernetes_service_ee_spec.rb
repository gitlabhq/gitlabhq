require 'spec_helper'

describe KubernetesService, models: true, use_clean_rails_memory_store_caching: true do
  include KubernetesHelpers
  include ReactiveCachingHelpers

  let(:project) { build_stubbed(:kubernetes_project) }
  let(:service) { project.kubernetes_service }

  describe '#rollout_status' do
    let(:environment) { build(:environment, project: project, name: "env", slug: "env-000000") }
    subject(:rollout_status) { service.rollout_status(environment) }

    context 'with valid deployments' do
      before do
        stub_reactive_cache(
          service,
          deployments: [kube_deployment(app: environment.slug), kube_deployment]
        )
      end

      it 'creates a matching RolloutStatus' do
        expect(rollout_status).to be_kind_of(::Gitlab::Kubernetes::RolloutStatus)
        expect(rollout_status.deployments.map(&:labels)).to eq([{ 'app' => 'env-000000' }])
      end
    end
  end
end
