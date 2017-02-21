require 'spec_helper'

describe RolloutStatusEntity do
  include KubernetesHelpers

  let(:entity) do
    described_class.new(rollout_status, request: double)
  end

  let(:rollout_status) { ::Gitlab::Kubernetes::RolloutStatus.from_specs(kube_deployment) }
  subject { entity.as_json }

  it { is_expected.to have_key(:instances) }
  it { is_expected.to have_key(:completion) }
  it { is_expected.to have_key(:is_completed) }
end
