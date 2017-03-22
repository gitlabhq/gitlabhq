require 'spec_helper'

module Ci
  describe CronParser, lib: true do
    describe '#next_time_from_now' do
      subject { described_class.new(cron, cron_time_zone).next_time_from_now }

      context 'when cron and cron_time_zone are valid' do
        context 'at 00:00, 00:10, 00:20, 00:30, 00:40, 00:50' do
          let(:cron) { '*/10 * * * *' }
          let(:cron_time_zone) { 'US/Pacific' }

          it 'returns next time from now' do
            time = Time.now.in_time_zone(cron_time_zone)
            time = time + 10.minutes
            time = time.change(sec: 0, min: time.min-time.min%10)
            is_expected.to eq(time)
          end
        end

        context 'at 10:00, 20:00' do
          let(:cron) { '0 */10 * * *' }
          let(:cron_time_zone) { 'US/Pacific' }

          it 'returns next time from now' do
            time = Time.now.in_time_zone(cron_time_zone)
            time = time + 10.hours
            time = time.change(sec: 0, min: 0, hour: time.hour-time.hour%10)
            is_expected.to eq(time)
          end
        end

        context 'when cron is every 10 days' do
          let(:cron) { '0 0 */10 * *' }
          let(:cron_time_zone) { 'US/Pacific' }

          it 'returns next time from now' do
            time = Time.now.in_time_zone(cron_time_zone)
            time = time + 10.days
            time = time.change(sec: 0, min: 0, hour: 0, day: time.day-time.day%10)
            is_expected.to eq(time)
          end
        end

        context 'when cron is every week 2:00 AM' do
          let(:cron) { '0 2 * * *' }
          let(:cron_time_zone) { 'US/Pacific' }

          it 'returns next time from now' do
            time = Time.now.in_time_zone(cron_time_zone)
            is_expected.to eq(time.change(sec: 0, min: 0, hour: 2, day: time.day+1))
          end
        end

        context 'when cron_time_zone is US/Pacific' do
          let(:cron) { '0 1 * * *' }
          let(:cron_time_zone) { 'US/Pacific' }

          it 'returns next time from now' do
            time = Time.now.in_time_zone(cron_time_zone)
            is_expected.to eq(time.change(sec: 0, min: 0, hour: 1, day: time.day+1))
          end
        end

        context 'when cron_time_zone is Europe/London' do
          let(:cron) { '0 1 * * *' }
          let(:cron_time_zone) { 'Europe/London' }

          it 'returns next time from now' do
            time = Time.now.in_time_zone(cron_time_zone)
            is_expected.to eq(time.change(sec: 0, min: 0, hour: 1, day: time.day+1))
          end
        end

        context 'when cron_time_zone is Asia/Tokyo' do
          let(:cron) { '0 1 * * *' }
          let(:cron_time_zone) { 'Asia/Tokyo' }

          it 'returns next time from now' do
            time = Time.now.in_time_zone(cron_time_zone)
            is_expected.to eq(time.change(sec: 0, min: 0, hour: 1, day: time.day+1))
          end
        end
      end

      context 'when cron is given and cron_time_zone is not given' do
        let(:cron) { '0 1 * * *' }

        it 'returns next time from now in utc' do
          obj = described_class.new(cron).next_time_from_now
          time = Time.now.in_time_zone('UTC')
          expect(obj).to eq(time.change(sec: 0, min: 0, hour: 1, day: time.day+1))
        end 
      end

      context 'when cron and cron_time_zone are invalid' do
        let(:cron) { 'hack' }
        let(:cron_time_zone) { 'hack' }

        it 'returns nil' do
          is_expected.to be_nil
        end 
      end
    end

    describe '#valid_syntax?' do
      subject { described_class.new(cron, cron_time_zone).valid_syntax? }

      context 'when cron and cron_time_zone are valid' do
        let(:cron) { '* * * * *' }
        let(:cron_time_zone) { 'Europe/Istanbul' }

        it 'returns true' do
          is_expected.to eq(true)
        end 
      end

      context 'when cron and cron_time_zone are invalid' do
        let(:cron) { 'hack' }
        let(:cron_time_zone) { 'hack' }

        it 'returns false' do
          is_expected.to eq(false)
        end 
      end
    end
  end
end
