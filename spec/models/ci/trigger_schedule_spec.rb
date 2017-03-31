require 'spec_helper'

describe Ci::TriggerSchedule, models: true do

  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:trigger) }
  # it { is_expected.to validate_presence_of :cron }
  # it { is_expected.to validate_presence_of :cron_time_zone }
  it { is_expected.to respond_to :ref }

  it 'should validate ref existence' do
    trigger_schedule = create(:ci_trigger_schedule, :cron_nightly_build)
    trigger_schedule.trigger.ref = 'invalid-ref'
    trigger_schedule.valid?
    expect(trigger_schedule.errors[:ref].first).to include('does not exist')
  end

  describe 'cron limitation' do
    let(:trigger_schedule) { create(:ci_trigger_schedule, :cron_nightly_build) }

    before do
      trigger_schedule.cron = cron
      trigger_schedule.valid?
    end

    context 'when every hour' do
      let(:cron) { '0 * * * *' } # 00:00, 01:00, 02:00, ..., 23:00

      it 'fails' do
        expect(trigger_schedule.errors[:cron].first).to include('can not be less than 1 hour')
      end
    end

    context 'when each six hours' do
      let(:cron) { '0 */6 * * *' } # 00:00, 06:00, 12:00, 18:00

      it 'succeeds' do
        expect(trigger_schedule.errors[:cron]).to be_empty
      end
    end
  end

  describe '#schedule_next_run!' do
    context 'when more_than_1_hour_from_now' do
      let(:trigger_schedule) { create(:ci_trigger_schedule, :cron_nightly_build) }

      before do
        trigger_schedule.schedule_next_run!
      end

      it 'updates next_run_at' do
        next_time = Ci::CronParser.new(trigger_schedule.cron, trigger_schedule.cron_time_zone).next_time_from(Time.now)
        expect(Ci::TriggerSchedule.last.next_run_at).to eq(next_time)
      end
    end
  end

  describe '#real_next_run' do
    let(:trigger_schedule) { create(:ci_trigger_schedule, cron: user_cron, cron_time_zone: 'UTC') }

    subject { trigger_schedule.real_next_run(worker_cron: worker_cron, worker_time_zone: 'UTC') }

    context 'when next_run_at > worker_next_time' do
      let(:worker_cron) { '* * * * *' } # every minutes
      let(:user_cron) { '0 0 1 1 *' } # every 00:00, January 1st

      it 'returns next_run_at' do
        is_expected.to eq(trigger_schedule.next_run_at)
      end
    end

    context 'when worker_next_time > next_run_at' do
      let(:worker_cron) { '0 0 1 1 *' } # every 00:00, January 1st
      let(:user_cron) { '0 */6 * * *' } # each six hours

      it 'returns worker_next_time' do
        is_expected.to eq(Ci::CronParser.new(worker_cron, 'UTC').next_time_from(Time.now))
      end
    end
  end
end
