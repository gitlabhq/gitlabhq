# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Tokens::IamOauthToken, feature_category: :system_access do
  include_context 'with IAM authentication setup'

  let_it_be(:user) { create(:user) }

  let(:scopes) { %w[api read_repository] }
  let(:expires_at) { 1.hour.from_now }
  let(:sub) { user.id.to_s }
  let(:valid_token_string) do
    create_iam_jwt(user: user, scopes: scopes, expires_at: expires_at, issuer: iam_issuer,
      private_key: private_key, kid: kid, sub: sub)
  end

  subject(:token) { described_class.from_jwt(valid_token_string) }

  describe '.from_jwt' do
    context 'when IAM is disabled' do
      before do
        stub_iam_service_config(enabled: false, url: iam_service_url, audience: iam_audience)
      end

      it 'returns nil' do
        is_expected.to be_nil
      end
    end

    context 'when IAM is enabled' do
      context 'when feature flag is disabled for user' do
        before do
          stub_feature_flags(iam_svc_oauth: false)
        end

        it 'returns nil' do
          expect(token).to be_nil
        end
      end

      context 'when feature flag is enabled for user' do
        before do
          stub_feature_flags(iam_svc_oauth: user)
        end

        context 'when token is IAM-issued JWT format' do
          it 'returns token with correct attributes', :freeze_time do
            is_expected.to be_a(described_class)
            expect(token.user_id).to eq(user.id)
            expect(token.scopes).to eq(scopes)
            expect(token.id).to be_present
            expect(token.expires_at).to eq(expires_at)
            expect(token.issued_at).to be_within(1.second).of(Time.current)
          end
        end

        context 'when token is not IAM-issued JWT format' do
          it 'returns nil' do
            expect(described_class.from_jwt('not-a-jwt')).to be_nil
            expect(described_class.from_jwt(nil)).to be_nil
            expect(described_class.from_jwt('only.two')).to be_nil
          end
        end

        context 'when validation fails' do
          let(:expires_at) { 1.hour.ago }

          it { is_expected.to be_nil }
        end

        context 'when token refers to non-existent user' do
          let(:sub) { non_existing_record_id.to_s }

          it 'returns nil when user does not exist in database' do
            expect(token).to be_nil
          end
        end

        context 'when from_validated_jwt returns nil' do
          before do
            allow(described_class).to receive(:from_validated_jwt).and_return(nil)
          end

          it 'returns nil' do
            expect(described_class.from_jwt(valid_token_string)).to be_nil
          end
        end
      end
    end
  end

  describe '#accessible?' do
    it 'returns true for valid token' do
      expect(token.accessible?).to be(true)
    end

    it 'returns false when token is expired' do
      token

      travel_to(2.hours.from_now) do
        expect(token.accessible?).to be(false)
      end
    end
  end

  describe '#active?' do
    it 'returns true for valid token' do
      expect(token.active?).to be(true)
    end

    it 'returns false when token is expired' do
      token

      travel_to(2.hours.from_now) do
        expect(token.active?).to be(false)
      end
    end
  end

  describe '#expired?' do
    it 'returns false for valid token' do
      expect(token.expired?).to be(false)
    end

    it 'returns true when token expires in the past' do
      token

      travel_to(2.hours.from_now) do
        expect(token.expired?).to be(true)
      end
    end
  end

  describe '#id' do
    it 'returns the id' do
      expect(token.id).to be_present
    end
  end

  describe '#reload' do
    it 'clears memoized user' do
      token.user
      token.reload

      expect(User).to receive(:find_by_id).with(user.id).and_call_original
      token.user
    end

    context 'when token has scope_user' do
      let_it_be(:scope_user) { create(:user) }
      let(:scopes) { ['api', "user:#{scope_user.id}"] }

      it 'clears memoized scope_user' do
        token.scope_user
        token.reload

        expect(User).to receive(:find_by_id).with(scope_user.id).and_call_original
        token.scope_user
      end
    end
  end

  describe '#resource_owner_id' do
    it 'returns the user_id' do
      expect(token.resource_owner_id).to eq(user.id)
    end
  end

  describe '#revoked?' do
    it 'always returns false' do
      expect(token.revoked?).to be(false)
    end
  end

  describe '#scope_user' do
    context 'when scopes include user scope' do
      let_it_be(:scope_user) { create(:user) }
      let(:scopes) { ['api', "user:#{scope_user.id}"] }

      it 'returns the scoped user' do
        expect(token.scope_user).to eq(scope_user)
      end
    end

    context 'when scopes include non-existent user' do
      let(:scopes) { ['api', "user:#{non_existing_record_id}"] }

      it 'returns nil' do
        expect(token.scope_user).to be_nil
      end
    end

    context 'when scopes do not include user scope' do
      let(:scopes) { %w[api read_repository] }

      it 'returns nil' do
        expect(token.scope_user).to be_nil
      end
    end

    context 'when token has no scopes' do
      let(:scopes) { nil }

      it 'returns nil' do
        expect(token.scope_user).to be_nil
      end
    end
  end

  describe '#user' do
    it 'returns the user' do
      expect(token.user).to eq(user)
    end
  end

  describe '#to_s' do
    it 'returns a string representation with id and user_id' do
      expect(token.to_s).to eq("Authn::Tokens::IamOauthToken(id: #{token.id}, user_id: #{user.id})")
    end
  end
end
