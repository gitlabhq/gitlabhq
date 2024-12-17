# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::ActivateService, feature_category: :user_management do
  let_it_be(:current_user) { build(:admin) }

  subject(:service) { described_class.new(current_user) }

  describe '#execute' do
    let!(:user) { create(:user, :deactivated) }

    subject(:operation) { service.execute(user) }

    context 'when successful', :enable_admin_mode do
      it 'returns success status' do
        expect(operation[:status]).to eq(:success)
      end

      it "changes the user's state" do
        expect { operation }.to change { user.state }.to('active')
      end

      it 'creates a log entry' do
        allow(Gitlab::AppLogger).to receive(:info)

        expect(Gitlab::AppLogger).to receive(:info).with(
          message: "User activated",
          username: user.username,
          user_id: user.id,
          email: user.email,
          activated_by: current_user.username,
          ip_address: current_user.current_sign_in_ip.to_s
        )

        operation
      end
    end

    context 'when the user is already active', :enable_admin_mode do
      let(:user) { create(:user) }

      it 'returns success result' do
        aggregate_failures 'success result' do
          expect(operation[:status]).to eq(:success)
          expect(operation[:message]).to eq('Successfully activated')
        end
      end

      it "does not change the user's state" do
        expect { operation }.not_to change { user.state }
      end
    end

    context 'when user activation fails', :enable_admin_mode do
      before do
        allow(user).to receive(:activate).and_return(false)
      end

      it 'returns an unprocessable entity error' do
        result = service.execute(user)

        expect(result[:status]).to eq(:error)
        expect(result[:reason]).to eq(:unprocessable_entity)
      end
    end

    context 'when user is not an admin' do
      let(:non_admin_user) { build(:user) }
      let(:service) { described_class.new(non_admin_user) }

      it 'returns permissions error message' do
        expect(operation[:status]).to eq(:error)
        expect(operation[:message]).to eq("You are not authorized to perform this action")
        expect(operation.reason).to eq :forbidden
      end
    end
  end
end
