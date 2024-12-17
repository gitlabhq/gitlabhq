# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::UnbanService, feature_category: :user_management do
  let(:user) { create(:user) }

  let_it_be(:current_user) { create(:admin) }

  shared_examples 'does not modify the BannedUser record or user state' do
    it 'does not modify the BannedUser record or user state' do
      expect { unban_user }.not_to change { Users::BannedUser.count }
      expect { unban_user }.not_to change { user.state }
    end
  end

  context 'unban', :aggregate_failures do
    subject(:unban_user) { described_class.new(current_user).execute(user) }

    context 'when successful', :enable_admin_mode do
      before do
        user.ban!
      end

      it 'returns success status' do
        response = unban_user

        expect(response[:status]).to eq(:success)
      end

      it 'unbans the user' do
        expect { unban_user }.to change { user.state }.from('banned').to('active')
      end

      it 'removes the BannedUser' do
        expect { unban_user }.to change { Users::BannedUser.count }.by(-1)
        expect(user.reload.banned_user).to be_nil
      end

      it 'logs unban in application logs' do
        allow(Gitlab::AppLogger).to receive(:info)

        expect(Gitlab::AppLogger).to receive(:info).with(
          message: "User unban",
          username: user.username.to_s,
          user_id: user.id,
          email: user.email.to_s,
          unban_by: current_user.username.to_s,
          ip_address: current_user.current_sign_in_ip.to_s
        )

        unban_user
      end
    end

    context 'when failed' do
      context 'when user is already active', :enable_admin_mode do
        it 'returns state error message' do
          response = unban_user

          expect(response[:status]).to eq(:error)
          expect(response[:message]).to match('You cannot unban active users.')
        end

        it_behaves_like 'does not modify the BannedUser record or user state'
      end

      context 'when user is not an admin' do
        before do
          user.ban!
        end

        it 'returns permissions error message' do
          response = unban_user

          expect(response[:status]).to eq(:error)
          expect(response[:message]).to match(/You are not allowed to unban a user/)
        end

        it_behaves_like 'does not modify the BannedUser record or user state'
      end
    end
  end
end
