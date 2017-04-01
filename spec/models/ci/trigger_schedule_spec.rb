require 'spec_helper'

describe Ci::TriggerSchedule, models: true do
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:trigger) }
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

    context 'when cron frequency is too short' do
      let(:cron) { '0 * * * *' } # 00:00, 01:00, 02:00, ..., 23:00

      it 'gets an error' do
        expect(trigger_schedule.errors[:cron].first).to include('can not be less than 1 hour')
      end
    end

    context 'when cron frequency is eligible' do
      let(:cron) { '0 0 1 1 *' } # every 00:00, January 1st

      it 'gets no errors' do
        expect(trigger_schedule.errors[:cron]).to be_empty
      end
    end
  end

  describe '#schedule_next_run!' do
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
