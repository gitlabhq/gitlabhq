require 'spec_helper'

describe Ci::TriggerSchedule, models: true do
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:trigger) }
  it { is_expected.to respond_to :ref }

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
