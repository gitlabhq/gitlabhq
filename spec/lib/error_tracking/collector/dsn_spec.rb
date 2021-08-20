# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::Collector::Dsn do
  describe '.build__url' do
    let(:gitlab) do
      double(
        protocol: 'https',
        https: true,
        host: 'gitlab.example.com',
        port: '4567',
        relative_url_root: nil
      )
    end

    subject { described_class.build_url('abcdef1234567890', 778) }

    it 'returns a valid URL' do
      allow(Settings).to receive(:gitlab).and_return(gitlab)
      allow(Settings).to receive(:gitlab_on_standard_port?).and_return(false)

      is_expected.to eq('https://abcdef1234567890@gitlab.example.com:4567/api/v4/error_tracking/collector/778')
    end
  end
end
