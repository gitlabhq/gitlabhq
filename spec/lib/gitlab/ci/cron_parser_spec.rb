# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::CronParser, feature_category: :continuous_integration do
  shared_examples_for "returns time in the future" do
    it { is_expected.to be > Time.now }
  end

  shared_examples_for "returns time in the past" do
    it { is_expected.to be < Time.now }
  end

  shared_examples_for 'when cron and cron_timezone are valid' do |returns_time_for_epoch|
    context 'when specific time' do
      let(:cron) { '3 4 5 6 *' }
      let(:cron_timezone) { 'UTC' }

      it_behaves_like returns_time_for_epoch

      it 'returns exact time' do
        expect(subject.min).to eq(3)
        expect(subject.hour).to eq(4)
        expect(subject.day).to eq(5)
        expect(subject.month).to eq(6)
      end
    end

    context 'when specific day of week' do
      let(:cron) { '* * * * 0' }
      let(:cron_timezone) { 'UTC' }

      it_behaves_like returns_time_for_epoch

      it 'returns exact day of week' do
        expect(subject.wday).to eq(0)
      end
    end

    context 'when */ used' do
      let(:cron) { '*/10 */6 */10 */10 *' }
      let(:cron_timezone) { 'UTC' }

      it_behaves_like returns_time_for_epoch

      it 'returns specific time' do
        expect(subject.min).to be_in([0, 10, 20, 30, 40, 50])
        expect(subject.hour).to be_in([0, 6, 12, 18])
        expect(subject.day).to be_in([1, 11, 21, 31])
        expect(subject.month).to be_in([1, 11])
      end
    end

    context 'when range used' do
      let(:cron) { '0,20,40 * 1-5 * *' }
      let(:cron_timezone) { 'UTC' }

      it_behaves_like returns_time_for_epoch

      it 'returns specific time' do
        expect(subject.min).to be_in([0, 20, 40])
        expect(subject.day).to be_in((1..5).to_a)
      end
    end

    context 'when range and / are used' do
      let(:cron) { '3-59/10 * * * *' }
      let(:cron_timezone) { 'UTC' }

      it_behaves_like returns_time_for_epoch

      it 'returns specific time' do
        expect(subject.min).to be_in([3, 13, 23, 33, 43, 53])
      end
    end

    context 'when / is used' do
      let(:cron) { '3/10 * * * *' }
      let(:cron_timezone) { 'UTC' }

      it_behaves_like returns_time_for_epoch

      it 'returns specific time' do
        expect(subject.min).to be_in([3, 13, 23, 33, 43, 53])
      end
    end

    context 'when cron_timezone is TZInfo format' do
      before do
        allow(Time).to receive(:zone)
          .and_return(ActiveSupport::TimeZone['UTC'])
      end

      let(:hour_in_utc) do
        ActiveSupport::TimeZone[cron_timezone]
          .now.change(hour: 0).in_time_zone('UTC').hour
      end

      context 'when cron_timezone is US/Pacific' do
        let(:cron) { '* 0 * * *' }
        let(:cron_timezone) { 'US/Pacific' }

        it_behaves_like returns_time_for_epoch

        context 'when PST (Pacific Standard Time)' do
          it 'converts time in server time zone' do
            travel_to(Time.utc(2017, 1, 1)) do
              expect(subject.hour).to eq(hour_in_utc)
            end
          end
        end

        context 'when PDT (Pacific Daylight Time)' do
          it 'converts time in server time zone' do
            travel_to(Time.utc(2017, 6, 1)) do
              expect(subject.hour).to eq(hour_in_utc)
            end
          end
        end
      end
    end

    context 'when cron_timezone is ActiveSupport::TimeZone format' do
      before do
        allow(Time).to receive(:zone)
          .and_return(ActiveSupport::TimeZone['UTC'])
      end

      let(:hour_in_utc) do
        ActiveSupport::TimeZone[cron_timezone]
          .now.change(hour: 0).in_time_zone('UTC').hour
      end

      context 'when cron_timezone is Berlin' do
        let(:cron) { '* 0 * * *' }
        let(:cron_timezone) { 'Berlin' }

        it_behaves_like returns_time_for_epoch

        context 'when CET (Central European Time)' do
          it 'converts time in server time zone' do
            travel_to(Time.utc(2017, 1, 1)) do
              expect(subject.hour).to eq(hour_in_utc)
            end
          end
        end

        context 'when CEST (Central European Summer Time)' do
          it 'converts time in server time zone' do
            travel_to(Time.utc(2017, 6, 1)) do
              expect(subject.hour).to eq(hour_in_utc)
            end
          end
        end
      end
    end
  end

  shared_examples_for 'when cron_timezone is Eastern Time (US & Canada)' do |returns_time_for_epoch, year|
    let(:cron) { '* 0 * * *' }
    let(:cron_timezone) { 'Eastern Time (US & Canada)' }

    before do
      allow(Time).to receive(:zone)
        .and_return(ActiveSupport::TimeZone['UTC'])
    end

    let(:hour_in_utc) do
      ActiveSupport::TimeZone[cron_timezone]
        .now.change(hour: 0).in_time_zone('UTC').hour
    end

    it_behaves_like returns_time_for_epoch

    context 'when EST (Eastern Standard Time)' do
      it 'converts time in server time zone' do
        travel_to(Time.utc(2017, 1, 1)) do
          expect(subject.hour).to eq(hour_in_utc)
        end
      end
    end

    context 'when EDT (Eastern Daylight Time)' do
      it 'converts time in server time zone' do
        travel_to(Time.utc(2017, 6, 1)) do
          expect(subject.hour).to eq(hour_in_utc)
        end
      end
    end

    context 'when time crosses a Daylight Savings boundary' do
      let(:cron) { '* 0 1 12 *' }

      # Note this previously only failed if the time zone is set
      # to a zone that observes Daylight Savings
      # (e.g. America/Chicago) at the start of the test. Stubbing
      # TZ doesn't appear to be enough.
      it 'generates day without TZInfo::AmbiguousTime error' do
        travel_to(Time.utc(2020, 1, 1)) do
          expect(subject.year).to eq(year)
          expect(subject.month).to eq(12)
          expect(subject.day).to eq(1)
        end
      end
    end
  end

  shared_examples_for 'when cron and cron_timezone are invalid' do
    let(:cron) { 'invalid_cron' }
    let(:cron_timezone) { 'invalid_cron_timezone' }

    it { is_expected.to be_nil }
  end

  shared_examples_for 'when cron syntax is quoted' do
    let(:cron) { "'0 * * * *'" }
    let(:cron_timezone) { 'UTC' }

    it { expect(subject).to be_nil }
  end

  shared_examples_for 'when cron syntax is rufus-scheduler syntax' do
    let(:cron) { 'every 3h' }
    let(:cron_timezone) { 'UTC' }

    it { expect(subject).to be_nil }
  end

  shared_examples_for 'when cron is scheduled to a non existent day' do
    let(:cron) { '0 12 31 2 *' }
    let(:cron_timezone) { 'UTC' }

    it { expect(subject).to be_nil }
  end

  describe '#next_time_from' do
    subject { described_class.new(cron, cron_timezone).next_time_from(current_time) }

    let(:current_time) { Time.now }

    it_behaves_like 'when cron and cron_timezone are valid', 'returns time in the future'

    it_behaves_like 'when cron_timezone is Eastern Time (US & Canada)', 'returns time in the future', 2020

    it_behaves_like 'when cron and cron_timezone are invalid'

    it_behaves_like 'when cron syntax is quoted'

    it_behaves_like 'when cron syntax is rufus-scheduler syntax'

    it_behaves_like 'when cron is scheduled to a non existent day'

    context 'for modulo' do
      let(:cron) { '0 6 * * tue%2' }
      let(:cron_timezone) { 'America/Los_Angeles' }

      context 'when before daylight saving' do
        let(:current_time) { ActiveSupport::TimeZone.new(cron_timezone).parse('2024-02-01') }

        it 'returns the correct future time' do
          expect(subject.to_s).to eq('2024-02-13 14:00:00 UTC')
        end
      end

      context 'when after daylight saving' do
        let(:current_time) { ActiveSupport::TimeZone.new(cron_timezone).parse('2024-05-01') }

        it 'returns the correct future time' do
          expect(subject.to_s).to eq('2024-05-14 13:00:00 UTC')
        end
      end
    end
  end

  describe '#previous_time_from' do
    subject { described_class.new(cron, cron_timezone).previous_time_from(Time.now) }

    it_behaves_like 'when cron and cron_timezone are valid', 'returns time in the past'

    it_behaves_like 'when cron_timezone is Eastern Time (US & Canada)', 'returns time in the past', 2019

    it_behaves_like 'when cron and cron_timezone are invalid'

    it_behaves_like 'when cron syntax is quoted'

    it_behaves_like 'when cron syntax is rufus-scheduler syntax'

    it_behaves_like 'when cron is scheduled to a non existent day'
  end

  describe '#cron_valid?' do
    subject { described_class.new(cron, Gitlab::Ci::CronParser::VALID_SYNTAX_SAMPLE_TIME_ZONE).cron_valid? }

    context 'when cron is valid' do
      let(:cron) { '* * * * *' }

      it { is_expected.to eq(true) }
    end

    context 'when cron is invalid' do
      let(:cron) { '*********' }

      it { is_expected.to eq(false) }
    end

    context 'when cron syntax is quoted' do
      let(:cron) { "'0 * * * *'" }

      it { is_expected.to eq(false) }
    end
  end

  describe '#cron_timezone_valid?' do
    subject { described_class.new(Gitlab::Ci::CronParser::VALID_SYNTAX_SAMPLE_CRON, cron_timezone).cron_timezone_valid? }

    context 'when cron is valid' do
      let(:cron_timezone) { 'Europe/Istanbul' }

      it { is_expected.to eq(true) }
    end

    context 'when cron is invalid' do
      let(:cron_timezone) { 'Invalid-zone' }

      it { is_expected.to eq(false) }
    end

    context 'when cron_timezone is ActiveSupport::TimeZone format' do
      let(:cron_timezone) { 'Eastern Time (US & Canada)' }

      it { is_expected.to eq(true) }
    end
  end

  describe '.parse_natural', :aggregate_failures do
    let(:cron_line) { described_class.parse_natural_with_timestamp(time, { unit: 'day', duration: 1 }) }
    let(:time) { Time.parse('Mon, 30 Aug 2021 06:29:44.067132000 UTC +00:00') }
    let(:hours) { Fugit::Cron.parse(cron_line).hours }
    let(:minutes) { Fugit::Cron.parse(cron_line).minutes }
    let(:weekdays) { Fugit::Cron.parse(cron_line).weekdays.first }
    let(:months) { Fugit::Cron.parse(cron_line).months }

    context 'when repeat cycle is day' do
      it 'generates daily cron expression', :aggregate_failures do
        expect(hours).to include time.hour
        expect(minutes).to include time.min
      end
    end

    context 'when repeat cycle is week' do
      let(:cron_line) { described_class.parse_natural_with_timestamp(time, { unit: 'week', duration: 1 }) }

      it 'generates weekly cron expression', :aggregate_failures do
        expect(hours).to include time.hour
        expect(minutes).to include time.min
        expect(weekdays).to include time.wday
      end
    end

    context 'when repeat cycle is month' do
      let(:cron_line) { described_class.parse_natural_with_timestamp(time, { unit: 'month', duration: 3 }) }

      it 'generates monthly cron expression', :aggregate_failures do
        expect(minutes).to include time.min
        expect(months).to include time.month
      end

      context 'when an unsupported duration is specified' do
        subject { described_class.parse_natural_with_timestamp(time, { unit: 'month', duration: 7 }) }

        it 'raises an exception' do
          expect { subject }.to raise_error(NotImplementedError, 'The cadence {:unit=>"month", :duration=>7} is not supported')
        end
      end
    end

    context 'when repeat cycle is year' do
      let(:cron_line) { described_class.parse_natural_with_timestamp(time, { unit: 'year', duration: 1 }) }

      it 'generates yearly cron expression', :aggregate_failures do
        expect(hours).to include time.hour
        expect(minutes).to include time.min
        expect(months).to include time.month
      end
    end

    context 'when the repeat cycle is not implemented' do
      subject { described_class.parse_natural_with_timestamp(time, { unit: 'quarterly', duration: 1 }) }

      it 'raises an exception' do
        expect { subject }.to raise_error(NotImplementedError, 'The cadence unit quarterly is not implemented')
      end
    end
  end

  describe '#match?' do
    let(:run_date) { Time.zone.local(2021, 3, 2, 1, 0) }

    subject(:matched) { described_class.new(cron, Gitlab::Ci::CronParser::VALID_SYNTAX_SAMPLE_TIME_ZONE).match?(run_date) }

    context 'when cron matches up' do
      let(:cron) { '0 1 2 3 *' }

      it { is_expected.to eq(true) }
    end

    context 'when cron does not match' do
      let(:cron) { '5 4 3 2 1' }

      it { is_expected.to eq(false) }
    end
  end
end
