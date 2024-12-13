# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::BanService, feature_category: :user_management do
  let(:user) { create(:user) }

  let_it_be(:current_user) { create(:admin) }

  shared_examples 'does not modify the BannedUser record or user state' do
    it 'does not modify the BannedUser record or user state' do
      expect { ban_user }.not_to change { Users::BannedUser.count }
      expect { ban_user }.not_to change { user.state }
    end
  end

  context 'ban', :aggregate_failures do
    subject(:ban_user) { described_class.new(current_user).execute(user) }

    context 'when successful', :enable_admin_mode do
      it 'returns success status' do
        response = ban_user

        expect(response[:status]).to eq(:success)
      end

      it 'bans the user' do
        expect { ban_user }.to change { user.state }.from('active').to('banned')
      end

      it 'creates a BannedUser' do
        expect { ban_user }.to change { Users::BannedUser.count }.by(1)
        expect(Users::BannedUser.last.user_id).to eq(user.id)
      end

      it 'logs ban in application logs' do
        allow(Gitlab::AppLogger).to receive(:info)

        expect(Gitlab::AppLogger).to receive(:info).with(
          message: "User ban",
          username: user.username.to_s,
          user_id: user.id,
          email: user.email.to_s,
          ban_by: current_user.username.to_s,
          ip_address: current_user.current_sign_in_ip.to_s
        )

        ban_user
      end

      it 'bans duplicate users' do
        expect(AntiAbuse::BanDuplicateUsersWorker).to receive(:perform_async).with(user.id)

        ban_user
      end
    end

    context 'when failed' do
      context 'when user is blocked', :enable_admin_mode do
        before do
          user.block!
        end

        it 'returns state error message' do
          response = ban_user

          expect(response[:status]).to eq(:error)
          expect(response[:message]).to match('You cannot ban blocked users.')
        end

        it_behaves_like 'does not modify the BannedUser record or user state'
      end

      context 'when user is not an admin' do
        it 'returns permissions error message' do
          response = ban_user

          expect(response[:status]).to eq(:error)
          expect(response[:message]).to match(/You are not allowed to ban a user/)
        end

        it_behaves_like 'does not modify the BannedUser record or user state'
      end
    end
  end
end
