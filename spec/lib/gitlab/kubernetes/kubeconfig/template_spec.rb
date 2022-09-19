# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Kubernetes::Kubeconfig::Template do
  let(:template) { described_class.new }

  describe '#valid?' do
    subject { template.valid? }

    it { is_expected.to be_falsey }

    context 'with configuration added' do
      before do
        template.add_context(name: 'name', cluster: 'cluster', user: 'user')
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '#to_h' do
    subject { described_class.new.to_h }

    it do
      is_expected.to eq(
        apiVersion: 'v1',
        kind: 'Config',
        clusters: [],
        users: [],
        contexts: []
      )
    end
  end

  describe '#to_yaml' do
    subject { template.to_yaml }

    it { is_expected.to eq(YAML.dump(template.to_h.deep_stringify_keys)) }
  end

  describe '#merge_yaml' do
    it 'appends to the configuration and overwrites the current context' do
      template.add_cluster(name: 'hello-cluster', url: 'hello-url')
      template.add_context(name: 'hello-context', cluster: 'hello-cluster', user: 'hello-user')
      template.add_user(name: 'hello-user', token: 'hello-token')
      ca_pem = Base64.strict_encode64('a certificate')
      template.merge_yaml(<<~YAML)
        apiVersion: v1
        kind: Config
        clusters:
          - name: 'gitlab-deploy'
            cluster:
              server: url
              certificate-authority-data: #{ca_pem.inspect}
        contexts:
          - name: gitlab-deploy
            context:
              cluster: gitlab-deploy
              namespace: namespace
              user: gitlab-deploy
        current-context: gitlab-deploy
        users:
          - name: 'gitlab-deploy'
            user: { token: token }
      YAML
      expect(template.to_h).to eq({
        apiVersion: 'v1',
        kind: 'Config',
        clusters: [
          { name: 'hello-cluster', cluster: { server: 'hello-url' } },
          { name: 'gitlab-deploy', cluster: { server: 'url', 'certificate-authority-data': ca_pem } }
        ],
        contexts: [
          { name: 'hello-context', context: { cluster: 'hello-cluster', user: 'hello-user' } },
          { name: 'gitlab-deploy', context: { cluster: 'gitlab-deploy', namespace: 'namespace', user: 'gitlab-deploy' } }
        ],
        users: [
          { name: 'hello-user', user: { token: 'hello-token' } },
          { name: 'gitlab-deploy', user: { token: 'token' } }
        ],
        'current-context': 'gitlab-deploy'
      })
    end
  end

  describe 'adding entries' do
    let(:entry) { instance_double(entry_class, to_h: attributes) }
    let(:attributes) do
      { name: 'name', other: 'other' }
    end

    subject { template.to_h }

    before do
      expect(entry_class).to receive(:new).with(attributes).and_return(entry)
    end

    describe '#add_cluster' do
      let(:entry_class) { Gitlab::Kubernetes::Kubeconfig::Entry::Cluster }

      before do
        template.add_cluster(**attributes)
      end

      it { is_expected.to include(clusters: [attributes]) }
    end

    describe '#add_user' do
      let(:entry_class) { Gitlab::Kubernetes::Kubeconfig::Entry::User }

      before do
        template.add_user(**attributes)
      end

      it { is_expected.to include(users: [attributes]) }
    end

    describe '#add_context' do
      let(:entry_class) { Gitlab::Kubernetes::Kubeconfig::Entry::Context }

      before do
        template.add_context(**attributes)
      end

      it { is_expected.to include(contexts: [attributes]) }
    end
  end
end
