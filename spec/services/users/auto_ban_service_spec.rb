# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::AutoBanService, feature_category: :instance_resiliency do
  let_it_be_with_reload(:user) { create(:user) }
  let(:reason) { :auto_ban_reason }

  shared_examples 'auto banning a user' do
    it 'bans the user' do
      expect { subject }.to change { user.state }.from('active').to('banned')
    end

    it 'creates a BannedUser' do
      expect { subject }.to change { Users::BannedUser.count }.by(1)
      expect(Users::BannedUser.last.user_id).to eq(user.id)
    end

    it 'records a custom attribute' do
      expect { subject }.to change { UserCustomAttribute.count }.by(1)
      expect(user.custom_attributes.by_key(UserCustomAttribute::AUTO_BANNED_BY).first.value).to eq(reason.to_s)
    end

    it 'bans duplicate users' do
      expect(AntiAbuse::BanDuplicateUsersWorker).to receive(:perform_async).with(user.id)

      subject
    end
  end

  describe "#execute" do
    subject(:execute) { described_class.new(user: user, reason: reason).execute }

    context 'when successful' do
      it_behaves_like 'auto banning a user'

      it 'returns success status' do
        response = execute

        expect(response[:status]).to eq(:success)
      end
    end

    context 'when failed' do
      context 'when user is blocked' do
        before do
          user.block!
        end

        it 'returns state error message' do
          response = execute

          expect(response[:status]).to eq(:error)
          expect(response[:message]).to match('State cannot transition via "ban"')
        end

        it 'does not modify the BannedUser record or user state' do
          expect { execute }.not_to change { Users::BannedUser.count }
          expect { execute }.not_to change { user.state }
        end
      end
    end
  end

  describe "#execute!" do
    subject(:execute!) { described_class.new(user: user, reason: reason).execute! }

    context 'when successful' do
      it_behaves_like 'auto banning a user'
    end

    context 'when failed' do
      context 'when user is blocked' do
        before do
          user.block!
        end

        it 'raises an error and does not ban the user', :aggregate_failures do
          expect { execute! }.to raise_error(StateMachines::InvalidTransition)
            .and not_change { Users::BannedUser.count }
            .and not_change { user.state }
        end
      end
    end
  end
end
