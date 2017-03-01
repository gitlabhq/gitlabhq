require 'spec_helper'

describe Gitlab::Kubernetes::RolloutStatus do
  include KubernetesHelpers
  let(:specs_all_finished) { [kube_deployment(name: 'one'), kube_deployment(name: 'two')] }
  let(:specs_half_finished) do
    [
      kube_deployment(name: 'one'),
      kube_deployment(name: 'two').deep_merge('status' => { 'availableReplicas' => 0 })
    ]
  end

  let(:specs) { specs_all_finished }
  subject(:rollout_status) { described_class.from_specs(*specs) }

  describe '#deployments' do
    it 'stores the deployments' do
      expect(rollout_status.deployments).to be_kind_of(Array)
      expect(rollout_status.deployments.size).to eq(2)
      expect(rollout_status.deployments.first).to be_kind_of(::Gitlab::Kubernetes::Deployment)
    end
  end

  describe '#instances' do
    it 'stores the union of deployment instances' do
      expected = [
        { status: 'finished', tooltip: 'one (pod 0) Finished' },
        { status: 'finished', tooltip: 'one (pod 1) Finished' },
        { status: 'finished', tooltip: 'one (pod 2) Finished' },
        { status: 'finished', tooltip: 'two (pod 0) Finished' },
        { status: 'finished', tooltip: 'two (pod 1) Finished' },
        { status: 'finished', tooltip: 'two (pod 2) Finished' },
      ]

      expect(rollout_status.instances).to eq(expected)
    end
  end

  describe '#completion' do
    subject { rollout_status.completion }

    context 'when all instances are finished' do
      it { is_expected.to eq(100) }
    end

    context 'when half of the instances are finished' do
      let(:specs) { specs_half_finished }
      it { is_expected.to eq(50) }
    end
  end

  describe '#complete?' do
    subject { rollout_status.complete? }

    context 'when all instances are finished' do
      it { is_expected.to be_truthy }
    end

    context 'when half of the instances are finished' do
      let(:specs) { specs_half_finished }
      it { is_expected.to be_falsy}
    end
  end
end
