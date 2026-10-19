# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::MobilePush::WorkingHours, feature_category: :notifications do
  # 2026-10-05 is a Monday; Europe/Berlin is UTC+2 (CEST) in early October.
  let(:zone) { ActiveSupport::TimeZone['Europe/Berlin'] }
  let(:window) { described_class::Window.new(start_minute: 9 * 60, end_minute: 17 * 60) }
  let(:days) { %w[monday tuesday wednesday thursday friday] }

  subject(:schedule) { described_class.new(window: window, days: days, zone: zone) }

  describe '#deliver_now?' do
    it 'delivers inside the window' do
      expect(schedule.deliver_now?(Time.utc(2026, 10, 6, 8, 0))).to be(true) # Tue 10:00
    end

    it 'skips before the start and at the end, the end being exclusive' do
      expect(schedule.deliver_now?(Time.utc(2026, 10, 6, 6, 59))).to be(false) # 08:59
      expect(schedule.deliver_now?(Time.utc(2026, 10, 6, 14, 59))).to be(true) # 16:59
      expect(schedule.deliver_now?(Time.utc(2026, 10, 6, 15, 0))).to be(false) # 17:00
    end

    it 'skips on a non-working day' do
      expect(schedule.deliver_now?(Time.utc(2026, 10, 10, 8, 0))).to be(false) # Sat 10:00
    end

    it 'evaluates in the given zone, not the server zone' do
      auckland = described_class.new(window: window, days: days, zone: ActiveSupport::TimeZone['Pacific/Auckland'])

      # 22:00 UTC on Tuesday is 11:00 on Wednesday in Auckland.
      expect(auckland.deliver_now?(Time.utc(2026, 10, 6, 22, 0))).to be(true)
    end

    context 'with an overnight window' do
      let(:window) { described_class::Window.new(start_minute: 22 * 60, end_minute: 6 * 60) }

      it 'counts the part after midnight as the previous working day' do
        expect(schedule.deliver_now?(Time.utc(2026, 10, 5, 21, 0))).to be(true)  # Mon 23:00
        expect(schedule.deliver_now?(Time.utc(2026, 10, 6, 3, 0))).to be(true)   # Tue 05:00
        expect(schedule.deliver_now?(Time.utc(2026, 10, 6, 5, 0))).to be(false)  # Tue 07:00
        expect(schedule.deliver_now?(Time.utc(2026, 10, 9, 23, 0))).to be(true)  # Sat 01:00, Friday's shift
        expect(schedule.deliver_now?(Time.utc(2026, 10, 4, 23, 0))).to be(false) # Mon 01:00, Sunday's shift
      end
    end

    context 'on every day of the week' do
      let(:days) { described_class::DAYS }

      it 'is unaffected by a DST transition day' do
        # 2026-03-29: Berlin springs forward at 02:00 CET.
        expect(schedule.deliver_now?(Time.utc(2026, 3, 29, 8, 0))).to be(true)   # 10:00 CEST
        expect(schedule.deliver_now?(Time.utc(2026, 3, 29, 0, 30))).to be(false) # 01:30 CET
      end
    end

    describe 'failing open' do
      let(:night) { Time.utc(2026, 10, 6, 22, 0) }

      def schedule_with(**overrides)
        described_class.new(**{ window: window, days: days, zone: zone }.merge(overrides))
      end

      it 'delivers when a time is missing' do
        no_start = described_class::Window.new(start_minute: nil, end_minute: 17 * 60)
        no_end = described_class::Window.new(start_minute: 9 * 60, end_minute: nil)

        expect(schedule_with(window: no_start).deliver_now?(night)).to be(true)
        expect(schedule_with(window: no_end).deliver_now?(night)).to be(true)
      end

      it 'delivers when the start equals the end' do
        point = described_class::Window.new(start_minute: 9 * 60, end_minute: 9 * 60)

        expect(schedule_with(window: point).deliver_now?(night)).to be(true)
      end

      it 'delivers when no known day is set' do
        expect(schedule_with(days: []).deliver_now?(night)).to be(true)
        expect(schedule_with(days: %w[funday]).deliver_now?(night)).to be(true)
      end

      it 'delivers when the zone is unknown' do
        expect(schedule_with(zone: nil).deliver_now?(night)).to be(true)
      end
    end
  end

  describe '#next_window_start' do
    it 'is today at the start when now is before it on a working day' do
      expect(schedule.next_window_start(Time.utc(2026, 10, 6, 6, 0))) # Tue 08:00
        .to eq(Time.utc(2026, 10, 6, 7, 0))
    end

    it 'is the next working day after the end' do
      expect(schedule.next_window_start(Time.utc(2026, 10, 9, 16, 0))) # Fri 18:00
        .to eq(Time.utc(2026, 10, 12, 7, 0))
    end

    it 'skips non-working days' do
      expect(schedule.next_window_start(Time.utc(2026, 10, 10, 8, 0))) # Sat 10:00
        .to eq(Time.utc(2026, 10, 12, 7, 0))
    end

    it 'returns UTC' do
      expect(schedule.next_window_start(Time.utc(2026, 10, 6, 6, 0))).to be_utc
    end

    it 'looks a week ahead when the only working day is today and its start has passed' do
      sundays = described_class.new(window: window, days: %w[sunday], zone: zone)

      expect(sundays.next_window_start(Time.utc(2026, 10, 11, 10, 0))) # Sun 12:00
        .to eq(Time.utc(2026, 10, 18, 7, 0))
    end

    context 'with a start inside a DST transition, on every day of the week' do
      let(:days) { described_class::DAYS }
      let(:window) { described_class::Window.new(start_minute: (2 * 60) + 30, end_minute: 17 * 60) }

      it 'moves a start inside the spring-forward gap an hour later' do
        # 02:30 does not exist on 2026-03-29 in Berlin; Rails lands on 03:30 CEST.
        expect(schedule.next_window_start(Time.utc(2026, 3, 29, 0, 0))).to eq(Time.utc(2026, 3, 29, 1, 30))
      end

      it 'takes the first occurrence of a start inside the fall-back overlap' do
        # 02:30 happens twice on 2026-10-25 in Berlin; Rails picks the CEST one.
        expect(schedule.next_window_start(Time.utc(2026, 10, 24, 23, 0))).to eq(Time.utc(2026, 10, 25, 0, 30))
      end
    end

    it 'is nil when the schedule is unusable' do
      unusable = described_class.new(window: window, days: [], zone: zone)

      expect(unusable.next_window_start(Time.utc(2026, 10, 6, 6, 0))).to be_nil
    end
  end
end
