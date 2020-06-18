# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Kubernetes::NetworkPolicy do
  let(:policy) do
    described_class.new(
      name: name,
      namespace: namespace,
      creation_timestamp: '2020-04-14T00:08:30Z',
      pod_selector: pod_selector,
      policy_types: %w(Ingress Egress),
      ingress: ingress,
      egress: egress
    )
  end

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

  describe '.from_yaml' do
    let(:manifest) do
      <<~POLICY
        apiVersion: networking.k8s.io/v1
        kind: NetworkPolicy
        metadata:
          name: example-name
          namespace: example-namespace
          labels:
            app: foo
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
    let(:resource) do
      ::Kubeclient::Resource.new(
        metadata: { name: name, namespace: namespace, labels: { app: 'foo' } },
        spec: { podSelector: pod_selector, policyTypes: %w(Ingress), ingress: ingress, egress: nil }
      )
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
  end

  describe '#generate' do
    let(:resource) do
      ::Kubeclient::Resource.new(
        metadata: { name: name, namespace: namespace },
        spec: { podSelector: pod_selector, policyTypes: %w(Ingress Egress), ingress: ingress, egress: egress }
      )
    end

    subject { policy.generate }

    it { is_expected.to eq(resource) }
  end

  describe '#as_json' do
    let(:json_policy) do
      {
        name: name,
        namespace: namespace,
        creation_timestamp: '2020-04-14T00:08:30Z',
        manifest: YAML.dump(
          {
            metadata: { name: name, namespace: namespace },
            spec: { podSelector: pod_selector, policyTypes: %w(Ingress Egress), ingress: ingress, egress: egress }
          }.deep_stringify_keys
        ),
        is_autodevops: false,
        is_enabled: true
      }
    end

    subject { policy.as_json }

    it { is_expected.to eq(json_policy) }
  end

  describe '#autodevops?' do
    subject { policy.autodevops? }

    let(:chart) { nil }
    let(:policy) do
      described_class.new(
        name: name,
        namespace: namespace,
        labels: { chart: chart },
        pod_selector: pod_selector,
        ingress: ingress
      )
    end

    it { is_expected.to be false }

    context 'with non-autodevops chart' do
      let(:chart) { 'foo' }

      it { is_expected.to be false }
    end

    context 'with autodevops chart' do
      let(:chart) { 'auto-deploy-app-0.6.0' }

      it { is_expected.to be true }
    end
  end

  describe '#enabled?' do
    subject { policy.enabled? }

    let(:pod_selector) { nil }
    let(:policy) do
      described_class.new(
        name: name,
        namespace: namespace,
        pod_selector: pod_selector,
        ingress: ingress
      )
    end

    it { is_expected.to be true }

    context 'with empty pod_selector' do
      let(:pod_selector) { {} }

      it { is_expected.to be true }
    end

    context 'with nil matchLabels in pod_selector' do
      let(:pod_selector) { { matchLabels: nil } }

      it { is_expected.to be true }
    end

    context 'with empty matchLabels in pod_selector' do
      let(:pod_selector) { { matchLabels: {} } }

      it { is_expected.to be true }
    end

    context 'with disabled_by label in matchLabels in pod_selector' do
      let(:pod_selector) do
        { matchLabels: { Gitlab::Kubernetes::NetworkPolicy::DISABLED_BY_LABEL => 'gitlab' } }
      end

      it { is_expected.to be false }
    end
  end

  describe '#enable' do
    subject { policy.enabled? }

    let(:pod_selector) { nil }
    let(:policy) do
      described_class.new(
        name: name,
        namespace: namespace,
        pod_selector: pod_selector,
        ingress: ingress
      )
    end

    before do
      policy.enable
    end

    it { is_expected.to be true }

    context 'with empty pod_selector' do
      let(:pod_selector) { {} }

      it { is_expected.to be true }
    end

    context 'with nil matchLabels in pod_selector' do
      let(:pod_selector) { { matchLabels: nil } }

      it { is_expected.to be true }
    end

    context 'with empty matchLabels in pod_selector' do
      let(:pod_selector) { { matchLabels: {} } }

      it { is_expected.to be true }
    end

    context 'with disabled_by label in matchLabels in pod_selector' do
      let(:pod_selector) do
        { matchLabels: { Gitlab::Kubernetes::NetworkPolicy::DISABLED_BY_LABEL => 'gitlab' } }
      end

      it { is_expected.to be true }
    end
  end

  describe '#disable' do
    subject { policy.enabled? }

    let(:pod_selector) { nil }
    let(:policy) do
      described_class.new(
        name: name,
        namespace: namespace,
        pod_selector: pod_selector,
        ingress: ingress
      )
    end

    before do
      policy.disable
    end

    it { is_expected.to be false }

    context 'with empty pod_selector' do
      let(:pod_selector) { {} }

      it { is_expected.to be false }
    end

    context 'with nil matchLabels in pod_selector' do
      let(:pod_selector) { { matchLabels: nil } }

      it { is_expected.to be false }
    end

    context 'with empty matchLabels in pod_selector' do
      let(:pod_selector) { { matchLabels: {} } }

      it { is_expected.to be false }
    end

    context 'with disabled_by label in matchLabels in pod_selector' do
      let(:pod_selector) do
        { matchLabels: { Gitlab::Kubernetes::NetworkPolicy::DISABLED_BY_LABEL => 'gitlab' } }
      end

      it { is_expected.to be false }
    end
  end
end
