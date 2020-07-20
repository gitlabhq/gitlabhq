# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kubernetes do
  include KubernetesHelpers
  include described_class

  describe '#container_exec_url' do
    let(:api_url) { 'https://example.com' }
    let(:namespace) { 'default' }
    let(:pod_name) { 'pod1' }
    let(:container_name) { 'container1' }

    subject(:result) { URI.parse(container_exec_url(api_url, namespace, pod_name, container_name)) }

    it { expect(result.scheme).to eq('wss') }
    it { expect(result.host).to eq('example.com') }
    it { expect(result.path).to eq('/api/v1/namespaces/default/pods/pod1/exec') }
    it { expect(result.query).to eq('container=container1&stderr=true&stdin=true&stdout=true&tty=true&command=sh&command=-c&command=bash+%7C%7C+sh') }

    context 'with a HTTP API URL' do
      let(:api_url) { 'http://example.com' }

      it { expect(result.scheme).to eq('ws') }
    end

    context 'with a path prefix in the API URL' do
      let(:api_url) { 'https://example.com/prefix/' }

      it { expect(result.path).to eq('/prefix/api/v1/namespaces/default/pods/pod1/exec') }
    end

    context 'with arguments that need urlencoding' do
      let(:namespace) { 'default namespace' }
      let(:pod_name) { 'pod 1' }
      let(:container_name) { 'container 1' }

      it { expect(result.path).to eq('/api/v1/namespaces/default%20namespace/pods/pod%201/exec') }
      it { expect(result.query).to match(/\Acontainer=container\+1&/) }
    end
  end

  describe '#filter_by_label' do
    it 'returns matching labels' do
      matching_items = [kube_pod(track: 'foo'), kube_deployment(track: 'foo')]
      items = matching_items + [kube_pod, kube_deployment]

      expect(filter_by_label(items, 'track' => 'foo')).to eq(matching_items)
    end
  end

  describe '#filter_by_annotation' do
    it 'returns matching labels' do
      matching_items = [kube_pod(environment_slug: 'foo'), kube_deployment(environment_slug: 'foo')]
      items = matching_items + [kube_pod, kube_deployment]

      expect(filter_by_annotation(items, 'app.gitlab.com/env' => 'foo')).to eq(matching_items)
    end
  end

  describe '#filter_by_project_environment' do
    let(:matching_pod) { kube_pod(environment_slug: 'production', project_slug: 'my-cool-app') }

    it 'returns matching env label' do
      matching_items = [matching_pod]
      items = matching_items + [kube_pod]

      expect(filter_by_project_environment(items, 'my-cool-app', 'production')).to eq(matching_items)
    end
  end

  describe '#filter_by_legacy_label' do
    let(:non_matching_pod) { kube_pod(environment_slug: 'production', project_slug: 'my-cool-app') }

    let(:non_matching_pod_2) do
      kube_pod(environment_slug: 'production', project_slug: 'my-cool-app').tap do |pod|
        pod['metadata']['labels']['app'] = 'production'
      end
    end

    let(:matching_pod) do
      kube_pod.tap do |pod|
        pod['metadata']['annotations'].delete('app.gitlab.com/env')
        pod['metadata']['annotations'].delete('app.gitlab.com/app')
        pod['metadata']['labels']['app'] = 'production'
      end
    end

    it 'returns matching labels' do
      items = [non_matching_pod, non_matching_pod_2, matching_pod]

      expect(filter_by_legacy_label(items, 'my-cool-app', 'production')).to contain_exactly(matching_pod)
    end
  end

  describe '#to_kubeconfig' do
    let(:token) { 'TOKEN' }
    let(:ca_pem) { 'PEM' }

    subject do
      to_kubeconfig(
        url: 'https://kube.domain.com',
        namespace: 'NAMESPACE',
        token: token,
        ca_pem: ca_pem
      )
    end

    it { expect(YAML.safe_load(subject)).to eq(YAML.load_file(expand_fixture_path('config/kubeconfig.yml'))) }

    context 'when CA PEM is not provided' do
      let(:ca_pem) { nil }

      it { expect(YAML.safe_load(subject)).to eq(YAML.load_file(expand_fixture_path('config/kubeconfig-without-ca.yml'))) }
    end

    context 'when token is not provided' do
      let(:token) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe '#add_terminal_auth' do
    it 'adds authentication parameters to a hash' do
      terminal = { original: 'value' }

      add_terminal_auth(terminal, token: 'foo', max_session_time: 0, ca_pem: 'bar')

      expect(terminal).to eq(
        original: 'value',
        headers: { 'Authorization' => ['Bearer foo'] },
        max_session_time: 0,
        ca_pem: 'bar'
      )
    end
  end
end
