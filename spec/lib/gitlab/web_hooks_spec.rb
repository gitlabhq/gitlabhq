# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::WebHooks, feature_category: :webhooks do
  describe '.normalize_dates' do
    subject(:normalized) { described_class.normalize_dates(value) }

    around do |example|
      Time.use_zone('UTC') { example.run }
    end

    context 'with a Time' do
      let(:value) { Time.utc(2026, 4, 23, 12, 30, 45, 123_000) }

      it { is_expected.to eq('2026-04-23T12:30:45.123Z') }
    end

    context 'with a DateTime' do
      let(:value) { DateTime.new(2026, 4, 23, 12, 30, 45) }

      it 'serializes to ISO 8601 with millisecond precision' do
        expect(normalized).to eq(value.iso8601(3))
      end
    end

    context 'with an ActiveSupport::TimeWithZone' do
      let(:value) { Time.zone.local(2026, 4, 23, 12, 30, 45, 123_000) }

      it { is_expected.to eq('2026-04-23T12:30:45.123Z') }
    end

    context 'with a Date' do
      let(:value) { Date.new(2026, 4, 23) }

      it { is_expected.to eq('2026-04-23') }
    end

    context 'with a Hash that contains a Time' do
      let(:time) { Time.utc(2026, 4, 23, 12, 30, 45, 123_000) }
      let(:value) { { 'meta' => { 'when' => time, 'label' => 'x' } } }

      it 'recurses and serializes nested Time values while preserving other scalars' do
        expect(normalized).to eq('meta' => { 'when' => '2026-04-23T12:30:45.123Z', 'label' => 'x' })
      end
    end

    context 'with an Array of Hashes that contain Times (pipeline-builds shape)' do
      let(:time) { Time.utc(2026, 4, 23, 12, 30, 45, 123_000) }
      let(:value) do
        [
          { 'name' => 'rspec', 'started_at' => time, 'finished_at' => time },
          { 'name' => 'jest',  'started_at' => time, 'finished_at' => nil  }
        ]
      end

      it 'recurses through the array and each element' do
        iso = '2026-04-23T12:30:45.123Z'
        expect(normalized).to eq(
          [
            { 'name' => 'rspec', 'started_at' => iso, 'finished_at' => iso },
            { 'name' => 'jest',  'started_at' => iso, 'finished_at' => nil }
          ]
        )
      end
    end

    context 'with scalar values that are not time-like' do
      ['refs/heads/main', 42, 3.14, true, false, nil, :sym].each do |scalar|
        context "for #{scalar.inspect}" do
          let(:value) { scalar }

          it { is_expected.to eq(scalar) }
        end
      end
    end
  end
end
