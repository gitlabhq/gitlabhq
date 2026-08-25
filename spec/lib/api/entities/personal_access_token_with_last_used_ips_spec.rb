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

    context 'when the token has more than the stored limit of IPs' do
      let_it_be(:token) { create(:personal_access_token, user: user) }

      before do
        7.times do |i|
          create(:personal_access_token_last_used_ip,
            personal_access_token: token, ip_address: "192.0.2.#{i}", created_at: i.minutes.ago
          )
        end
      end

      it 'exposes only the 5 most recent IPs' do
        expect(entity_json[:last_used_ips].map(&:to_s))
          .to match_array(%w[192.0.2.0 192.0.2.1 192.0.2.2 192.0.2.3 192.0.2.4])
      end
    end

    context 'when the token has duplicate IPs' do
      let_it_be(:token) { create(:personal_access_token, user: user) }

      before do
        create(:personal_access_token_last_used_ip,
          personal_access_token: token, ip_address: '192.0.2.1', created_at: 2.minutes.ago
        )
        create(:personal_access_token_last_used_ip,
          personal_access_token: token, ip_address: '192.0.2.1', created_at: 1.minute.ago
        )
        create(:personal_access_token_last_used_ip,
          personal_access_token: token, ip_address: '192.0.2.2', created_at: 3.minutes.ago
        )
      end

      it 'exposes each IP only once' do
        expect(entity_json[:last_used_ips].map(&:to_s)).to contain_exactly('192.0.2.1', '192.0.2.2')
      end
    end
  end
end
