# frozen_string_literal: true

RSpec.shared_examples 'network policy common specs' do
  let(:name) { 'example-name' }
  let(:namespace) { 'example-namespace' }
  let(:labels) { nil }

  describe '#generate' do
    subject { policy.generate }

    it { is_expected.to eq(Kubeclient::Resource.new(policy.resource)) }
  end

  describe 'as_json' do
    let(:json_policy) do
      {
        name: name,
        namespace: namespace,
        creation_timestamp: nil,
        manifest: YAML.dump(policy.resource.deep_stringify_keys),
        is_autodevops: false,
        is_enabled: true,
        environment_ids: []
      }
    end

    subject { policy.as_json }

    it { is_expected.to eq(json_policy) }
  end

  describe 'autodevops?' do
    subject { policy.autodevops? }

    let(:labels) { { chart: chart } }
    let(:chart) { nil }

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

  describe 'enabled?' do
    subject { policy.enabled? }

    let(:selector) { nil }

    it { is_expected.to be true }

    context 'with empty selector' do
      let(:selector) { {} }

      it { is_expected.to be true }
    end

    context 'with nil matchLabels in selector' do
      let(:selector) { { matchLabels: nil } }

      it { is_expected.to be true }
    end

    context 'with empty matchLabels in selector' do
      let(:selector) { { matchLabels: {} } }

      it { is_expected.to be true }
    end

    context 'with disabled_by label in matchLabels in selector' do
      let(:selector) do
        { matchLabels: { Gitlab::Kubernetes::NetworkPolicyCommon::DISABLED_BY_LABEL => 'gitlab' } }
      end

      it { is_expected.to be false }
    end
  end

  describe 'enable' do
    subject { policy.enabled? }

    let(:selector) { nil }

    before do
      policy.enable
    end

    it { is_expected.to be true }

    context 'with empty selector' do
      let(:selector) { {} }

      it { is_expected.to be true }
    end

    context 'with nil matchLabels in selector' do
      let(:selector) { { matchLabels: nil } }

      it { is_expected.to be true }
    end

    context 'with empty matchLabels in selector' do
      let(:selector) { { matchLabels: {} } }

      it { is_expected.to be true }
    end

    context 'with disabled_by label in matchLabels in selector' do
      let(:selector) do
        { matchLabels: { Gitlab::Kubernetes::NetworkPolicyCommon::DISABLED_BY_LABEL => 'gitlab' } }
      end

      it { is_expected.to be true }
    end
  end

  describe 'disable' do
    subject { policy.enabled? }

    let(:selector) { nil }

    before do
      policy.disable
    end

    it { is_expected.to be false }

    context 'with empty selector' do
      let(:selector) { {} }

      it { is_expected.to be false }
    end

    context 'with nil matchLabels in selector' do
      let(:selector) { { matchLabels: nil } }

      it { is_expected.to be false }
    end

    context 'with empty matchLabels in selector' do
      let(:selector) { { matchLabels: {} } }

      it { is_expected.to be false }
    end

    context 'with disabled_by label in matchLabels in selector' do
      let(:selector) do
        { matchLabels: { Gitlab::Kubernetes::NetworkPolicyCommon::DISABLED_BY_LABEL => 'gitlab' } }
      end

      it { is_expected.to be false }
    end
  end
end
