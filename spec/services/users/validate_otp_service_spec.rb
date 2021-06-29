# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::ValidateOtpService do
  let_it_be(:user) { create(:user) }

  let(:otp_code) { 42 }

  subject(:validate) { described_class.new(user).execute(otp_code) }

  context 'Devise' do
    it 'calls Devise strategy' do
      expect_next_instance_of(::Gitlab::Auth::Otp::Strategies::Devise) do |strategy|
        expect(strategy).to receive(:validate).with(otp_code).once
      end

      validate
    end
  end

  context 'FortiAuthenticator' do
    before do
      stub_feature_flags(forti_authenticator: user)
      allow(::Gitlab.config.forti_authenticator).to receive(:enabled).and_return(true)
    end

    it 'calls FortiAuthenticator strategy' do
      expect_next_instance_of(::Gitlab::Auth::Otp::Strategies::FortiAuthenticator) do |strategy|
        expect(strategy).to receive(:validate).with(otp_code).once
      end

      validate
    end
  end

  context 'FortiTokenCloud' do
    before do
      stub_feature_flags(forti_token_cloud: user)
      allow(::Gitlab.config.forti_token_cloud).to receive(:enabled).and_return(true)
    end

    it 'calls FortiTokenCloud strategy' do
      expect_next_instance_of(::Gitlab::Auth::Otp::Strategies::FortiTokenCloud) do |strategy|
        expect(strategy).to receive(:validate).with(otp_code).once
      end

      validate
    end
  end
end
