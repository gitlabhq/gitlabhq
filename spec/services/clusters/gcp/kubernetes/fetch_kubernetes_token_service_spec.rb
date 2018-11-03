# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Gcp::Kubernetes::FetchKubernetesTokenService do
  include KubernetesHelpers

  describe '#execute' do
    let(:api_url) { 'http://111.111.111.111' }
    let(:namespace) { 'my-namespace' }
    let(:service_account_token_name) { 'gitlab-token' }

    let(:kubeclient) do
      Gitlab::Kubernetes::KubeClient.new(
        api_url,
        auth_options: { username: 'admin', password: 'xxx' }
      )
    end

    subject { described_class.new(kubeclient, service_account_token_name, namespace).execute }

    context 'when params correct' do
      let(:decoded_token) { 'xxx.token.xxx' }
      let(:token) { Base64.encode64(decoded_token) }

      context 'when gitlab-token exists' do
        before do
          stub_kubeclient_discover(api_url)
          stub_kubeclient_get_secret(
            api_url,
            {
              metadata_name: service_account_token_name,
              namespace: namespace,
              token: token
            }
          )
        end

        it { is_expected.to eq(decoded_token) }
      end

      context 'when gitlab-token does not exist' do
        before do
          allow(kubeclient).to receive(:get_secret).and_raise(Kubeclient::HttpError.new(404, 'Not found', nil))
        end

        it { is_expected.to be_nil }
      end
    end
  end
end
