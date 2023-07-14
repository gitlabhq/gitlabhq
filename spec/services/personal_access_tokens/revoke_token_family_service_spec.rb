# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokens::RevokeTokenFamilyService, feature_category: :system_access do
  describe '#execute' do
    let_it_be(:token_3) { create(:personal_access_token, :revoked) }
    let_it_be(:token_2) { create(:personal_access_token, :revoked, previous_personal_access_token_id: token_3.id) }
    let_it_be(:token_1) { create(:personal_access_token, previous_personal_access_token_id: token_2.id) }

    subject(:response) { described_class.new(token_3).execute }

    it 'revokes the latest token from the chain of rotated tokens' do
      expect(response).to be_success
      expect(token_1.reload).to be_revoked
    end
  end
end
