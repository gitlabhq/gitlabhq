require 'spec_helper'

describe Ci::FetchKubernetesTokenService do
  describe '#execute' do
    subject { described_class.new(api_url, ca_pem, username, password).execute }

    let(:api_url) { 'http://111.111.111.111' }
    let(:ca_pem) { '' }
    let(:username) { 'admin' }
    let(:password) { 'xxx' }

    context 'when params correct' do
      let(:token) { 'xxx.token.xxx' }

      let(:secrets_json) do
        [
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

      context 'when default-token exists' do
        let(:metadata_name) { 'default-token-123' }

        it { is_expected.to eq(token) }
      end

      context 'when default-token does not exist' do
        let(:metadata_name) { 'another-token-123' }

        it { is_expected.to be_nil }
      end
    end

    context 'when api_url is nil' do
      let(:api_url) { nil }

      it { expect { subject }.to raise_error("Incomplete settings") }
    end

    context 'when username is nil' do
      let(:username) { nil }

      it { expect { subject }.to raise_error("Incomplete settings") }
    end

    context 'when password is nil' do
      let(:password) { nil }

      it { expect { subject }.to raise_error("Incomplete settings") }
    end
  end
end
