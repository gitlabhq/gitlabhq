require 'rails_helper'

describe TriggersHelper do
  describe '#real_next_run' do
    let(:trigger_schedule) { create(:ci_trigger_schedule, cron: user_cron, cron_time_zone: 'UTC') }

    subject { helper.real_next_run(trigger_schedule, worker_cron: worker_cron, worker_time_zone: 'UTC') }

    context 'when next_run_at > worker_next_time' do
      let(:worker_cron) { '* * * * *' } # every minutes
      let(:user_cron) { '0 0 1 1 *' } # every 00:00, January 1st

      it 'returns next_run_at' do
        is_expected.to eq(trigger_schedule.next_run_at)
      end
    end

    context 'when worker_next_time > next_run_at' do
      let(:worker_cron) { '0 0 1 1 *' } # every 00:00, January 1st
      let(:user_cron) { '0 */6 * * *' } # each six hours

      it 'returns worker_next_time' do
        is_expected.to eq(Ci::CronParser.new(worker_cron, 'UTC').next_time_from(Time.now))
      end
    end
  end
end
