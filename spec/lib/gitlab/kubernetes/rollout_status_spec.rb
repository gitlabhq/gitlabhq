# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kubernetes::RolloutStatus do
  include KubernetesHelpers

  let(:track) { nil }
  let(:specs) { specs_all_finished }

  let(:pods) do
    create_pods(name: "one", count: 3, track: 'stable') + create_pods(name: "two", count: 3, track: "canary")
  end

  let(:ingresses) { [] }

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
    ]
  end

  subject(:rollout_status) { described_class.from_deployments(*specs, pods_attrs: pods, ingresses: ingresses) }

  describe '#deployments' do
    it 'stores the deployments' do
      expect(rollout_status.deployments).to be_kind_of(Array)
      expect(rollout_status.deployments.size).to eq(2)
      expect(rollout_status.deployments.first).to be_kind_of(::Gitlab::Kubernetes::Deployment)
    end
  end

  describe '#instances' do
    context 'for stable track' do
      let(:track) { "any" }

      let(:pods) do
        create_pods(name: "one", count: 3, track: 'stable') + create_pods(name: "two", count: 3, track: "any")
      end

      it 'stores the union of deployment instances' do
        expected = [
          { status: 'running', pod_name: "two", tooltip: 'two (Running)', track: 'any', stable: false },
          { status: 'running', pod_name: "two", tooltip: 'two (Running)', track: 'any', stable: false },
          { status: 'running', pod_name: "two", tooltip: 'two (Running)', track: 'any', stable: false },
          { status: 'running', pod_name: "one", tooltip: 'one (Running)', track: 'stable', stable: true },
          { status: 'running', pod_name: "one", tooltip: 'one (Running)', track: 'stable', stable: true },
          { status: 'running', pod_name: "one", tooltip: 'one (Running)', track: 'stable', stable: true }
        ]

        expect(rollout_status.instances).to eq(expected)
      end
    end

    context 'for stable track' do
      let(:track) { 'canary' }

      let(:pods) do
        create_pods(name: "one", count: 3, track: 'stable') + create_pods(name: "two", count: 3, track: track)
      end

      it 'sorts stable instances last' do
        expected = [
          { status: 'running', pod_name: "two", tooltip: 'two (Running)', track: 'canary', stable: false },
          { status: 'running', pod_name: "two", tooltip: 'two (Running)', track: 'canary', stable: false },
          { status: 'running', pod_name: "two", tooltip: 'two (Running)', track: 'canary', stable: false },
          { status: 'running', pod_name: "one", tooltip: 'one (Running)', track: 'stable', stable: true },
          { status: 'running', pod_name: "one", tooltip: 'one (Running)', track: 'stable', stable: true },
          { status: 'running', pod_name: "one", tooltip: 'one (Running)', track: 'stable', stable: true }
        ]

        expect(rollout_status.instances).to eq(expected)
      end
    end
  end

  describe '#completion' do
    subject { rollout_status.completion }

    context 'when all instances are finished' do
      let(:track) { 'canary' }

      it { is_expected.to eq(100) }
    end

    context 'when half of the instances are finished' do
      let(:track) { "canary" }

      let(:pods) do
        create_pods(name: "one", count: 3, track: 'stable') + create_pods(name: "two", count: 3, track: track, status: "Pending")
      end

      let(:specs) { specs_half_finished }

      it { is_expected.to eq(50) }
    end

    context 'with one deployment' do
      it 'sets the completion percentage when a deployment has more running pods than desired' do
        deployments = [kube_deployment(name: 'one', track: 'one', replicas: 2)]
        pods = create_pods(name: 'one', track: 'one', count: 3)
        rollout_status = described_class.from_deployments(*deployments, pods_attrs: pods)

        expect(rollout_status.completion).to eq(100)
      end
    end

    context 'with two deployments on different tracks' do
      it 'sets the completion percentage when all pods are complete' do
        deployments = [
          kube_deployment(name: 'one', track: 'one', replicas: 2),
          kube_deployment(name: 'two', track: 'two', replicas: 2)
        ]
        pods = create_pods(name: 'one', track: 'one', count: 2) + create_pods(name: 'two', track: 'two', count: 2)
        rollout_status = described_class.from_deployments(*deployments, pods_attrs: pods)

        expect(rollout_status.completion).to eq(100)
      end
    end

    context 'with two deployments that both have track set to "stable"' do
      it 'sets the completion percentage when all pods are complete' do
        deployments = [
          kube_deployment(name: 'one', track: 'stable', replicas: 2),
          kube_deployment(name: 'two', track: 'stable', replicas: 2)
        ]
        pods = create_pods(name: 'one', track: 'stable', count: 2) + create_pods(name: 'two', track: 'stable', count: 2)
        rollout_status = described_class.from_deployments(*deployments, pods_attrs: pods)

        expect(rollout_status.completion).to eq(100)
      end

      it 'sets the completion percentage when no pods are complete' do
        deployments = [
          kube_deployment(name: 'one', track: 'stable', replicas: 3),
          kube_deployment(name: 'two', track: 'stable', replicas: 7)
        ]
        rollout_status = described_class.from_deployments(*deployments, pods_attrs: [])

        expect(rollout_status.completion).to eq(0)
      end

      it 'sets the completion percentage when a quarter of the pods are complete' do
        deployments = [
          kube_deployment(name: 'one', track: 'stable', replicas: 6),
          kube_deployment(name: 'two', track: 'stable', replicas: 2)
        ]
        pods = create_pods(name: 'one', track: 'stable', count: 2)
        rollout_status = described_class.from_deployments(*deployments, pods_attrs: pods)

        expect(rollout_status.completion).to eq(25)
      end
    end

    context 'with two deployments, one with track set to "stable" and one with no track label' do
      it 'sets the completion percentage when all pods are complete' do
        deployments = [
          kube_deployment(name: 'one', track: 'stable', replicas: 3),
          kube_deployment(name: 'two', track: nil, replicas: 3)
        ]
        pods = create_pods(name: 'one', track: 'stable', count: 3) + create_pods(name: 'two', track: nil, count: 3)
        rollout_status = described_class.from_deployments(*deployments, pods_attrs: pods)

        expect(rollout_status.completion).to eq(100)
      end

      it 'sets the completion percentage when no pods are complete' do
        deployments = [
          kube_deployment(name: 'one', track: 'stable', replicas: 1),
          kube_deployment(name: 'two', track: nil, replicas: 1)
        ]
        rollout_status = described_class.from_deployments(*deployments, pods_attrs: [])

        expect(rollout_status.completion).to eq(0)
      end

      it 'sets the completion percentage when a third of the pods are complete' do
        deployments = [
          kube_deployment(name: 'one', track: 'stable', replicas: 2),
          kube_deployment(name: 'two', track: nil, replicas: 7)
        ]
        pods = create_pods(name: 'one', track: 'stable', count: 2) + create_pods(name: 'two', track: nil, count: 1)
        rollout_status = described_class.from_deployments(*deployments, pods_attrs: pods)

        expect(rollout_status.completion).to eq(33)
      end
    end
  end

  describe '#complete?' do
    subject { rollout_status.complete? }

    context 'when all instances are finished' do
      let(:track) { 'canary' }

      it { is_expected.to be_truthy }
    end

    context 'when half of the instances are finished' do
      let(:track) { "canary" }

      let(:pods) do
        create_pods(name: "one", count: 3, track: 'stable') + create_pods(name: "two", count: 3, track: track, status: "Pending")
      end

      let(:specs) { specs_half_finished }

      it { is_expected.to be_falsy }
    end
  end

  describe '#found?' do
    context 'when the specs are passed' do
      it { is_expected.to be_found }
    end

    context 'when list of specs is empty' do
      let(:specs) { [] }

      it { is_expected.not_to be_found }
    end
  end

  describe '.loading' do
    subject { described_class.loading }

    it { is_expected.to be_loading }
  end

  describe '#not_found?' do
    context 'when the specs are passed' do
      it { is_expected.not_to be_not_found }
    end

    context 'when list of specs is empty' do
      let(:specs) { [] }

      it { is_expected.to be_not_found }
    end
  end

  describe '#canary_ingress_exists?' do
    context 'when canary ingress exists' do
      let(:ingresses) { [kube_ingress(track: :canary)] }

      it 'returns true' do
        expect(rollout_status.canary_ingress_exists?).to eq(true)
      end
    end

    context 'when canary ingress does not exist' do
      let(:ingresses) { [kube_ingress(track: :stable)] }

      it 'returns false' do
        expect(rollout_status.canary_ingress_exists?).to eq(false)
      end
    end
  end

  def create_pods(name:, count:, track: nil, status: 'Running')
    Array.new(count, kube_pod(name: name, status: status, track: track))
  end
end
