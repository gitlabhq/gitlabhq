require 'spec_helper'

describe Ci::TriggerSchedulePresenter do
  let(:trigger_schedule) { create(:ci_trigger_schedule) }

  subject(:presenter) do
    described_class.new(trigger_schedule)
  end

  it 'inherits from Gitlab::View::Presenter::Delegated' do
    expect(described_class.superclass).to eq(Gitlab::View::Presenter::Delegated)
  end

  describe '#initialize' do
    it 'takes a trigger_schedule and optional params' do
      expect { presenter }.not_to raise_error
    end

    it 'exposes trigger_schedule' do
      expect(presenter.trigger_schedule).to eq(trigger_schedule)
    end

    it 'forwards missing methods to trigger_schedule' do
      expect(presenter.ref).to eq('master')
    end
  end

  describe '#real_next_run' do
    let(:trigger_schedule) { create(:ci_trigger_schedule, cron: user_cron, cron_time_zone: 'UTC') }

    subject { described_class.new(trigger_schedule).real_next_run(arguments) }

    context 'when next_run_at > worker_next_time' do
      let(:arguments) { { worker_cron: '0 0 1 1 *', worker_time_zone: 'UTC' } } # every 00:00, January 1st
      let(:user_cron) { '1 0 1 1 *' } # every 00:01, January 1st

      it 'returns nearest worker_next_time from next_run_at' do
        is_expected.to eq(Gitlab::Ci::CronParser.new(arguments[:worker_cron], arguments[:worker_time_zone])
                                                .next_time_from(trigger_schedule.next_run_at))
      end
    end

    context 'when worker_next_time > next_run_at' do
      let(:arguments) { { worker_cron: '1 0 1 1 *', worker_time_zone: 'UTC' } } # every 00:01, January 1st
      let(:user_cron) { '0 0 1 1 *' } # every 00:00, January 1st

      it 'returns nearest worker_next_time from next_run_at' do
        is_expected.to eq(Gitlab::Ci::CronParser.new(arguments[:worker_cron], arguments[:worker_time_zone])
                                                .next_time_from(trigger_schedule.next_run_at))
      end
    end

    context 'when worker_cron and worker_time_zone are ommited' do
      let(:arguments) { {} }
      let(:user_cron) { '* * * * *' } # every minutes

      it 'returns nearest worker_next_time from next_run_at by server configuration' do
        is_expected.to eq(Gitlab::Ci::CronParser.new(Settings.cron_jobs['trigger_schedule_worker']['cron'],
                                                     Time.zone.name)
                                                .next_time_from(trigger_schedule.next_run_at))
      end
    end
  end
end
