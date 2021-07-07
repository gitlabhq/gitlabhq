# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kubernetes::NetworkPolicy do
  let(:policy) do
    described_class.new(
      name: name,
      namespace: namespace,
      selector: selector,
      ingress: ingress,
      labels: labels
    )
  end

  let(:resource) do
    ::Kubeclient::Resource.new(
      kind: Gitlab::Kubernetes::NetworkPolicy::KIND,
      metadata: { name: name, namespace: namespace },
      spec: { podSelector: pod_selector, policyTypes: %w(Ingress), ingress: ingress, egress: nil }
    )
  end

  let(:selector) { pod_selector }
  let(:labels) { nil }
  let(:name) { 'example-name' }
  let(:namespace) { 'example-namespace' }
  let(:pod_selector) { { matchLabels: { role: 'db' } } }

  let(:ingress) do
    [
      {
        from: [
          { namespaceSelector: { matchLabels: { project: 'myproject' } } }
        ]
      }
    ]
  end

  let(:egress) do
    [
      {
        ports: [{ port: 5978 }]
      }
    ]
  end

  include_examples 'network policy common specs'

  describe '.from_yaml' do
    let(:manifest) do
      <<~POLICY
        apiVersion: networking.k8s.io/v1
        kind: NetworkPolicy
        metadata:
          name: example-name
          namespace: example-namespace
        spec:
          podSelector:
            matchLabels:
              role: db
          policyTypes:
          - Ingress
          ingress:
          - from:
            - namespaceSelector:
                matchLabels:
                  project: myproject
      POLICY
    end

    subject { Gitlab::Kubernetes::NetworkPolicy.from_yaml(manifest)&.generate }

    it { is_expected.to eq(resource) }

    context 'with nil manifest' do
      let(:manifest) { nil }

      it { is_expected.to be_nil }
    end

    context 'with invalid manifest' do
      let(:manifest) { "\tfoo: bar" }

      it { is_expected.to be_nil }
    end

    context 'with manifest without metadata' do
      let(:manifest) do
        <<~POLICY
        apiVersion: networking.k8s.io/v1
        kind: NetworkPolicy
        spec:
          podSelector:
            matchLabels:
              role: db
          policyTypes:
          - Ingress
          ingress:
          - from:
            - namespaceSelector:
                matchLabels:
                  project: myproject
        POLICY
      end

      it { is_expected.to be_nil }
    end

    context 'with manifest without spec' do
      let(:manifest) do
        <<~POLICY
        apiVersion: networking.k8s.io/v1
        kind: NetworkPolicy
        metadata:
          name: example-name
          namespace: example-namespace
        POLICY
      end

      it { is_expected.to be_nil }
    end

    context 'with disallowed class' do
      let(:manifest) do
        <<~POLICY
        apiVersion: networking.k8s.io/v1
        kind: NetworkPolicy
        metadata:
          name: example-name
          namespace: example-namespace
          creationTimestamp: 2020-04-14T00:08:30Z
        spec:
          podSelector:
            matchLabels:
              role: db
          policyTypes:
          - Ingress
          ingress:
          - from:
            - namespaceSelector:
                matchLabels:
                  project: myproject
        POLICY
      end

      it { is_expected.to be_nil }
    end
  end

  describe '.from_resource' do
    let(:resource) do
      ::Kubeclient::Resource.new(
        metadata: {
          name: name, namespace: namespace, creationTimestamp: '2020-04-14T00:08:30Z',
          labels: { app: 'foo' }, resourceVersion: '4990'
        },
        spec: { podSelector: pod_selector, policyTypes: %w(Ingress), ingress: ingress, egress: nil }
      )
    end

    let(:generated_resource) do
      ::Kubeclient::Resource.new(
        kind: Gitlab::Kubernetes::NetworkPolicy::KIND,
        metadata: { name: name, namespace: namespace, labels: { app: 'foo' } },
        spec: { podSelector: pod_selector, policyTypes: %w(Ingress), ingress: ingress, egress: nil }
      )
    end

    subject { Gitlab::Kubernetes::NetworkPolicy.from_resource(resource)&.generate }

    it { is_expected.to eq(generated_resource) }

    context 'with nil resource' do
      let(:resource) { nil }

      it { is_expected.to be_nil }
    end

    context 'with resource without metadata' do
      let(:resource) do
        ::Kubeclient::Resource.new(
          spec: { podSelector: pod_selector, policyTypes: %w(Ingress), ingress: ingress, egress: nil }
        )
      end

      it { is_expected.to be_nil }
    end

    context 'with resource without spec' do
      let(:resource) do
        ::Kubeclient::Resource.new(
          metadata: { name: name, namespace: namespace, uid: '128cf288-7de4-11ea-aceb-42010a800089', resourceVersion: '4990' }
        )
      end

      it { is_expected.to be_nil }
    end

    context 'with environment_ids' do
      subject { Gitlab::Kubernetes::NetworkPolicy.from_resource(resource, [1, 2, 3]) }

      it 'includes environment_ids in as_json result' do
        expect(subject.as_json).to include(environment_ids: [1, 2, 3])
      end
    end
  end

  describe '#resource' do
    subject { policy.resource }

    let(:resource) do
      {
        kind: Gitlab::Kubernetes::NetworkPolicy::KIND,
        metadata: { name: name, namespace: namespace },
        spec: { podSelector: pod_selector, policyTypes: %w(Ingress), ingress: ingress, egress: nil }
      }
    end

    it { is_expected.to eq(resource) }

    context 'with labels' do
      let(:labels) { { app: 'foo' } }
      let(:resource) do
        {
          kind: Gitlab::Kubernetes::NetworkPolicy::KIND,
          metadata: { name: name, namespace: namespace, labels: { app: 'foo' } },
          spec: { podSelector: pod_selector, policyTypes: %w(Ingress), ingress: ingress, egress: nil }
        }
      end

      it { is_expected.to eq(resource) }
    end
  end
end
