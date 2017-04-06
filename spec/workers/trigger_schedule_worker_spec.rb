require 'spec_helper'

describe TriggerScheduleWorker do
  let(:worker) { described_class.new }

  before do
    stub_ci_pipeline_to_return_yaml_file
  end

  context 'when there is a scheduled trigger within next_run_at' do
    let!(:trigger_schedule) { create(:ci_trigger_schedule, :nightly) }
    let(:next_time) { Gitlab::Ci::CronParser.new(trigger_schedule.cron, trigger_schedule.cron_timezone).next_time_from(@time_future) }

    before do
      @time_future = Time.now + 10.days
      allow(Time).to receive(:now).and_return(@time_future)
      worker.perform
    end

    it 'creates a new trigger request' do
      expect(trigger_schedule.trigger.id).to eq(Ci::TriggerRequest.first.trigger_id)
    end

    it 'creates a new pipeline' do
      expect(Ci::Pipeline.last).to be_pending
    end

    it 'updates next_run_at' do
      expect(Ci::TriggerSchedule.last.next_run_at).to eq(next_time)
    end
  end

  context 'when there are no scheduled triggers within next_run_at' do
    let!(:trigger_schedule) { create(:ci_trigger_schedule, :nightly) }

    before do
      worker.perform
    end

    it 'does not create a new pipeline' do
      expect(Ci::Pipeline.count).to eq(0)
    end

    it 'does not update next_run_at' do
      expect(trigger_schedule.next_run_at).to eq(Ci::TriggerSchedule.last.next_run_at)
    end
  end

  context 'when next_run_at is nil' do
    let!(:trigger_schedule) { create(:ci_trigger_schedule, :nightly) }

    before do
      trigger_schedule.update_attribute(:next_run_at, nil)
      worker.perform
    end

    it 'does not create a new pipeline' do
      expect(Ci::Pipeline.count).to eq(0)
    end

    it 'does not update next_run_at' do
      expect(trigger_schedule.next_run_at).to eq(Ci::TriggerSchedule.last.next_run_at)
    end
  end
end
