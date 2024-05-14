# frozen_string_literal: true

require 'spec_helper'

# Only Sidekiq.redis interacts with cron jobs so unrouted calls are allowed.
RSpec.describe Sidekiq::Cron::Job, :allow_unrouted_sidekiq_calls do
  describe 'cron jobs' do
    context 'when Fugit depends on ZoTime or EoTime' do
      before do
        described_class.create( # rubocop:disable Rails/SaveBang
          name: 'TestCronWorker',
          cron: Settings.cron_jobs[:pipeline_schedule_worker]['cron'],
          class: Settings.cron_jobs[:pipeline_schedule_worker]['job_class']
        )
      end

      it 'does not get any errors' do
        expect { described_class.all.first.should_enque?(Time.now) }.not_to raise_error
      end
    end
  end
end
