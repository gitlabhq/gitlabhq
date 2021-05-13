# frozen_string_literal: true

RSpec.shared_examples 'handles set_next_run_at' do
  context 'when schedule runs every minute' do
    it "updates next_run_at to the worker's execution time" do
      travel_to(1.day.ago) do
        expect(schedule.next_run_at).to eq(cron_worker_next_run_at)
      end
    end
  end

  context 'when there are two different schedules in the same time zones' do
    it 'sets the sames next_run_at' do
      expect(schedule_1.next_run_at).to eq(schedule_2.next_run_at)
    end
  end

  context 'when cron is updated for existing schedules' do
    it 'updates next_run_at automatically' do
      expect { schedule.update!(cron: new_cron) }.to change { schedule.next_run_at }
    end
  end
end
