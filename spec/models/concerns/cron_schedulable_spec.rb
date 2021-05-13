# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CronSchedulable do
  let(:ideal_next_run_at) { schedule.send(:ideal_next_run_from, Time.zone.now) }
  let(:cron_worker_next_run_at) { schedule.send(:cron_worker_next_run_from, Time.zone.now) }

  context 'for ci_pipeline_schedule' do
    let(:schedule) { create(:ci_pipeline_schedule, :every_minute) }
    let(:schedule_1) { create(:ci_pipeline_schedule, :weekly, cron_timezone: 'UTC') }
    let(:schedule_2) { create(:ci_pipeline_schedule, :weekly, cron_timezone: 'UTC') }
    let(:new_cron) { '0 0 1 1 *' }

    it_behaves_like 'handles set_next_run_at'
  end
end
