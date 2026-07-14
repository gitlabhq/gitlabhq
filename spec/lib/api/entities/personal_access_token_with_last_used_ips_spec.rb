# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::PersonalAccessTokenWithLastUsedIps, feature_category: :system_access do
  describe '#as_json' do
    let_it_be(:user) { create(:user) }
    let(:options) { { with_granular_scopes: true } }

    subject(:entity_json) { described_class.new(token, options).as_json }

    context 'when the token is not granular' do
      let_it_be(:token) { create(:personal_access_token, user: user) }

      it 'does not expose granular_scopes' do
        expect(entity_json).not_to have_key(:granular_scopes)
      end
    end

    context 'when the token is granular' do
      let_it_be(:project) { create(:project) }
      let_it_be(:token) do
        create(:granular_pat, user: user, permissions: ['read_job'], boundary: ::Authz::Boundary.for(project))
      end

      it 'exposes granular_scopes' do
        expect(entity_json[:granular_scopes]).to contain_exactly(
          a_hash_including(access: 'selected_memberships', permissions: ['read_job'], project_id: project.id)
        )
      end

      context 'when the with_granular_scopes option is not passed' do
        let(:options) { {} }

        it 'does not expose granular_scopes' do
          expect(entity_json).not_to have_key(:granular_scopes)
        end
      end
    end
  end
end
