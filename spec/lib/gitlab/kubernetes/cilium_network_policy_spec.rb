# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kubernetes::CiliumNetworkPolicy do
  let(:policy) do
    described_class.new(
      name: name,
      namespace: namespace,
      creation_timestamp: '2020-04-14T00:08:30Z',
      endpoint_selector: endpoint_selector,
      ingress: ingress,
      egress: egress,
      description: description
    )
  end

  let(:resource) do
    ::Kubeclient::Resource.new(
      kind: partial_class_name,
      apiVersion: "cilium.io/v2",
      metadata: { name: name, namespace: namespace, resourceVersion: resource_version },
      spec: { endpointSelector: endpoint_selector, ingress: ingress }
    )
  end

  let(:name) { 'example-name' }
  let(:namespace) { 'example-namespace' }
  let(:endpoint_selector) { { matchLabels: { role: 'db' } } }
  let(:description) { 'example-description' }
  let(:partial_class_name) { described_class.name.split('::').last }
  let(:resource_version) { 101 }
  let(:ingress) do
    [
      {
        fromEndpoints: [
          { matchLabels: { project: 'myproject' } }
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

  include_examples 'network policy common specs' do
    let(:selector) { endpoint_selector}
    let(:policy) do
      described_class.new(
        name: name,
        namespace: namespace,
        selector: selector,
        ingress: ingress,
        labels: labels,
        resource_version: resource_version
      )
    end

    let(:spec) { { endpointSelector: selector, ingress: ingress } }
    let(:metadata) { { name: name, namespace: namespace, resourceVersion: resource_version } }
  end

  describe '#generate' do
    subject { policy.generate }

    it { is_expected.to eq(resource) }
  end

  describe '.from_yaml' do
    let(:manifest) do
      <<~POLICY
        apiVersion: cilium.io/v2
        kind: CiliumNetworkPolicy
        metadata:
          name: example-name
          namespace: example-namespace
          resourceVersion: 101
        spec:
          endpointSelector:
            matchLabels:
              role: db
          ingress:
          - fromEndpoints:
            - matchLabels:
                project: myproject
      POLICY
    end

    subject { Gitlab::Kubernetes::CiliumNetworkPolicy.from_yaml(manifest)&.generate }

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
        apiVersion: cilium.io/v2
        kind: CiliumNetworkPolicy
        spec:
          endpointSelector:
            matchLabels:
              role: db
          ingress:
          - fromEndpoints:
              matchLabels:
                project: myproject
        POLICY
      end

      it { is_expected.to be_nil }
    end

    context 'with manifest without spec' do
      let(:manifest) do
        <<~POLICY
        apiVersion: cilium.io/v2
        kind: CiliumNetworkPolicy
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
        apiVersion: cilium.io/v2
        kind: CiliumNetworkPolicy
        metadata:
          name: example-name
          namespace: example-namespace
          creationTimestamp: 2020-04-14T00:08:30Z
        spec:
          endpointSelector:
            matchLabels:
              role: db
          ingress:
          - fromEndpoints:
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
          labels: { app: 'foo' }, resourceVersion: resource_version
        },
        spec: { endpointSelector: endpoint_selector, ingress: ingress, egress: nil, labels: nil, description: nil }
      )
    end

    let(:generated_resource) do
      ::Kubeclient::Resource.new(
        kind: partial_class_name,
        apiVersion: "cilium.io/v2",
        metadata: { name: name, namespace: namespace, resourceVersion: resource_version, labels: { app: 'foo' } },
        spec: { endpointSelector: endpoint_selector, ingress: ingress }
      )
    end

    subject { Gitlab::Kubernetes::CiliumNetworkPolicy.from_resource(resource)&.generate }

    it { is_expected.to eq(generated_resource) }

    context 'with nil resource' do
      let(:resource) { nil }

      it { is_expected.to be_nil }
    end

    context 'with resource without metadata' do
      let(:resource) do
        ::Kubeclient::Resource.new(
          spec: { endpointSelector: endpoint_selector, ingress: ingress, egress: nil, labels: nil, description: nil }
        )
      end

      it { is_expected.to be_nil }
    end

    context 'with resource without spec' do
      let(:resource) do
        ::Kubeclient::Resource.new(
          metadata: { name: name, namespace: namespace, uid: '128cf288-7de4-11ea-aceb-42010a800089', resourceVersion: resource_version }
        )
      end

      it { is_expected.to be_nil }
    end
  end
end
