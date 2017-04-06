require 'spec_helper'

describe TriggerScheduleWorker do
  let(:worker) { described_class.new }

  before do
    stub_ci_pipeline_to_return_yaml_file
  end

  context 'when there is a scheduled trigger within next_run_at' do
    before do
      trigger_schedule = create(:ci_trigger_schedule, :nightly)
      time_future = Time.now + 10.days
      allow(Time).to receive(:now).and_return(time_future)
      @next_time = Gitlab::Ci::CronParser.new(trigger_schedule.cron, trigger_schedule.cron_timezone).next_time_from(time_future)
    end

    it 'creates a new trigger request' do
      expect { worker.perform }.to change { Ci::TriggerRequest.count }.by(1)
    end

    it 'creates a new pipeline' do
      expect { worker.perform }.to change { Ci::Pipeline.count }.by(1)
      expect(Ci::Pipeline.last).to be_pending
    end

    it 'updates next_run_at' do
      expect { worker.perform }.to change { Ci::TriggerSchedule.last.next_run_at }.to(@next_time)
    end
  end

  context 'when there are no scheduled triggers within next_run_at' do
    before { create(:ci_trigger_schedule, :nightly) }

    it 'does not create a new pipeline' do
      expect { worker.perform }.not_to change { Ci::Pipeline.count }
    end

    it 'does not update next_run_at' do
      expect { worker.perform }.not_to change { Ci::TriggerSchedule.last.next_run_at }
    end
  end

  context 'when next_run_at is nil' do
    before do
      trigger_schedule = create(:ci_trigger_schedule, :nightly)
      trigger_schedule.update_attribute(:next_run_at, nil)
    end

    it 'does not create a new pipeline' do
      expect { worker.perform }.not_to change { Ci::Pipeline.count }
    end

    it 'does not update next_run_at' do
      expect { worker.perform }.not_to change { Ci::TriggerSchedule.last.next_run_at }
    end
  end
end
