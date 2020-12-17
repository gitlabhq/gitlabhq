# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kubernetes::Deployment do
  include KubernetesHelpers

  let(:pods) { {} }

  subject(:deployment) { described_class.new(params, pods: pods) }

  describe '#name' do
    let(:params) { named(:selected) }

    it { expect(deployment.name).to eq(:selected) }
  end

  describe '#labels' do
    let(:params) { make('metadata', 'labels' => :selected) }

    it { expect(deployment.labels).to eq(:selected) }
  end

  describe '#outdated?' do
    context 'when outdated' do
      let(:params) { generation(2, 1, 0) }

      it { expect(deployment.outdated?).to be_truthy }
    end

    context 'when up to date' do
      let(:params) { generation(2, 2, 0) }

      it { expect(deployment.outdated?).to be_falsy }
    end

    context 'when ahead of latest' do
      let(:params) { generation(1, 2, 0) }

      it { expect(deployment.outdated?).to be_falsy }
    end
  end

  describe '#instances' do
    context 'when unnamed' do
      let(:pods) do
        [
          kube_pod(name: nil, status: 'Pending'),
          kube_pod(name: nil, status: 'Pending'),
          kube_pod(name: nil, status: 'Pending'),
          kube_pod(name: nil, status: 'Pending')
        ]
      end

      let(:params) { combine(generation(1, 1, 4)) }

      it 'returns all pods with generated names and pending' do
        expected = [
          { status: 'pending', pod_name: 'generated-name-with-suffix', tooltip: 'generated-name-with-suffix (Pending)', track: 'stable', stable: true },
          { status: 'pending', pod_name: 'generated-name-with-suffix', tooltip: 'generated-name-with-suffix (Pending)', track: 'stable', stable: true },
          { status: 'pending', pod_name: 'generated-name-with-suffix', tooltip: 'generated-name-with-suffix (Pending)', track: 'stable', stable: true },
          { status: 'pending', pod_name: 'generated-name-with-suffix', tooltip: 'generated-name-with-suffix (Pending)', track: 'stable', stable: true }
        ]

        expect(deployment.instances).to eq(expected)
      end
    end

    # When replica count is higher than pods it is considered that pod was not
    # able to spawn for some reason like limited resources.
    context 'when number of pods is less than wanted replicas' do
      let(:wanted_replicas) { 3 }
      let(:pods) { [kube_pod(name: nil, status: 'Running')] }
      let(:params) { combine(generation(1, 1, wanted_replicas)) }

      it 'returns not spawned pods as pending and unknown and running' do
        expected = [
          { status: 'running', pod_name: 'generated-name-with-suffix', tooltip: 'generated-name-with-suffix (Running)', track: 'stable', stable: true },
          { status: 'pending', pod_name: 'Not provided', tooltip: 'Not provided (Pending)', track: 'stable', stable: true },
          { status: 'pending', pod_name: 'Not provided', tooltip: 'Not provided (Pending)', track: 'stable', stable: true }
        ]

        expect(deployment.instances).to eq(expected)
      end
    end

    context 'when outdated' do
      let(:pods) do
        [
          kube_pod(status: 'Pending'),
          kube_pod(name: 'kube-pod1', status: 'Pending'),
          kube_pod(name: 'kube-pod2', status: 'Pending'),
          kube_pod(name: 'kube-pod3', status: 'Pending')
        ]
      end

      let(:params) { combine(named('foo'), generation(1, 0, 4)) }

      it 'returns all instances as named and waiting' do
        expected = [
          { status: 'pending', pod_name: 'kube-pod', tooltip: 'kube-pod (Pending)', track: 'stable', stable: true },
          { status: 'pending', pod_name: 'kube-pod1', tooltip: 'kube-pod1 (Pending)', track: 'stable', stable: true },
          { status: 'pending', pod_name: 'kube-pod2', tooltip: 'kube-pod2 (Pending)', track: 'stable', stable: true },
          { status: 'pending', pod_name: 'kube-pod3', tooltip: 'kube-pod3 (Pending)', track: 'stable', stable: true }
        ]

        expect(deployment.instances).to eq(expected)
      end
    end

    context 'with pods of each type' do
      let(:pods) do
        [
          kube_pod(status: 'Succeeded'),
          kube_pod(name: 'kube-pod1', status: 'Running'),
          kube_pod(name: 'kube-pod2', status: 'Pending'),
          kube_pod(name: 'kube-pod3', status: 'Pending')
        ]
      end

      let(:params) { combine(named('foo'), generation(1, 1, 4)) }

      it 'returns all instances' do
        expected = [
          { status: 'succeeded', pod_name: 'kube-pod', tooltip: 'kube-pod (Succeeded)', track: 'stable', stable: true },
          { status: 'running', pod_name: 'kube-pod1', tooltip: 'kube-pod1 (Running)', track: 'stable', stable: true },
          { status: 'pending', pod_name: 'kube-pod2', tooltip: 'kube-pod2 (Pending)', track: 'stable', stable: true },
          { status: 'pending', pod_name: 'kube-pod3', tooltip: 'kube-pod3 (Pending)', track: 'stable', stable: true }
        ]

        expect(deployment.instances).to eq(expected)
      end
    end

    context 'with track label' do
      let(:pods) { [kube_pod(status: 'Pending')] }
      let(:labels) { { 'track' => track } }
      let(:params) { combine(named('foo', labels), generation(1, 0, 1)) }

      context 'when marked as stable' do
        let(:track) { 'stable' }

        it 'returns all instances' do
          expected = [
            { status: 'pending', pod_name: 'kube-pod', tooltip: 'kube-pod (Pending)', track: 'stable', stable: true }
          ]

          expect(deployment.instances).to eq(expected)
        end
      end

      context 'when marked as canary' do
        let(:track) { 'canary' }
        let(:pods) { [kube_pod(status: 'Pending', track: track)] }

        it 'returns all instances' do
          expected = [
            { status: 'pending', pod_name: 'kube-pod', tooltip: 'kube-pod (Pending)', track: 'canary', stable: false }
          ]

          expect(deployment.instances).to eq(expected)
        end
      end
    end
  end

  def generation(expected, observed, replicas)
    combine(
      make('metadata', 'generation' => expected),
      make('status', 'observedGeneration' => observed),
      make('spec', 'replicas' => replicas)
    )
  end

  def named(name = "foo", labels = {})
    make('metadata', 'name' => name, 'labels' => labels)
  end

  def make(key, values = {})
    hsh = {}
    hsh[key] = values
    hsh
  end

  def combine(*hashes)
    out = {}
    hashes.each { |hsh| out = out.deep_merge(hsh) }
    out
  end
end
