require 'spec_helper'

describe Clusters::Gcp::Kubernetes::FetchKubernetesTokenService do
  describe '#execute' do
    subject { described_class.new(kubeclient).execute }

    let(:api_url) { 'http://111.111.111.111' }
    let(:username) { 'admin' }
    let(:password) { 'xxx' }
    let(:kubeclient) do
      Gitlab::Kubernetes::KubeClient.new(
        api_url,
        ['api', 'apis/rbac.authorization.k8s.io'],
        auth_options: { username: username, password: password }
      )
    end

    context 'when params correct' do
      let(:token) { 'xxx.token.xxx' }

      let(:secrets_json) do
        [
          {
            'metadata': {
              name: 'default-token-123'
            },
            'data': {
              'token': Base64.encode64('yyy.token.yyy')
            }
          },
          {
            'metadata': {
              name: metadata_name
            },
            'data': {
              'token': Base64.encode64(token)
            }
          }
        ]
      end

      before do
        allow_any_instance_of(Kubeclient::Client)
          .to receive(:get_secrets).and_return(secrets_json)
      end

      context 'when gitlab-token exists' do
        let(:metadata_name) { 'gitlab-token-123' }

        it { is_expected.to eq(token) }
      end

      context 'when gitlab-token does not exist' do
        let(:metadata_name) { 'another-token-123' }

        it { is_expected.to be_nil }
      end
    end
  end
end
