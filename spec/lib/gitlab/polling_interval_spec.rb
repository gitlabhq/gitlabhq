require 'spec_helper'

describe Gitlab::PollingInterval do
  let(:polling_interval) { described_class }

  describe '.set_header' do
    let(:headers) { {} }
    let(:response) { double(headers: headers) }

    context 'when polling is disabled' do
      before do
        stub_application_setting(polling_interval_multiplier: 0)
      end

      it 'sets value to -1' do
        polling_interval.set_header(response, interval: 10_000)

        expect(headers['Poll-Interval']).to eq('-1')
      end
    end

    context 'when polling is enabled' do
      before do
        stub_application_setting(polling_interval_multiplier: 0.33333)
      end

      it 'applies modifier to base interval' do
        polling_interval.set_header(response, interval: 10_000)

        expect(headers['Poll-Interval']).to eq('3333')
      end
    end
  end
end
