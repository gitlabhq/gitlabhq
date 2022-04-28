# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::Collector::Dsn do
  describe '.build_url' do
    let(:setting) do
      {
        protocol: 'https',
        https: true,
        port: 443,
        host: 'gitlab.example.com',
        relative_url_root: nil
      }
    end

    subject { described_class.build_url('abcdef1234567890', 778) }

    it 'returns a valid URL without explicit port' do
      stub_config_setting(setting)

      is_expected.to eq('https://abcdef1234567890@gitlab.example.com/api/v4/error_tracking/collector/778')
    end

    context 'with non-standard port' do
      it 'returns a valid URL with custom port' do
        setting[:port] = 4567
        stub_config_setting(setting)

        is_expected.to eq('https://abcdef1234567890@gitlab.example.com:4567/api/v4/error_tracking/collector/778')
      end
    end
  end
end
