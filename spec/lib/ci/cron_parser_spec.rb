require 'spec_helper'

module Ci
  describe CronParser, lib: true do
    describe '#next_time_from' do
      subject { described_class.new(cron, cron_time_zone).next_time_from(Time.now) }

      context 'when cron and cron_time_zone are valid' do
        context 'when specific time' do
          let(:cron) { '3 4 5 6 *' }
          let(:cron_time_zone) { 'UTC' }

          it 'returns exact time in the future' do
            expect(subject).to be > Time.now
            expect(subject.min).to eq(3)
            expect(subject.hour).to eq(4)
            expect(subject.day).to eq(5)
            expect(subject.month).to eq(6)
          end
        end

        context 'when specific day of week' do
          let(:cron) { '* * * * 0' }
          let(:cron_time_zone) { 'UTC' }

          it 'returns exact day of week in the future' do
            expect(subject).to be > Time.now
            expect(subject.wday).to eq(0)
          end
        end

        context 'when slash used' do
          let(:cron) { '*/10 */6 */10 */10 *' }
          let(:cron_time_zone) { 'UTC' }

          it 'returns exact minute' do
            expect(subject).to be > Time.now
            expect(subject.min).to be_in([0, 10, 20, 30, 40, 50])
            expect(subject.hour).to be_in([0, 6, 12, 18])
            expect(subject.day).to be_in([1, 11, 21, 31])
            expect(subject.month).to be_in([1, 11])
          end
        end

        context 'when range used' do
          let(:cron) { '0,20,40 * 1-5 * *' }
          let(:cron_time_zone) { 'UTC' }

          it 'returns next time from now' do
            expect(subject).to be > Time.now
            expect(subject.min).to be_in([0, 20, 40])
            expect(subject.day).to be_in((1..5).to_a)
          end
        end

        context 'when cron_time_zone is US/Pacific' do
          let(:cron) { '0 0 * * *' }
          let(:cron_time_zone) { 'US/Pacific' }

          it 'returns next time from now' do
            expect(subject).to be > Time.now
          end

          it 'converts time in server time zone' do
            expect(subject.hour).to eq(7)
          end
        end
      end

      context 'when cron and cron_time_zone are invalid' do
        let(:cron) { 'invalid_cron' }
        let(:cron_time_zone) { 'invalid_cron_time_zone' }

        it 'returns nil' do
          is_expected.to be_nil
        end 
      end
    end

    describe '#validation' do
      it 'returns results' do
        is_valid_cron, is_valid_cron_time_zone = described_class.new('* * * * *', 'Europe/Istanbul').validation
        expect(is_valid_cron).to eq(true)
        expect(is_valid_cron_time_zone).to eq(true)
      end

      it 'returns results' do
        is_valid_cron, is_valid_cron_time_zone = described_class.new('*********', 'Europe/Istanbul').validation
        expect(is_valid_cron).to eq(false)
        expect(is_valid_cron_time_zone).to eq(true)
      end

      it 'returns results' do
        is_valid_cron, is_valid_cron_time_zone = described_class.new('* * * * *', 'Invalid-zone').validation
        expect(is_valid_cron).to eq(true)
        expect(is_valid_cron_time_zone).to eq(false)
      end
    end
  end
end
