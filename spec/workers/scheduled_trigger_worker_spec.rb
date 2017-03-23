require 'spec_helper'

describe ScheduledTriggerWorker do
  let(:worker) { described_class.new }

  before do
    stub_ci_pipeline_to_return_yaml_file
  end

  context 'when there is a scheduled trigger within next_run_at' do
    before do
      create(:ci_scheduled_trigger, :cron_nightly_build, :force_triggable)
      worker.perform
    end

    it 'creates a new pipeline' do
      expect(Ci::Pipeline.last.status).to eq('pending')
    end

    it 'schedules next_run_at' do
      scheduled_trigger2 = create(:ci_scheduled_trigger, :cron_nightly_build)
      expect(Ci::ScheduledTrigger.last.next_run_at).to eq(scheduled_trigger2.next_run_at)
    end
  end

  context 'when there are no scheduled triggers within next_run_at' do
    let!(:scheduled_trigger) { create(:ci_scheduled_trigger, :cron_nightly_build) }

    before do
      worker.perform
    end

    it 'do not create a new pipeline' do
      expect(Ci::Pipeline.all).to be_empty
    end

    it 'do not reschedule next_run_at' do
      expect(Ci::ScheduledTrigger.last.next_run_at).to eq(scheduled_trigger.next_run_at)
    end
  end

  context 'when next_run_at is nil' do
    let!(:scheduled_trigger) { create(:ci_scheduled_trigger, :cron_nightly_build, next_run_at: nil) }

    before do
      worker.perform
    end

    it 'do not create a new pipeline' do
      expect(Ci::Pipeline.all).to be_empty
    end

    it 'do not reschedule next_run_at' do
      expect(Ci::ScheduledTrigger.last.next_run_at).to eq(scheduled_trigger.next_run_at)
    end
  end
end
