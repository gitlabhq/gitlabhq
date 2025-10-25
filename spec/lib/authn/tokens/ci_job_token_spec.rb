# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Tokens::CiJobToken, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let(:ci_build) { create(:ci_build, status: :running) }
  let(:token_type) { ::Authn::Tokens::CiJobToken }

  subject(:token) { described_class.new(plaintext, :api_admin_token) }

  context 'with valid ci build token' do
    let(:plaintext) { ci_build.token }
    let(:valid_revocable) { ci_build }

    it_behaves_like 'finding the valid revocable'

    context 'when the job is not running' do
      let(:ci_build) { create(:ci_build, status: :success) }

      it 'is not found' do
        expect(token.revocable).to be_nil
      end
    end

    context 'with custom instance prefix' do
      let_it_be(:instance_prefix) { 'instanceprefix' }
      let_it_be(:default_prefix) { Ci::Build::TOKEN_PREFIX }

      before do
        stub_application_setting(instance_token_prefix: instance_prefix)
        allow(ci_build).to receive_message_chain(:namespace, :root_ancestor, :namespace_settings,
          :jwt_ci_cd_job_token_enabled?).and_return(true)
      end

      it_behaves_like 'finding the valid revocable'
      it_behaves_like 'contains instance prefix when enabled'
    end

    describe '#revoke!' do
      it 'does not support revocation yet' do
        expect do
          token.revoke!(user)
        end.to raise_error(::Authn::AgnosticTokenIdentifier::UnsupportedTokenError, 'Unsupported token type')
      end
    end
  end

  it_behaves_like 'token handling with unsupported token type'
end
