# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::SupportPin::RetrieveService, feature_category: :user_management do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user) }

  describe '#execute' do
    context 'when a PIN exists' do
      let!(:pin) { Users::SupportPin::UpdateService.new(user).execute[:pin] }

      it 'retrieves the existing PIN' do
        result = service.execute

        expect(result[:pin]).to eq(pin)
        expect(result[:expires_at]).to be_within(1.minute).of(described_class::SUPPORT_PIN_EXPIRATION)
      end
    end

    context 'when no PIN exists' do
      it 'returns nil' do
        expect(service.execute).to be_nil
      end
    end
  end
end
