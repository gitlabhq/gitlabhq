# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Kubernetes::FetchKubernetesTokenService do
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

    subject { described_class.new(kubeclient, service_account_token_name, namespace, token_retry_delay: 0).execute }

    before do
      stub_kubeclient_discover(api_url)
    end

    context 'when params correct' do
      let(:decoded_token) { 'xxx.token.xxx' }
      let(:token) { Base64.encode64(decoded_token) }

      context 'when the secret exists' do
        before do
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

      context 'when there is a 500 error' do
        before do
          stub_kubeclient_get_secret_error(api_url, service_account_token_name, namespace: namespace, status: 500)
        end

        it { expect { subject }.to raise_error(Kubeclient::HttpError) }
      end

      context 'when the secret does not exist on the first try' do
        before do
          stub_kubeclient_get_secret_not_found_then_found(
            api_url,
            {
              metadata_name: service_account_token_name,
              namespace: namespace,
              token: token
            }
          )
        end

        it 'retries and finds the token' do
          expect(subject).to eq(decoded_token)
        end
      end

      context 'when the secret permanently does not exist' do
        before do
          stub_kubeclient_get_secret_error(api_url, service_account_token_name, namespace: namespace, status: 404)
        end

        it { is_expected.to be_nil }
      end

      context 'when the secret is missing a token on the first try' do
        before do
          stub_kubeclient_get_secret_missing_token_then_with_token(
            api_url,
            {
              metadata_name: service_account_token_name,
              namespace: namespace,
              token: token
            }
          )
        end

        it 'retries and finds the token' do
          expect(subject).to eq(decoded_token)
        end
      end

      context 'when the secret is permanently missing a token' do
        before do
          stub_kubeclient_get_secret(
            api_url,
            {
              metadata_name: service_account_token_name,
              namespace: namespace,
              token: nil
            }
          )
        end

        it { is_expected.to be_nil }
      end
    end
  end
end
