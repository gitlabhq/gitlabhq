# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::SupportPin::RevokeService, feature_category: :user_management do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user) }

  describe '#execute' do
    context 'when a PIN exists' do
      before do
        # Create a PIN using the UpdateService
        Users::SupportPin::UpdateService.new(user).execute
      end

      it 'revokes the PIN successfully' do
        # Verify PIN exists before revocation
        expect(Users::SupportPin::RetrieveService.new(user).execute).not_to be_nil

        result = service.execute
        expect(result[:status]).to eq(:success)

        # Verify PIN is no longer accessible after revocation
        expect(Users::SupportPin::RetrieveService.new(user).execute).to be_nil
      end
    end

    context 'when no PIN exists' do
      it 'returns not_found status' do
        result = service.execute

        expect(result[:status]).to eq(:not_found)
        expect(result[:message]).to eq('Support PIN not found or already expired')
      end
    end

    context 'when Redis operation fails' do
      before do
        # Create a PIN first
        Users::SupportPin::UpdateService.new(user).execute

        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:revoke_pin).and_return(false)
        end
      end

      it 'returns an error' do
        result = service.execute

        expect(result).to eq({ status: :error, message: 'Failed to revoke support PIN' })
      end
    end
  end
end
