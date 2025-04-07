# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::AgnosticTokenIdentifier, feature_category: :system_access do
  shared_examples 'supported token type' do
    describe '#initialize' do
      it 'finds the correct revocable token type' do
        expect(token).to be_instance_of(token_type)
      end

      it 'detects whether the value is a token' do
        expect(described_class.token?(plaintext)).to be token?
      end
    end
  end

  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:deploy_token) { create(:deploy_token).token }
  let_it_be(:feed_token) { user.feed_token }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user).token }
  let_it_be(:impersonation_token) { create(:personal_access_token, :impersonation, user: user).token }
  let_it_be(:oauth_application_secret) { create(:oauth_application).plaintext_secret }
  let_it_be(:cluster_agent_token) { create(:cluster_agent_token, token_encrypted: nil).token }
  let_it_be(:runner_authentication_token) { create(:ci_runner, registration_type: :authenticated_user).token }
  let_it_be(:ci_trigger_token) { create(:ci_trigger).token }
  let_it_be(:feature_flags_client_token) { create(:operations_feature_flags_client).token }
  let_it_be(:gitlab_session) { '_gitlab_session=session_id' }
  let_it_be(:incoming_email_token) { user.incoming_email_token }

  subject(:token) { described_class.token_for(plaintext, :group_token_revocation_service) }

  context 'with supported token types' do
    where(:plaintext, :token_type, :token?) do
      ref(:personal_access_token)       | ::Authn::Tokens::PersonalAccessToken        | true
      ref(:impersonation_token)         | ::Authn::Tokens::PersonalAccessToken        | true
      ref(:feed_token)                  | ::Authn::Tokens::FeedToken                  | true
      ref(:deploy_token)                | ::Authn::Tokens::DeployToken                | true
      ref(:oauth_application_secret)    | ::Authn::Tokens::OauthApplicationSecret     | true
      ref(:cluster_agent_token)         | ::Authn::Tokens::ClusterAgentToken          | true
      ref(:runner_authentication_token) | ::Authn::Tokens::RunnerAuthenticationToken  | true
      ref(:ci_trigger_token)            | ::Authn::Tokens::CiTriggerToken             | true
      ref(:feature_flags_client_token)  | ::Authn::Tokens::FeatureFlagsClientToken    | true
      ref(:gitlab_session)              | ::Authn::Tokens::GitlabSession              | true
      ref(:incoming_email_token)        | ::Authn::Tokens::IncomingEmailToken         | true
      'unsupported'                     | NilClass                                    | false
    end

    with_them do
      context 'with default instance prefix' do
        it_behaves_like 'supported token type'
      end

      context 'with custom instance prefix' do
        let_it_be(:instance_prefix) { 'instance-prefix-' }

        before do
          stub_application_setting(instance_token_prefix: instance_prefix)
        end

        # this will make sure that we find old tokens with the default instance prefix,
        # even if we have configured a custom one:
        it_behaves_like 'supported token type'
      end

      context 'with feature flag custom_prefix_for_all_token_types disabled' do
        before do
          stub_feature_flags(custom_prefix_for_all_token_types: false)
        end

        it_behaves_like 'supported token type'
      end
    end
  end

  context 'with CI Job tokens' do
    let(:plaintext) { create(:ci_build, status: status).token }
    let(:token_type) { ::Authn::Tokens::CiJobToken }

    before do
      rsa_key = OpenSSL::PKey::RSA.generate(3072).to_s
      stub_application_setting(ci_jwt_signing_key: rsa_key)
    end

    context 'when job is running' do
      let(:status) { :running }

      it_behaves_like 'supported token type' do
        let(:token?) { true }
      end
    end

    context 'when job is not running' do
      let(:status) { :success }

      it_behaves_like 'supported token type' do
        let(:token?) { true }
      end
    end
  end
end
