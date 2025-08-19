# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Utils::TimeIntegerConverter, feature_category: :shared do
  let(:time_string) { '2024-01-01 12:34:56.123456 +0000' }
  let(:time_integer) { 1_704_112_496_123_456 }
  let(:converter) { described_class.new(input) }

  describe '#to_i' do
    subject { converter.to_i }

    context 'when input is a Time object' do
      let(:input) { Time.parse(time_string) } # rubocop:disable Rails/TimeZone -- Necessary for testing

      it { is_expected.to eq(time_integer) }

      context 'when custom precision is provided' do
        let(:converter) { described_class.new(input, 1_000) }

        it { is_expected.to eq(time_integer / 1_000) }
      end
    end

    context 'when input is an ActiveSupport::TimeWithZone object' do
      let(:input) { Time.zone.parse(time_string) }

      it { is_expected.to eq(time_integer) }

      context 'when custom precision is provided' do
        let(:converter) { described_class.new(input, 1_000) }

        it { is_expected.to eq(time_integer / 1_000) }
      end
    end

    context 'when input is not a Time object' do
      let(:input) { 12345 }

      it 'raises INVALID_INPUT_TYPE' do
        expect { converter.to_i }.to raise_error(
          Gitlab::Utils::TimeIntegerConverter::INVALID_INPUT_TYPE,
          'input must be a valid Time object'
        )
      end
    end

    context 'when input is nil' do
      let(:input) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe '#to_time' do
    subject { converter.to_time }

    context 'when input is an Integer' do
      let(:input) { time_integer }

      it { is_expected.to eq(Time.zone.parse(time_string)) }

      context 'when custom precision is provided' do
        let(:converter) { described_class.new(input / 1_000, 1_000) }

        it { is_expected.to eq(Time.zone.parse('2024-01-01 12:34:56.123000 +0000')) }
      end
    end

    context 'when input is not an Integer' do
      let(:input) { 'not_a_number' }

      it 'raises INVALID_INPUT_TYPE' do
        expect { converter.to_time }.to raise_error(
          Gitlab::Utils::TimeIntegerConverter::INVALID_INPUT_TYPE,
          'input must be an Integer'
        )
      end

      context 'when input is a Float' do
        let(:input) { 1.2 }

        it 'raises INVALID_INPUT_TYPE' do
          expect { converter.to_time }.to raise_error(
            Gitlab::Utils::TimeIntegerConverter::INVALID_INPUT_TYPE,
            'input must be an Integer'
          )
        end
      end

      context 'when input is a valid Integer string representation' do
        let(:input) { time_integer.to_s }

        it { is_expected.to eq(Time.zone.parse(time_string)) }
      end
    end
  end
end
