# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::BannedUser, feature_category: :user_management do
  let_it_be(:user) { create(:user, :banned, email: 'user+1@example.org') }
  let(:banned_user) { user.banned_user }

  describe 'relationships' do
    it { is_expected.to belong_to(:user) }

    it do
      is_expected.to have_many(:emails).with_primary_key('user_id').with_foreign_key('user_id')
        .inverse_of(:banned_user)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:user) }

    it 'validates uniqueness of banned user id' do
      is_expected.to validate_uniqueness_of(:user_id).with_message("banned user already exists")
    end
  end

  describe 'scopes' do
    describe '.by_detumbled_email' do
      let_it_be(:other_user) { create(:user, :banned, email: 'other_user+1@example.org') }
      let_it_be(:other_user_unconfirmed_email) { create(:email, user: other_user, email: 'user+3@example.org') }

      it 'returns banned user records with confirmed email matching the given email' do
        results = described_class.by_detumbled_email('USER+2@EXAMPLE.ORG')
        expect(results).to contain_exactly(banned_user)
      end

      context 'when passed email is nil' do
        it 'returns nothing' do
          results = described_class.by_detumbled_email(nil)
          expect(results).to be_empty
        end
      end

      context 'when passed email is an empty string' do
        it 'returns nothing' do
          results = described_class.by_detumbled_email(' ')
          expect(results).to be_empty
        end
      end
    end

    describe '.by_user_ids' do
      before do
        create(:banned_user)
      end

      it 'returns banned users that match provided user ids' do
        expect(described_class.by_user_ids([user.id])).to contain_exactly(banned_user)
      end
    end

    describe '.created_before' do
      it 'returns banned users created before the given interval' do
        travel_to(25.hours.from_now) do
          expect(described_class.created_before(1.day.ago)).to contain_exactly(banned_user)
        end
      end

      it 'does not return banned users created after the given interval' do
        travel_to(23.hours.from_now) do
          expect(described_class.created_before(1.day.ago)).to be_empty
        end
      end
    end

    describe '.without_deleted_projects' do
      let_it_be(:banned_user1) { create(:banned_user, projects_deleted: true) }

      it 'returns banned users whose projects have not been deleted' do
        expect(described_class.without_deleted_projects).to contain_exactly(banned_user)
      end
    end
  end
end
