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

  describe '#schedule_next_run!' do
    let(:trigger_schedule) { create(:ci_trigger_schedule, :cron_nightly_build, next_run_at: nil) }

    before do
      trigger_schedule.schedule_next_run!
    end

    it 'updates next_run_at' do
      next_time = Ci::CronParser.new(trigger_schedule.cron, trigger_schedule.cron_time_zone).next_time_from(Time.now)
      expect(Ci::TriggerSchedule.last.next_run_at).to eq(next_time)
    end
  end
end
