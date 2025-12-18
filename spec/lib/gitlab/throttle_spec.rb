# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Throttle do
  using RSpec::Parameterized::TableSyntax

  describe '.protected_paths_enabled?' do
    subject { described_class.protected_paths_enabled? }

    it 'returns Application Settings throttle_protected_paths_enabled?' do
      expect(Gitlab::CurrentSettings.current_application_settings).to receive(:throttle_protected_paths_enabled?)

      subject
    end
  end

  describe '.bypass_header' do
    subject { described_class.bypass_header }

    it 'is nil' do
      expect(subject).to be_nil
    end

    context 'when a header is configured' do
      before do
        stub_env('GITLAB_THROTTLE_BYPASS_HEADER', 'My-Custom-Header')
      end

      it 'is a funny upper case rack key' do
        expect(subject).to eq('HTTP_MY_CUSTOM_HEADER')
      end
    end
  end

  describe '.rate_limiting_response_text' do
    subject { described_class.rate_limiting_response_text }

    context 'when the setting is not present' do
      before do
        stub_application_setting(rate_limiting_response_text: '')
      end

      it 'returns the default value with a trailing newline' do
        expect(subject).to eq(described_class::DEFAULT_RATE_LIMITING_RESPONSE_TEXT + "\n")
      end
    end

    context 'when the setting is present' do
      let(:response_text) do
        'Rate limit exceeded; see https://docs.gitlab.com/ee/user/gitlab_com/#gitlabcom-specific-rate-limits for more details'
      end

      before do
        stub_application_setting(rate_limiting_response_text: response_text)
      end

      it 'returns the default value with a trailing newline' do
        expect(subject).to eq(response_text + "\n")
      end
    end
  end

  describe '.throttle_authenticated_git_http_options' do
    before do
      stub_application_setting(
        throttle_authenticated_git_http_requests_per_period: 50,
        throttle_authenticated_git_http_period_in_seconds: 30
      )
    end

    it 'returns correct options' do
      options = described_class.throttle_authenticated_git_http_options

      expect(options[:limit].call).to eq(50)
      expect(options[:period].call).to eq(30)
    end
  end
end
