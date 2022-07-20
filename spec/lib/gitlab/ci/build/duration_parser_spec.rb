# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::DurationParser do
  describe '.validate_duration', :request_store do
    subject { described_class.validate_duration(value) }

    context 'with never' do
      let(:value) { 'never' }

      it { is_expected.to be_truthy }
    end

    context 'with never value camelized' do
      let(:value) { 'Never' }

      it { is_expected.to be_truthy }
    end

    context 'with a duration' do
      let(:value) { '1 Day' }
      let(:other_value) { '30 seconds' }

      it { is_expected.to be_truthy }

      it 'caches data' do
        expect(ChronicDuration).to receive(:parse).with(value).once.and_call_original
        expect(ChronicDuration).to receive(:parse).with(other_value).once.and_call_original

        2.times do
          expect(described_class.validate_duration(value)).to eq(86400)
          expect(described_class.validate_duration(other_value)).to eq(30)
        end
      end
    end

    context 'without a duration' do
      let(:value) { 'something' }

      it { is_expected.to be_falsy }

      it 'caches data' do
        expect(ChronicDuration).to receive(:parse).with(value).once.and_call_original

        2.times do
          expect(described_class.validate_duration(value)).to be_falsey
        end
      end
    end
  end

  describe '#seconds_from_now' do
    subject { described_class.new(value).seconds_from_now }

    context 'with never' do
      let(:value) { 'never' }

      it { is_expected.to be_nil }
    end

    context 'with an empty string' do
      let(:value) { '' }

      it { is_expected.to be_nil }
    end

    context 'with a duration' do
      let(:value) { '1 day' }

      it { is_expected.to be_like_time(1.day.from_now) }
    end
  end
end
