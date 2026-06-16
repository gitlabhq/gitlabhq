# frozen_string_literal: true

require 'spec_helper'

# Only Sidekiq.redis interacts with cron jobs so unrouted calls are allowed.
RSpec.describe Sidekiq::Cron::Job, :allow_unrouted_sidekiq_calls, feature_category: :sidekiq do
  describe 'cron jobs' do
    context 'when Fugit depends on ZoTime or EoTime' do
      before do
        job = Gitlab::SidekiqConfig.cron_jobs['pipeline_schedule_worker']

        described_class.create( # rubocop:disable Rails/SaveBang
          name: 'TestCronWorker',
          cron: job['cron'],
          class: job['class']
        )
      end

      it 'does not get any errors' do
        expect { described_class.all.first.should_enqueue?(Time.now) }.not_to raise_error
      end
    end
  end
end
