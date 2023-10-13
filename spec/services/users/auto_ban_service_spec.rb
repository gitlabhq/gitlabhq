# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::AutoBanService, feature_category: :instance_resiliency do
  let_it_be_with_reload(:user) { create(:user) }
  let(:reason) { :auto_ban_reason }

  context 'when auto banning a user', :aggregate_failures do
    subject(:auto_ban_user) { described_class.new(user: user, reason: reason).execute }

    context 'when successful' do
      it 'returns success status' do
        response = auto_ban_user

        expect(response[:status]).to eq(:success)
      end

      it 'bans the user' do
        expect { auto_ban_user }.to change { user.state }.from('active').to('banned')
      end

      it 'creates a BannedUser' do
        expect { auto_ban_user }.to change { Users::BannedUser.count }.by(1)
        expect(Users::BannedUser.last.user_id).to eq(user.id)
      end

      describe 'recording a custom attribute' do
        it 'records a custom attribute' do
          expect { auto_ban_user }.to change { UserCustomAttribute.count }.by(1)
          expect(user.custom_attributes.by_key(UserCustomAttribute::AUTO_BANNED_BY).first.value).to eq(reason.to_s)
        end
      end
    end

    context 'when failed' do
      context 'when user is blocked' do
        before do
          user.block!
        end

        it 'returns state error message' do
          response = auto_ban_user

          expect(response[:status]).to eq(:error)
          expect(response[:message]).to match('State cannot transition via \"ban\"')
        end

        it 'does not modify the BannedUser record or user state' do
          expect { auto_ban_user }.not_to change { Users::BannedUser.count }
          expect { auto_ban_user }.not_to change { user.state }
        end
      end
    end
  end
end
