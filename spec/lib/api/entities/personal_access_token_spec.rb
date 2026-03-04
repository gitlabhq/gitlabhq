# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::PersonalAccessToken, feature_category: :system_access do
  describe '#as_json' do
    let_it_be(:user) { create(:user) }
    let_it_be(:token) { create(:personal_access_token, user: user, description: "Test") }

    let(:entity) { described_class.new(token) }

    subject(:as_json) { entity.as_json }

    it 'returns token data' do
      expect(as_json).to eq({
        id: token.id,
        name: token.name,
        description: token.description,
        active: true,
        revoked: false,
        expired: false,
        granular: false,
        created_at: token.created_at,
        scopes: ['api'],
        user_id: user.id,
        last_used_at: nil,
        expires_at: token.expires_at.iso8601
      })
    end

    context 'when token is expired' do
      let_it_be(:token) { create(:personal_access_token, :expired, user: user) }

      it 'shows token as expired' do
        expect(as_json[:active]).to be(false)
        expect(as_json[:expired]).to be(true)
      end
    end

    context 'when token is revoked' do
      let_it_be(:token) { create(:personal_access_token, :revoked, user: user) }

      it 'shows token as revoked' do
        expect(as_json[:active]).to be(false)
        expect(as_json[:revoked]).to be(true)
      end
    end

    context 'when token is granular' do
      let_it_be(:token) { create(:granular_pat, user: user) }

      it 'exposes granular as true' do
        expect(as_json[:granular]).to be(true)
      end

      context 'when `granular_personal_access_tokens` feature flag is enabled' do
        before do
          stub_feature_flags(granular_personal_access_tokens: true)
        end

        it 'shows token as active' do
          expect(as_json[:active]).to be(true)
        end

        context 'when token is expired' do
          let_it_be(:token) { create(:granular_pat, :expired, user: user) }

          it 'shows token as expired' do
            expect(as_json[:active]).to be(false)
            expect(as_json[:expired]).to be(true)
          end
        end

        context 'when token is revoked' do
          let_it_be(:token) { create(:granular_pat, :revoked, user: user) }

          it 'shows token as revoked' do
            expect(as_json[:active]).to be(false)
            expect(as_json[:revoked]).to be(true)
          end
        end
      end

      context 'when `granular_personal_access_tokens` feature flag is disabled' do
        before do
          stub_feature_flags(granular_personal_access_tokens: false)
        end

        it 'shows token as not active' do
          expect(as_json[:active]).to be(false)
        end

        context 'when token is expired' do
          let_it_be(:token) { create(:granular_pat, :expired, user: user) }

          it 'shows token as expired' do
            expect(as_json[:active]).to be(false)
            expect(as_json[:expired]).to be(true)
          end
        end

        context 'when token is revoked' do
          let_it_be(:token) { create(:granular_pat, :revoked, user: user) }

          it 'shows token as revoked' do
            expect(as_json[:active]).to be(false)
            expect(as_json[:revoked]).to be(true)
          end
        end
      end
    end
  end
end
