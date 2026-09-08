# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::PersonalAccessToken, feature_category: :system_access do
  describe '#as_json' do
    let_it_be(:user) { create(:user) }
    let_it_be(:token) { create(:personal_access_token, user: user, description: "Test") }

    let(:entity) { described_class.new(token) }

    it 'returns token data' do
      expect(entity.as_json).to eq({
        id: token.id,
        name: token.name,
        description: token.description,
        revoked: false,
        created_at: token.created_at,
        scopes: ['api'],
        user_id: user.id,
        last_used_at: nil,
        last_used_ips: [],
        active: true,
        granular: false,
        expires_at: token.expires_at.iso8601
      })
    end

    context 'when the token has been used' do
      let_it_be(:used_token) { create(:personal_access_token, :with_last_used_ips, user: user) }

      let(:entity) { described_class.new(used_token) }

      it 'exposes last_used_ips' do
        expect(entity.as_json[:last_used_ips]).to match_array(used_token.last_used_ips.map(&:ip_address))
      end
    end

    describe 'granular_scopes' do
      let(:options) { { with_granular_scopes: true } }
      let(:entity) { described_class.new(granular_token, options) }

      context 'when the token is not granular' do
        let(:granular_token) { token }

        it 'does not expose granular_scopes' do
          expect(entity.as_json).not_to have_key(:granular_scopes)
        end
      end

      context 'when the token is granular' do
        let_it_be(:project) { create(:project) }
        let_it_be(:granular_token) do
          create(:granular_pat, user: user, permissions: ['read_job'], boundary: ::Authz::Boundary.for(project))
        end

        it 'exposes granular_scopes' do
          expect(entity.as_json[:granular_scopes]).to contain_exactly(
            a_hash_including(access: 'selected_memberships', permissions: ['read_job'], project_id: project.id)
          )
        end

        context 'when the with_granular_scopes option is not passed' do
          let(:options) { {} }

          it 'does not expose granular_scopes' do
            expect(entity.as_json).not_to have_key(:granular_scopes)
          end
        end
      end
    end
  end
end
