# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kubernetes::CiliumNetworkPolicy do
  let(:policy) do
    described_class.new(
      name: name,
      namespace: namespace,
      description: description,
      selector: selector,
      ingress: ingress,
      egress: egress,
      labels: labels,
      resource_version: resource_version,
      annotations: annotations
    )
  end

  let(:resource) do
    ::Kubeclient::Resource.new(
      apiVersion: Gitlab::Kubernetes::CiliumNetworkPolicy::API_VERSION,
      kind: Gitlab::Kubernetes::CiliumNetworkPolicy::KIND,
      metadata: { name: name, namespace: namespace, resourceVersion: resource_version, annotations: annotations },
      spec: { endpointSelector: endpoint_selector, ingress: ingress, egress: egress },
      description: description
    )
  end

  let(:selector) { endpoint_selector }
  let(:labels) { nil }
  let(:name) { 'example-name' }
  let(:namespace) { 'example-namespace' }
  let(:endpoint_selector) { { matchLabels: { role: 'db' } } }
  let(:description) { 'example-description' }
  let(:partial_class_name) { described_class.name.split('::').last }
  let(:resource_version) { 101 }
  let(:annotations) { { 'app.gitlab.com/alert': 'true' } }
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

  include_examples 'network policy common specs'

  describe '.from_yaml' do
    let(:manifest) do
      <<~POLICY
        apiVersion: cilium.io/v2
        kind: CiliumNetworkPolicy
        description: example-description
        metadata:
          name: example-name
          namespace: example-namespace
          resourceVersion: 101
          annotations:
            app.gitlab.com/alert: "true"
        spec:
          endpointSelector:
            matchLabels:
              role: db
          ingress:
          - fromEndpoints:
            - matchLabels:
                project: myproject
          egress:
          - ports:
            - port: 5978
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
        description: description,
        metadata: {
          name: name, namespace: namespace, creationTimestamp: '2020-04-14T00:08:30Z',
          labels: { app: 'foo' }, resourceVersion: resource_version, annotations: annotations
        },
        spec: { endpointSelector: endpoint_selector, ingress: ingress, egress: nil, labels: nil }
      )
    end

    let(:generated_resource) do
      ::Kubeclient::Resource.new(
        apiVersion: Gitlab::Kubernetes::CiliumNetworkPolicy::API_VERSION,
        kind: Gitlab::Kubernetes::CiliumNetworkPolicy::KIND,
        description: description,
        metadata: { name: name, namespace: namespace, resourceVersion: resource_version, labels: { app: 'foo' }, annotations: annotations },
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
          spec: { endpointSelector: endpoint_selector, ingress: ingress, egress: nil, labels: nil }
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

    context 'with environment_ids' do
      subject { Gitlab::Kubernetes::CiliumNetworkPolicy.from_resource(resource, [1, 2, 3]) }

      it 'includes environment_ids in as_json result' do
        expect(subject.as_json).to include(environment_ids: [1, 2, 3])
      end
    end
  end

  describe '#resource' do
    subject { policy.resource }

    let(:resource) do
      {
        apiVersion: Gitlab::Kubernetes::CiliumNetworkPolicy::API_VERSION,
        kind: Gitlab::Kubernetes::CiliumNetworkPolicy::KIND,
        metadata: { name: name, namespace: namespace, resourceVersion: resource_version, annotations: annotations },
        spec: { endpointSelector: endpoint_selector, ingress: ingress, egress: egress },
        description: description
      }
    end

    it { is_expected.to eq(resource) }

    context 'with labels' do
      let(:labels) { { app: 'foo' } }

      before do
        resource[:metadata][:labels] = { app: 'foo' }
      end

      it { is_expected.to eq(resource) }
    end

    context 'without resource_version' do
      let(:resource_version) { nil }

      before do
        resource[:metadata].delete(:resourceVersion)
      end

      it { is_expected.to eq(resource) }
    end

    context 'with nil egress' do
      let(:egress) { nil }

      before do
        resource[:spec].delete(:egress)
      end

      it { is_expected.to eq(resource) }
    end

    context 'without annotations' do
      let(:annotations) { nil }

      before do
        resource[:metadata].delete(:annotations)
      end

      it { is_expected.to eq(resource) }
    end
  end
end
