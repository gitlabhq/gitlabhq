require 'spec_helper'

describe TriggerScheduleWorker do
  let(:worker) { described_class.new }

  before do
    stub_ci_pipeline_to_return_yaml_file
  end

  context 'when there is a scheduled trigger within next_run_at' do
    let!(:trigger_schedule) { create(:ci_trigger_schedule, :nightly, :force_triggable) }

    before do
      worker.perform
    end

    it 'creates a new trigger request' do
      expect(trigger_schedule.trigger.id).to eq(Ci::TriggerRequest.first.trigger_id)
    end

    it 'creates a new pipeline' do
      expect(Ci::Pipeline.last.status).to eq('pending')
    end

    it 'updates next_run_at' do
      next_time = Gitlab::Ci::CronParser.new(trigger_schedule.cron, trigger_schedule.cron_timezone).next_time_from(Time.now)
      expect(Ci::TriggerSchedule.last.next_run_at).to eq(next_time)
    end
  end

  context 'when there are no scheduled triggers within next_run_at' do
    let!(:trigger_schedule) { create(:ci_trigger_schedule, :nightly) }

    before do
      worker.perform
    end

    it 'do not create a new pipeline' do
      expect(Ci::Pipeline.count).to eq(0)
    end

    it 'do not reschedule next_run_at' do
      expect(Ci::TriggerSchedule.last.next_run_at).to eq(trigger_schedule.next_run_at)
    end
  end
end
