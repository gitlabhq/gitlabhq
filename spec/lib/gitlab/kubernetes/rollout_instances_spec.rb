# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kubernetes::RolloutInstances do
  include KubernetesHelpers

  def setup(deployments_attrs, pods_attrs)
    deployments = deployments_attrs.map do |attrs|
      ::Gitlab::Kubernetes::Deployment.new(attrs, pods: pods_attrs)
    end

    pods = pods_attrs.map do |attrs|
      ::Gitlab::Kubernetes::Pod.new(attrs)
    end

    [deployments, pods]
  end

  describe '#pod_instances' do
    it 'returns an instance for a deployment with one pod' do
      deployments, pods = setup(
        [kube_deployment(name: 'one', track: 'stable', replicas: 1)],
        [kube_pod(name: 'one', status: 'Running', track: 'stable')]
      )
      rollout_instances = described_class.new(deployments, pods)

      expect(rollout_instances.pod_instances).to eq([{
        pod_name: 'one',
        stable: true,
        status: 'running',
        tooltip: 'one (Running)',
        track: 'stable'
      }])
    end

    it 'returns a pending pod for a missing replica' do
      deployments, pods = setup(
        [kube_deployment(name: 'one', track: 'stable', replicas: 1)],
        []
      )
      rollout_instances = described_class.new(deployments, pods)

      expect(rollout_instances.pod_instances).to eq([{
        pod_name: 'Not provided',
        stable: true,
        status: 'pending',
        tooltip: 'Not provided (Pending)',
        track: 'stable'
      }])
    end

    it 'returns instances when there are two stable deployments' do
      deployments, pods = setup(
        [
          kube_deployment(name: 'one', track: 'stable', replicas: 1),
          kube_deployment(name: 'two', track: 'stable', replicas: 1)
        ], [
          kube_pod(name: 'one', status: 'Running', track: 'stable'),
          kube_pod(name: 'two', status: 'Running', track: 'stable')
        ])
      rollout_instances = described_class.new(deployments, pods)

      expect(rollout_instances.pod_instances).to eq([{
        pod_name: 'one',
        stable: true,
        status: 'running',
        tooltip: 'one (Running)',
        track: 'stable'
      }, {
        pod_name: 'two',
        stable: true,
        status: 'running',
        tooltip: 'two (Running)',
        track: 'stable'
      }])
    end

    it 'returns instances for two deployments with different tracks' do
      deployments, pods = setup(
        [
          kube_deployment(name: 'one', track: 'mytrack', replicas: 1),
          kube_deployment(name: 'two', track: 'othertrack', replicas: 1)
        ], [
          kube_pod(name: 'one', status: 'Running', track: 'mytrack'),
          kube_pod(name: 'two', status: 'Running', track: 'othertrack')
        ])
      rollout_instances = described_class.new(deployments, pods)

      expect(rollout_instances.pod_instances).to eq([{
        pod_name: 'one',
        stable: false,
        status: 'running',
        tooltip: 'one (Running)',
        track: 'mytrack'
      }, {
        pod_name: 'two',
        stable: false,
        status: 'running',
        tooltip: 'two (Running)',
        track: 'othertrack'
      }])
    end

    it 'sorts stable tracks after canary tracks' do
      deployments, pods = setup(
        [
          kube_deployment(name: 'one', track: 'stable', replicas: 1),
          kube_deployment(name: 'two', track: 'canary', replicas: 1)
        ], [
          kube_pod(name: 'one', status: 'Running', track: 'stable'),
          kube_pod(name: 'two', status: 'Running', track: 'canary')
        ])
      rollout_instances = described_class.new(deployments, pods)

      expect(rollout_instances.pod_instances).to eq([{
        pod_name: 'two',
        stable: false,
        status: 'running',
        tooltip: 'two (Running)',
        track: 'canary'
      }, {
        pod_name: 'one',
        stable: true,
        status: 'running',
        tooltip: 'one (Running)',
        track: 'stable'
      }])
    end
  end
end
