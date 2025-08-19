# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Tokens::CiTriggerToken, :aggregate_failures, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, maintainers: [user]) }

  let(:ci_trigger) { create(:ci_trigger, project: project) }

  subject(:token) { described_class.new(plaintext, :api_admin_token) }

  context 'with valid ci trigger token' do
    let(:plaintext) { ci_trigger.token }
    let(:valid_revocable) { ci_trigger }
    let_it_be(:default_prefix) { ::Ci::Trigger::TRIGGER_TOKEN_PREFIX }

    it_behaves_like 'finding the valid revocable'
    it_behaves_like 'contains instance prefix when enabled'

    describe '#revoke!' do
      it 'expires the token' do
        expect { token.revoke!(user) }.to change { ci_trigger.reload.expired? }
        expect(token.revoke!(user).success?).to be_truthy
      end

      context 'with feature flag disabled' do
        before do
          stub_feature_flags(token_api_expire_pipeline_triggers: false)
        end

        it 'does not support revocation yet' do
          expect do
            token.revoke!(user)
          end.to raise_error(::Authn::AgnosticTokenIdentifier::UnsupportedTokenError, 'Unsupported token type')
        end
      end
    end
  end

  it_behaves_like 'token handling with unsupported token type'
end
