# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OmniAuth::Strategies::OAuth2' do
  it 'verifies the gem version' do
    current_version = OmniAuth::OAuth2::VERSION
    expected_version = '1.8.0'

    expect(current_version).to eq(expected_version), <<~EOF
      New version #{current_version} of the `omniauth-oauth2` gem detected!

      Please check if the monkey patches in `config/initializers_before_autoloader/100_patch_omniauth_oauth2.rb`
      are still needed, and either update/remove them, or bump the version in this spec.

    EOF
  end

  context 'when a Faraday exception is raised' do
    where(exception: [Faraday::TimeoutError, Faraday::ConnectionFailed])

    with_them do
      it 'passes the exception to OmniAuth' do
        instance = OmniAuth::Strategies::OAuth2.new(double)

        expect(instance).to receive(:original_callback_phase) { raise exception, 'message' }
        expect(instance).to receive(:fail!).with(:timeout, kind_of(exception))

        instance.callback_phase
      end
    end
  end
end
