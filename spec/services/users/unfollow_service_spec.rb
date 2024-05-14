# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::UnfollowService, feature_category: :user_management do
  let(:follower) { create(:user) }
  let(:followee) { create(:user) }

  subject(:service) { described_class.new(follower: follower, followee: followee) }

  describe '#execute' do
    context 'when the unfollow action is successful' do
      before do
        follower.follow(followee)
      end

      it 'removes the follow relationship' do
        expect { service.execute }.to change { Users::UserFollowUser.count }.by(-1)
      end

      it 'returns a success response' do
        response = service.execute
        expect(response.success?).to be_truthy
      end
    end

    context 'when the follow relationship does not exist' do
      it 'returns an error response' do
        response = service.execute
        expect(response.success?).to be_falsy
        expect(response.message).to eq(_('Failed to unfollow user'))
      end
    end
  end
end
