require 'fast_spec_helper'

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
      let(:decoded_token) { 'xxx.token.xxx' }
      let(:token) { Base64.encode64(decoded_token) }

      let(:secret_json) do
        {
          'metadata': {
            name: 'gitlab-token'
          },
          'data': {
            'token': token
          }
        }
      end

      before do
        allow_any_instance_of(Kubeclient::Client)
          .to receive(:get_secret).and_return(secret_json)
      end

      context 'when gitlab-token exists' do
        let(:metadata_name) { 'gitlab-token' }

        it { is_expected.to eq(decoded_token) }
      end

      context 'when gitlab-token does not exist' do
        let(:secret_json) { {} }

        it { is_expected.to be_nil }
      end

      context 'when token is nil' do
        let(:token) { nil }

        it { is_expected.to be_nil }
      end
    end
  end
end
