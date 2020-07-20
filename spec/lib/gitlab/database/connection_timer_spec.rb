# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::ConnectionTimer do
  let(:current_clock_value) { 1234.56 }

  before do
    allow(described_class).to receive(:current_clock_value).and_return(current_clock_value)
  end

  describe '.starting_now' do
    let(:default_interval) { described_class::DEFAULT_INTERVAL }
    let(:random_value) { 120 }

    before do
      allow(described_class).to receive(:rand).and_return(random_value)
    end

    context 'when the configured interval is positive' do
      before do
        allow(described_class).to receive(:interval).and_return(default_interval)
      end

      it 'randomizes the interval of the created timer' do
        timer = described_class.starting_now

        expect(timer.interval).to eq(default_interval + random_value)
      end
    end

    context 'when the configured interval is not positive' do
      before do
        allow(described_class).to receive(:interval).and_return(0)
      end

      it 'sets the interval of the created timer to nil' do
        timer = described_class.starting_now

        expect(timer.interval).to be_nil
      end
    end
  end

  describe '.expired?' do
    context 'when the interval is positive' do
      context 'when the interval has elapsed' do
        it 'returns true' do
          timer = described_class.new(20, current_clock_value - 30)

          expect(timer).to be_expired
        end
      end

      context 'when the interval has not elapsed' do
        it 'returns false' do
          timer = described_class.new(20, current_clock_value - 10)

          expect(timer).not_to be_expired
        end
      end
    end

    context 'when the interval is not positive' do
      context 'when the interval has elapsed' do
        it 'returns false' do
          timer = described_class.new(0, current_clock_value - 30)

          expect(timer).not_to be_expired
        end
      end

      context 'when the interval has not elapsed' do
        it 'returns false' do
          timer = described_class.new(0, current_clock_value + 10)

          expect(timer).not_to be_expired
        end
      end
    end

    context 'when the interval is nil' do
      it 'returns false' do
        timer = described_class.new(nil, current_clock_value - 30)

        expect(timer).not_to be_expired
      end
    end
  end

  describe '.reset!' do
    it 'updates the timer clock value' do
      timer = described_class.new(20, current_clock_value - 20)
      expect(timer.starting_clock_value).not_to eql(current_clock_value)

      timer.reset!
      expect(timer.starting_clock_value).to eql(current_clock_value)
    end
  end
end
