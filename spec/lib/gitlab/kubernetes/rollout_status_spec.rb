require 'spec_helper'

describe Gitlab::Kubernetes::RolloutStatus do
  include KubernetesHelpers

  let(:track) { nil }
  let(:specs) { specs_all_finished }
  let(:specs_none) { [] }

  let(:specs_all_finished) do
    [
      kube_deployment(name: 'one'),
      kube_deployment(name: 'two', track: track)
    ]
  end

  let(:specs_half_finished) do
    [
      kube_deployment(name: 'one'),
      kube_deployment(name: 'two', track: track)
        .deep_merge('status' => { 'availableReplicas' => 0 })
    ]
  end

  subject(:rollout_status) { described_class.from_specs(*specs) }

  describe '#deployments' do
    it 'stores the deployments' do
      expect(rollout_status.deployments).to be_kind_of(Array)
      expect(rollout_status.deployments.size).to eq(2)
      expect(rollout_status.deployments.first).to be_kind_of(::Gitlab::Kubernetes::Deployment)
    end
  end

  describe '#instances' do
    context 'for stable track' do
      it 'stores the union of deployment instances' do
        expected = [
          { status: 'finished', tooltip: 'one (pod 0) Finished', track: 'stable', stable: true },
          { status: 'finished', tooltip: 'one (pod 1) Finished', track: 'stable', stable: true },
          { status: 'finished', tooltip: 'one (pod 2) Finished', track: 'stable', stable: true },
          { status: 'finished', tooltip: 'two (pod 0) Finished', track: 'stable', stable: true },
          { status: 'finished', tooltip: 'two (pod 1) Finished', track: 'stable', stable: true },
          { status: 'finished', tooltip: 'two (pod 2) Finished', track: 'stable', stable: true }
        ]

        expect(rollout_status.instances).to eq(expected)
      end
    end

    context 'for stable track' do
      let(:track) { 'canary' }

      it 'stores the union of deployment instances' do
        expected = [
          { status: 'finished', tooltip: 'two (pod 0) Finished', track: 'canary', stable: false },
          { status: 'finished', tooltip: 'two (pod 1) Finished', track: 'canary', stable: false },
          { status: 'finished', tooltip: 'two (pod 2) Finished', track: 'canary', stable: false },
          { status: 'finished', tooltip: 'one (pod 0) Finished', track: 'stable', stable: true },
          { status: 'finished', tooltip: 'one (pod 1) Finished', track: 'stable', stable: true },
          { status: 'finished', tooltip: 'one (pod 2) Finished', track: 'stable', stable: true }
        ]

        expect(rollout_status.instances).to eq(expected)
      end
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

  describe '#valid?' do
    context 'when the specs are passed' do
      it { is_expected.to be_valid }
    end

    context 'when no specs are passed' do
      let(:specs) { specs_none }

      it { is_expected.not_to be_valid }
    end
  end
end
