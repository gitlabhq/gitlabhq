require 'spec_helper'

describe TriggerScheduleWorker do
  let(:worker) { described_class.new }

  before do
    stub_ci_pipeline_to_return_yaml_file
  end

  context 'when there is a scheduled trigger within next_run_at' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:trigger) { create(:ci_trigger, owner: user, project: project, ref: 'master') }
    let!(:trigger_schedule) { create(:ci_trigger_schedule, :cron_nightly_build, :force_triggable, trigger: trigger, project: project) }

    before do
      worker.perform
    end

    it 'creates a new trigger request' do
      expect(Ci::TriggerRequest.first.trigger_id).to eq(trigger.id)
    end

    it 'creates a new pipeline' do
      expect(Ci::Pipeline.last.status).to eq('pending')
    end

    it 'schedules next_run_at' do
      next_time = Ci::CronParser.new('0 1 * * *', 'Europe/Istanbul').next_time_from_now
      expect(Ci::TriggerSchedule.last.next_run_at).to eq(next_time)
    end
  end

  context 'when there are no scheduled triggers within next_run_at' do
    let!(:trigger_schedule) { create(:ci_trigger_schedule, :cron_nightly_build) }

    before do
      worker.perform
    end

    it 'do not create a new pipeline' do
      expect(Ci::Pipeline.all).to be_empty
    end

    it 'do not reschedule next_run_at' do
      expect(Ci::TriggerSchedule.last.next_run_at).to eq(trigger_schedule.next_run_at)
    end
  end

  context 'when next_run_at is nil' do
    let!(:trigger_schedule) { create(:ci_trigger_schedule, :cron_nightly_build, next_run_at: nil) }

    before do
      worker.perform
    end

    it 'do not create a new pipeline' do
      expect(Ci::Pipeline.all).to be_empty
    end

    it 'do not reschedule next_run_at' do
      expect(Ci::TriggerSchedule.last.next_run_at).to eq(trigger_schedule.next_run_at)
    end
  end
end
