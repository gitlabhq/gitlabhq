# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Tokens::FeedToken, feature_category: :system_access do
  let_it_be_with_reload(:user) { create(:user) }

  subject(:token) { described_class.new(plaintext, :group_token_revocation_service) }

  context 'with valid feed token' do
    let(:plaintext) { user.feed_token }
    let(:valid_revocable) { user }

    it_behaves_like 'finding the valid revocable'

    context 'with different instance prefix' do
      let(:instance_prefix) { 'instanceprefix' }

      before do
        stub_application_setting(instance_token_prefix: instance_prefix)
        user.reset_feed_token!
      end

      it 'starts with the instance prefix' do
        expect(user.feed_token).to start_with(instance_prefix)
      end

      it_behaves_like 'finding the valid revocable'
    end

    describe '#revoke!' do
      it 'successfully revokes the token' do
        expect(token.revoke!(user).status).to eq(:success)
      end
    end
  end

  it_behaves_like 'token handling with unsupported token type'
end
