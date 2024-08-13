# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::BannedUser, feature_category: :user_management do
  let_it_be(:user) { create(:user, :banned) }

  describe 'relationships' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:user) }

    it 'validates uniqueness of banned user id' do
      is_expected.to validate_uniqueness_of(:user_id).with_message("banned user already exists")
    end
  end

  describe 'scopes' do
    describe '.by_canonical_email' do
      let_it_be(:user_canonical_email) { create(:user_canonical_email, user: user) }
      let_it_be(:other_user) { create(:user, :banned) }
      let_it_be(:other_user_canonical_email) { create(:user_canonical_email, user: other_user) }

      it 'returns banned user records matching the given email in lowercase' do
        results = described_class.by_canonical_email(user.email.upcase)
        expect(results).to contain_exactly(user.banned_user)
      end
    end
  end
end
