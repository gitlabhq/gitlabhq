# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AntiAbuse::BanDuplicateUsersWorker, feature_category: :instance_resiliency do
  let(:worker) { described_class.new }
  let_it_be_with_reload(:banned_user) { create(:user, email: 'user+banned@example.com') }

  subject { worker.perform(banned_user.id) }

  # The banned user cannot be instantiated as banned because validators prevent users from
  # being created that have similar characteristics of previously banned users.
  before do
    banned_user.ban!
  end

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [banned_user.id] }
  end

  shared_examples 'executing the ban duplicate users worker' do
    it_behaves_like 'bans the duplicate user'

    context 'when the banned user is not found' do
      subject { worker.perform(non_existing_record_id) }

      it_behaves_like 'does not ban the duplicate user'
    end

    context 'when the banned user is not in a banned state' do
      before do
        banned_user.unban!
      end

      it_behaves_like 'does not ban the duplicate user'
    end
  end

  describe 'ban users with the same detumbled email address' do
    let(:ban_reason) { "User #{banned_user.id} was banned with the same detumbled email address" }

    context 'when emails are confirmed' do
      let_it_be_with_reload(:duplicate_user) { create(:user, email: 'user+duplicate@example.com') }

      it_behaves_like 'executing the ban duplicate users worker'

      context 'when the auto_ban_via_detumbled_email feature is disabled' do
        before do
          stub_feature_flags(auto_ban_via_detumbled_email: false)
        end

        it_behaves_like 'does not ban the duplicate user'
      end

      context 'when the duplicate user is not active' do
        before do
          duplicate_user.block!
        end

        it_behaves_like 'does not ban the duplicate user'
      end
    end

    context 'when the duplicate user matches an unconfirmed email of the banned user' do
      let_it_be_with_reload(:duplicate_user) { create(:user, email: 'test+duplicate@example.com') }

      before do
        create(:email, email: 'test+banned@example.com', user: banned_user)
      end

      it_behaves_like 'does not ban the duplicate user'
    end

    context 'when the banned user matches an unconfirmed email of the duplicate user' do
      let_it_be_with_reload(:duplicate_user) { create(:user) }

      # We can't set this when we create the duplicate user because the primary email
      # is not added to the emails table until the user is confirmed.
      before do
        create(:email, email: 'user+duplicate@example.com', user: duplicate_user)
      end

      it_behaves_like 'bans the duplicate user'
    end
  end
end
