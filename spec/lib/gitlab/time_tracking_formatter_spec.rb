# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TimeTrackingFormatter do
  describe '#parse' do
    subject { described_class.parse(duration_string) }

    context 'positive durations' do
      let(:duration_string) { '3h 20m' }

      it { expect(subject).to eq(12_000) }
    end

    context 'negative durations' do
      let(:duration_string) { '-3h 20m' }

      it { expect(subject).to eq(-12_000) }
    end

    context 'durations with months' do
      let(:duration_string) { '1mo' }

      it 'uses our custom conversions' do
        expect(subject).to eq(576_000)
      end
    end
  end

  describe '#output' do
    let(:num_seconds) { 178_800 }

    subject { described_class.output(num_seconds) }

    context 'time_tracking_limit_to_hours setting is true' do
      before do
        stub_application_setting(time_tracking_limit_to_hours: true)
      end

      it { expect(subject).to eq('49h 40m') }
    end

    context 'time_tracking_limit_to_hours setting is false' do
      before do
        stub_application_setting(time_tracking_limit_to_hours: false)
      end

      it { expect(subject).to eq('1w 1d 1h 40m') }
    end

    context 'handles negative time input' do
      let(:num_seconds) { -178_800 }

      it { expect(subject).to eq('-1w 1d 1h 40m') }
    end
  end
end
