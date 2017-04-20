require 'spec_helper'

describe TriggerScheduleWorker do
  let(:worker) { described_class.new }

  before do
    stub_ci_pipeline_to_return_yaml_file
  end

  context 'when there is a scheduled trigger within next_run_at' do
    let(:next_run_at) { 2.days.ago }

    let!(:trigger_schedule) do
      create(:ci_trigger_schedule, :nightly)
    end

    before do
      trigger_schedule.update_column(:next_run_at, next_run_at)
    end

    it 'creates a new trigger request' do
      expect { worker.perform }.to change { Ci::TriggerRequest.count }
    end

    it 'creates a new pipeline' do
      expect { worker.perform }.to change { Ci::Pipeline.count }
      expect(Ci::Pipeline.last).to be_pending
    end

    it 'updates next_run_at' do
      worker.perform

      expect(trigger_schedule.reload.next_run_at).not_to eq(next_run_at)
    end

    context 'inactive schedule' do
      before do
        trigger_schedule.update(active: false)
      end

      it 'does not create a new trigger' do
        expect { worker.perform }.not_to change { Ci::TriggerRequest.count }
      end
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
      schedule = create(:ci_trigger_schedule, :nightly)
      schedule.update_column(:next_run_at, nil)
    end

    it 'does not create a new pipeline' do
      expect { worker.perform }.not_to change { Ci::Pipeline.count }
    end

    it 'does not update next_run_at' do
      expect { worker.perform }.not_to change { Ci::TriggerSchedule.last.next_run_at }
    end
  end
end
