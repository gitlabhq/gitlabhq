# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TimeZoneHelper, :aggregate_failures do
  describe '#timezone_data' do
    context 'with short format' do
      subject(:timezone_data) { helper.timezone_data }

      it 'matches schema' do
        expect(timezone_data).not_to be_empty

        timezone_data.each_with_index do |timezone_hash, i|
          expect(timezone_hash.keys).to contain_exactly(
            :identifier,
            :name,
            :offset
          ), "Failed at index #{i}"
        end
      end

      it 'formats for display' do
        tz = ActiveSupport::TimeZone.all[0]

        expect(timezone_data[0]).to eq(
          identifier: tz.tzinfo.identifier,
          name: tz.name,
          offset: tz.now.utc_offset
        )
      end
    end

    context 'with abbr format' do
      subject(:timezone_data) { helper.timezone_data(format: :abbr) }

      it 'matches schema' do
        expect(timezone_data).not_to be_empty

        timezone_data.each_with_index do |timezone_hash, i|
          expect(timezone_hash.keys).to contain_exactly(
            :identifier,
            :abbr
          ), "Failed at index #{i}"
        end
      end

      it 'formats for display' do
        tz = ActiveSupport::TimeZone.all[0]

        expect(timezone_data[0]).to eq(
          identifier: tz.tzinfo.identifier,
          abbr: tz.tzinfo.strftime('%Z')
        )
      end
    end

    context 'with full format' do
      subject(:timezone_data) { helper.timezone_data(format: :full) }

      it 'matches schema' do
        expect(timezone_data).not_to be_empty

        timezone_data.each_with_index do |timezone_hash, i|
          expect(timezone_hash.keys).to contain_exactly(
            :identifier,
            :name,
            :abbr,
            :offset,
            :formatted_offset
          ), "Failed at index #{i}"
        end
      end

      it 'formats for display' do
        tz = ActiveSupport::TimeZone.all[0]

        expect(timezone_data[0]).to eq(
          identifier: tz.tzinfo.identifier,
          name: tz.name,
          abbr: tz.tzinfo.strftime('%Z'),
          offset: tz.now.utc_offset,
          formatted_offset: tz.now.formatted_offset
        )
      end
    end

    context 'with unknown format' do
      subject(:timezone_data) { helper.timezone_data(format: :unknown) }

      it 'raises an exception' do
        expect { timezone_data }.to raise_error ArgumentError, 'Invalid format :unknown. Valid formats are :short, :abbr, :full.'
      end
    end
  end

  describe '#timezone_data_with_unique_identifiers' do
    subject { helper.timezone_data_with_unique_identifiers }

    before do
      allow(helper).to receive(:timezone_data).and_return([
        { identifier: 'Europe/London', name: 'London' },
        { identifier: 'Europe/London', name: 'Edinburgh' },
        { identifier: 'Europe/Berlin', name: 'Berlin' },
        { identifier: 'Europe/London', name: 'Hogwarts' }

      ])
    end

    let(:expected) do
      [
        { identifier: 'Europe/London', name: 'Edinburgh, Hogwarts, London' },
        { identifier: 'Europe/Berlin', name: 'Berlin' }
      ]
    end

    it { is_expected.to eq(expected) }
  end

  describe '#local_time' do
    let_it_be(:timezone) { 'America/Los_Angeles' }

    before do
      travel_to Time.find_zone(timezone).local(2021, 7, 20, 15, 30, 45)
    end

    context 'when timezone is `nil`' do
      it 'returns `nil`' do
        expect(helper.local_time(nil)).to eq(nil)
      end
    end

    context 'when timezone is blank' do
      it 'returns `nil`' do
        expect(helper.local_time('')).to eq(nil)
      end
    end

    context 'when a valid timezone is passed' do
      it 'returns local time' do
        expect(helper.local_time(timezone)).to eq('3:30 PM')
      end
    end

    context 'when an invalid timezone is passed' do
      it 'returns local time using the configured default timezone (UTC in this case)' do
        expect(helper.local_time('Foo/Bar')).to eq('10:30 PM')
      end
    end
  end

  describe '#local_timezone_instance' do
    let_it_be(:timezone) { 'UTC' }

    before do
      travel_to Time.find_zone(timezone).local(2021, 7, 20, 15, 30, 45)
    end

    context 'when timezone is `nil`' do
      it 'returns the system timezone instance' do
        expect(helper.local_timezone_instance(nil).name).to eq(timezone)
      end
    end

    context 'when timezone is blank' do
      it 'returns the system timezone instance' do
        expect(helper.local_timezone_instance('').name).to eq(timezone)
      end
    end

    context 'when a valid timezone is passed' do
      it 'returns the local time instance' do
        expect(helper.local_timezone_instance('America/Los_Angeles').name).to eq('America/Los_Angeles')
      end
    end

    context 'when an invalid timezone is passed' do
      it 'returns the system timezone instance' do
        expect(helper.local_timezone_instance('Foo/Bar').name).to eq(timezone)
      end
    end
  end
end
