# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::ValidatePushOtpService, feature_category: :user_profile do
  let_it_be(:user) { create(:user) }

  subject(:validate) { described_class.new(user).execute }

  context 'FortiAuthenticator' do
    before do
      stub_feature_flags(forti_authenticator: user)
      allow(::Gitlab.config.forti_authenticator).to receive(:enabled).and_return(true)
    end

    it 'calls PushOtp strategy' do
      expect_next_instance_of(::Gitlab::Auth::Otp::Strategies::FortiAuthenticator::PushOtp) do |strategy|
        expect(strategy).to receive(:validate).once
      end

      validate
    end
  end

  context 'unexpected error' do
    before do
      stub_feature_flags(forti_authenticator: user)
      allow(::Gitlab.config.forti_authenticator).to receive(:enabled).and_return(true)
    end

    it 'returns error' do
      error_message = "boom!"

      expect_next_instance_of(::Gitlab::Auth::Otp::Strategies::FortiAuthenticator::PushOtp) do |strategy|
        expect(strategy).to receive(:validate).once.and_raise(StandardError, error_message)
      end
      expect(Gitlab::ErrorTracking).to receive(:log_exception)

      result = validate

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq(error_message)
    end
  end
end
