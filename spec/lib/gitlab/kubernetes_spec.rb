require 'spec_helper'

describe Gitlab::Kubernetes do
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
      matching_items = [kube_pod(app: 'foo'), kube_deployment(app: 'foo')]
      items = matching_items + [kube_pod, kube_deployment]

      expect(filter_by_label(items, app: 'foo')).to eq(matching_items)
    end
  end
end
