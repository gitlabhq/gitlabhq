# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::DeactivateService, feature_category: :user_management do
  let_it_be(:current_user) { build(:admin) }
  let_it_be(:user) { build(:user) }

  subject(:service) { described_class.new(current_user) }

  describe '#execute' do
    subject(:operation) { service.execute(user) }

    context 'when successful', :enable_admin_mode do
      let(:user) { create(:user) }

      it 'returns success status' do
        expect(operation[:status]).to eq(:success)
      end

      it "changes the user's state" do
        expect { operation }.to change { user.state }.to('deactivated')
      end

      it 'creates a log entry' do
        allow(Gitlab::AppLogger).to receive(:info)

        expect(Gitlab::AppLogger).to receive(:info).with(
          message: "User deactivated",
          username: user.username,
          user_id: user.id,
          email: user.email,
          deactivated_by: current_user.username,
          ip_address: current_user.current_sign_in_ip.to_s
        )

        operation
      end
    end

    context 'when the user is already deactivated', :enable_admin_mode do
      let(:user) { create(:user, :deactivated) }

      it 'returns error result' do
        aggregate_failures 'error result' do
          expect(operation[:status]).to eq(:success)
          expect(operation[:message]).to eq('User has already been deactivated')
        end
      end

      it "does not change the user's state" do
        expect { operation }.not_to change { user.state }
      end
    end

    context 'when internal user', :enable_admin_mode do
      let(:user) { create(:user, :bot) }

      it 'returns an error message' do
        expect(operation[:status]).to eq(:error)
        expect(operation[:message]).to eq('Internal users cannot be deactivated')
        expect(operation.reason).to eq :forbidden
      end
    end

    context 'when user is blocked', :enable_admin_mode do
      let(:user) { create(:user, :blocked) }

      it 'returns an error message' do
        expect(operation[:status]).to eq(:error)
        expect(operation[:message]).to eq('Error occurred. A blocked user cannot be deactivated')
        expect(operation.reason).to eq :forbidden
      end
    end

    context 'when user is not an admin' do
      it 'returns permissions error message' do
        expect(operation[:status]).to eq(:error)
        expect(operation[:message]).to eq("You are not authorized to perform this action")
        expect(operation.reason).to eq :forbidden
      end
    end

    context 'when skip_authorization is true' do
      let(:non_admin_user) { create(:user) }
      let(:user_to_deactivate) { create(:user) }
      let(:skip_authorization_service) { described_class.new(non_admin_user, skip_authorization: true) }

      it 'deactivates the user even if the current user is not an admin' do
        expect(skip_authorization_service.execute(user_to_deactivate)[:status]).to eq(:success)
      end
    end
  end
end
