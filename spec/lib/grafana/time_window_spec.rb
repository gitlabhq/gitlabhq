# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Grafana::TimeWindow do
  let(:from) { '1552799400000' }
  let(:to) { '1552828200000' }

  around do |example|
    travel_to(Time.utc(2019, 3, 17, 13, 10)) { example.run }
  end

  describe '#formatted' do
    subject { described_class.new(from, to).formatted }

    it { is_expected.to eq(start: "2019-03-17T05:10:00Z", end: "2019-03-17T13:10:00Z") }
  end

  describe '#in_milliseconds' do
    subject { described_class.new(from, to).in_milliseconds }

    it { is_expected.to eq(from: 1552799400000, to: 1552828200000) }

    context 'when non-unix parameters are provided' do
      let(:to) { Time.now.to_s }

      let(:default_from) { 8.hours.ago.to_i * 1000 }
      let(:default_to) { Time.now.to_i * 1000 }

      it { is_expected.to eq(from: default_from, to: default_to) }
    end
  end
end

RSpec.describe Grafana::RangeWithDefaults do
  let(:from) { Grafana::Timestamp.from_ms_since_epoch('1552799400000') }
  let(:to) { Grafana::Timestamp.from_ms_since_epoch('1552828200000') }

  around do |example|
    travel_to(Time.utc(2019, 3, 17, 13, 10)) { example.run }
  end

  describe '#to_hash' do
    subject { described_class.new(from: from, to: to).to_hash }

    it { is_expected.to eq(from: from, to: to) }

    context 'when only "to" is provided' do
      let(:from) { nil }

      it 'has the expected properties' do
        expect(subject[:to]).to eq(to)
        expect(subject[:from].time).to eq(to.time - 8.hours)
      end
    end

    context 'when only "from" is provided' do
      let(:to) { nil }

      it 'has the expected properties' do
        expect(subject[:to].time).to eq(from.time + 8.hours)
        expect(subject[:from]).to eq(from)
      end
    end

    context 'when no parameters are provided' do
      let(:to) { nil }
      let(:from) { nil }

      let(:default_from) { 8.hours.ago }
      let(:default_to) { Time.now }

      it 'has the expected properties' do
        expect(subject[:to].time).to eq(default_to)
        expect(subject[:from].time).to eq(default_from)
      end
    end
  end
end

RSpec.describe Grafana::Timestamp do
  let(:timestamp) { Time.at(1552799400) }

  around do |example|
    travel_to(Time.utc(2019, 3, 17, 13, 10)) { example.run }
  end

  describe '#formatted' do
    subject { described_class.new(timestamp).formatted }

    it { is_expected.to eq "2019-03-17T05:10:00Z" }
  end

  describe '#to_ms' do
    subject { described_class.new(timestamp).to_ms }

    it { is_expected.to eq 1552799400000 }
  end

  describe '.from_ms_since_epoch' do
    let(:timestamp) { '1552799400000' }

    subject { described_class.from_ms_since_epoch(timestamp) }

    it { is_expected.to be_a described_class }

    context 'when the input is not a unix-ish timestamp' do
      let(:timestamp) { Time.now.to_s }

      it 'raises an error' do
        expect { subject }.to raise_error(Grafana::Timestamp::Error)
      end
    end
  end
end
