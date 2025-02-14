# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Tokens::FeatureFlagsClientToken, :aggregate_failures, feature_category: :feature_flags do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, maintainers: [user]) }

  let(:feature_flags_client) { create(:operations_feature_flags_client, project: project) }

  subject(:token) { described_class.new(plaintext, :api_admin_token) }

  context 'with valid Feature Flags Client token' do
    let(:plaintext) { feature_flags_client.token }
    let(:valid_revocable) { feature_flags_client }

    it_behaves_like 'finding the valid revocable'

    describe '#revoke!' do
      subject(:revoke) { token.revoke!(user) }

      it 'successfully resets the client token' do
        expect { revoke }.to change { feature_flags_client.reload.token }
        expect(revoke.success?).to be_truthy
      end
    end
  end

  it_behaves_like 'token handling with unsupported token type'
end
