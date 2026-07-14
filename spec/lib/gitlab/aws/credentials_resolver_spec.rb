# frozen_string_literal: true

require 'fast_spec_helper'
require 'aws-sdk-core'

RSpec.describe Gitlab::Aws::CredentialsResolver, feature_category: :integrations do
  let(:region) { 'us-east-1' }
  let(:role_session_name) { 'gitlab_test' }

  subject(:credentials) { described_class.resolve(**config) }

  before do
    described_class.clear_memoization(:credential_provider_chain)
  end

  describe '#resolve' do
    context 'when a role ARN is set' do
      let(:role_arn) { 'arn:aws:iam::123456789012:role/example' }
      let(:sts_client) { instance_double(Aws::STS::Client) }
      let(:assume_role_credentials) { instance_double(Aws::AssumeRoleCredentials) }

      let(:config) do
        {
          region: region,
          role_arn: role_arn,
          role_session_name: role_session_name,
          access_key_id: 'static-key',
          secret_access_key: 'static-secret'
        }
      end

      before do
        allow(Aws::STS::Client).to receive(:new).with(region: region).and_return(sts_client)
        allow(Aws::AssumeRoleCredentials).to receive(:new)
          .with(
            client: sts_client,
            role_arn: role_arn,
            role_session_name: role_session_name
          )
          .and_return(assume_role_credentials)
      end

      it 'returns assume-role credentials and ignores static keys', :aggregate_failures do
        expect(Aws::Credentials).not_to receive(:new)
        expect(Aws::CredentialProviderChain).not_to receive(:new)

        expect(credentials).to eq(assume_role_credentials)
      end
    end

    context 'when static access key and secret are set' do
      let(:static_credentials) { instance_double(Aws::Credentials, set?: true) }

      let(:config) do
        {
          region: region,
          access_key_id: 'AKIAEXAMPLE',
          secret_access_key: 'secret'
        }
      end

      before do
        allow(Aws::Credentials).to receive(:new)
          .with('AKIAEXAMPLE', 'secret')
          .and_return(static_credentials)
      end

      it 'returns static credentials without consulting the provider chain', :aggregate_failures do
        expect(Aws::CredentialProviderChain).not_to receive(:new)

        expect(credentials).to eq(static_credentials)
      end
    end

    context 'when no static credentials are configured' do
      let(:config) { {} }

      context 'and the credential provider chain resolves to a provider' do
        let(:provider) { instance_double(Aws::InstanceProfileCredentials) }
        let(:chain) { instance_double(Aws::CredentialProviderChain, resolve: provider) }

        before do
          allow(Aws::CredentialProviderChain).to receive(:new).and_return(chain)
        end

        it 'falls back to the AWS credential provider chain' do
          expect(credentials).to eq(provider)
        end
      end

      context 'and the credential provider chain resolves nil' do
        let(:chain) { instance_double(Aws::CredentialProviderChain, resolve: nil) }

        before do
          allow(Aws::CredentialProviderChain).to receive(:new).and_return(chain)
        end

        it 'returns nil' do
          expect(credentials).to be_nil
        end
      end
    end
  end
end
