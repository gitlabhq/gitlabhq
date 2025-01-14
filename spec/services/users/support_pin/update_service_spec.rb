# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::SupportPin::UpdateService, feature_category: :user_management do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user) }

  describe '#execute' do
    it 'creates a new support PIN' do
      result = service.execute

      expect(result[:status]).to eq(:success)
      expect(result[:pin]).to match(/^\d{6}$/)
      expect(result[:expires_at]).to be_within(1.minute).of(described_class::SUPPORT_PIN_EXPIRATION)
    end

    it 'stores the PIN in Redis' do
      result = service.execute
      key = "support_pin:#{user.id}"
      pin = result[:pin]

      Gitlab::Redis::Cache.with do |redis|
        expect(redis.get(key)).to eq(pin)
      end
    end

    it "returns an error when storing the PIN fails" do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:store_pin).and_return(false)
      end
      result = described_class.new(user).execute
      expect(result).to eq({ status: :error, message: 'Failed to create support PIN' })
    end
  end
end
