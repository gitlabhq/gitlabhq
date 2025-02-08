# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HTTP_V2, feature_category: :shared do
  def load_initializer
    load Rails.root.join('config/initializers/7_gitlab_http.rb')
  end

  it 'handles log_exception_proc' do
    expect(Gitlab::HTTP_V2::Client).to receive(:httparty_perform_request)
      .and_raise(Net::ReadTimeout)

    expect(Gitlab::ErrorTracking).to receive(:log_exception)
      .with(Net::ReadTimeout, {})

    expect { described_class.get('http://example.org') }.to raise_error(Net::ReadTimeout)
  end

  describe 'log_with_level_proc' do
    it 'calls AppJsonLogger with the correct log level and parameters' do
      expect(::Gitlab::AppJsonLogger).to receive(:debug).with({ message: 'Test', caller: anything })

      described_class.configuration.log_with_level(:debug, message: 'Test')
    end
  end

  context 'when silent_mode_enabled is true' do
    before do
      stub_application_setting(silent_mode_enabled: true)
    end

    context 'when sending a POST request' do
      it 'handles silent_mode_log_info_proc' do
        expect(::Gitlab::AppJsonLogger).to receive(:info).with(
          message: "Outbound HTTP request blocked",
          outbound_http_request_method: 'Net::HTTP::Post',
          silent_mode_enabled: true
        )

        expect { described_class.post('http://example.org', silent_mode_enabled: true) }.to raise_error(
          Gitlab::HTTP_V2::SilentModeBlockedError
        )
      end
    end

    context 'when sending a GET request' do
      before do
        stub_request(:get, 'http://example.org').to_return(body: 'hello')
      end

      it 'does not raise an error' do
        expect(::Gitlab::AppJsonLogger).not_to receive(:info)

        expect(described_class.get('http://example.org', silent_mode_enabled: true).body).to eq('hello')
      end
    end
  end

  context 'when configuring allowed_internal_uris' do
    subject(:uris) { described_class.configuration.allowed_internal_uris }

    it do
      is_expected.to contain_exactly(
        URI::HTTP.build(host: 'localhost', port: 80),
        URI::Generic.build(scheme: 'ssh', host: 'localhost', port: 22)
      )
    end

    context 'when the protocol is https' do
      before do
        stub_config_setting(protocol: 'https')
        load_initializer
      end

      it 'uses the correct scheme' do
        expect(uris.first.scheme).to eq('https')
      end
    end
  end
end
