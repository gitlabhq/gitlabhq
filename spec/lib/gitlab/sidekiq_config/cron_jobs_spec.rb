# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqConfig::CronJobs, feature_category: :build do
  describe '.config' do
    subject(:loader) { described_class.new }

    around do |example|
      described_class.reset!
      example.run
      described_class.reset!
    end

    context 'with FOSS schedule only' do
      before do
        allow(Gitlab).to receive_messages(ee?: false, com?: false, jh?: false)
      end

      it 'returns FOSS cron jobs' do
        expect(loader.load).to include('pipeline_schedule_worker', 'stuck_ci_jobs_worker')
      end

      it 'does not include EE-only jobs' do
        expect(loader.load).not_to include('geo_registry_sync_worker')
      end
    end

    context 'with EE schedule', if: Gitlab.ee? do
      before do
        allow(Gitlab).to receive_messages(com?: false, jh?: false)
      end

      it 'merges EE jobs alongside FOSS jobs' do
        result = loader.load

        expect(result).to include('pipeline_schedule_worker')
        expect(result).to include('active_user_count_threshold_worker')
      end

      it 'does not include SaaS-only jobs' do
        expect(loader.load).not_to include('block_pipl_users_worker')
      end
    end

    context 'when on GitLab.com (SaaS)', if: Gitlab.ee? do
      before do
        allow(Gitlab).to receive_messages(com?: true, jh?: false)
      end

      it 'includes SaaS-only jobs' do
        expect(loader.load).to include('block_pipl_users_worker')
      end

      context 'when not on SaaS' do
        before do
          allow(Gitlab).to receive(:com?).and_return(false) # -- test-only stub
        end

        it 'does not include SaaS-only jobs' do
          expect(loader.load).not_to include('block_pipl_users_worker')
        end
      end
    end

    context 'when on JH' do
      let(:jh_schedule) { { 'pipeline_schedule_worker' => { 'status' => 'disabled' } } }

      before do
        allow(Gitlab).to receive_messages(ee?: false, com?: false, jh?: true)
        allow(loader).to receive(:load_schedule_file).and_call_original
        allow(loader).to receive(:load_schedule_file)
          .with(described_class::JH_SCHEDULE_PATH).and_return(jh_schedule)
      end

      it 'applies JH overrides on top of existing jobs' do
        result = loader.load

        expect(result['pipeline_schedule_worker']['status']).to eq('disabled')
        expect(result['pipeline_schedule_worker']['class']).to eq('PipelineScheduleWorker')
      end
    end

    context 'when schedule file is missing' do
      before do
        allow(loader).to receive(:schedule_paths).and_return(['/nonexistent/path/schedule.yml'])
      end

      it 'returns an empty hash' do
        expect(loader.load).to eq({})
      end
    end

    context 'when cron is overridden in config' do
      before do
        allow(Gitlab).to receive_messages(ee?: false, com?: false, jh?: false)
        allow(Gitlab.config).to receive(:cron_jobs).and_return(
          GitlabSettings::Options.build('pipeline_schedule_worker' => { 'cron' => '*/5 * * * *' })
        )
      end

      it 'applies the override' do
        expect(loader.load['pipeline_schedule_worker']['cron']).to eq('*/5 * * * *')
      end

      it 'logs a warning' do
        expect(Gitlab::AppLogger).to receive(:warn).with(
          a_string_including("pipeline_schedule_worker.cron").and(including("overridden by instance configuration"))
        )

        loader.load
      end
    end

    context 'when args are overridden in config' do
      before do
        allow(Gitlab).to receive_messages(ee?: false, com?: false, jh?: false)
        allow(Gitlab.config).to receive(:cron_jobs).and_return(
          GitlabSettings::Options.build(
            'cells_schedule_claims_verification_worker' => {
              'args' => { 'worker_class' => 'Cells::ScheduleClaimsVerificationWorker',
                          'within_minutes' => 30, 'within_hours' => 12 }
            }
          )
        )
      end

      it 'applies the args override' do
        args = loader.load['cells_schedule_claims_verification_worker']['args']
        expect(args['within_minutes']).to eq(30)
        expect(args['within_hours']).to eq(12)
      end

      it 'does not change cron' do
        expect(loader.load['cells_schedule_claims_verification_worker']['cron']).to eq('0 0 * * 6')
      end
    end

    context 'when class or status are overridden in config' do
      before do
        allow(Gitlab).to receive_messages(ee?: false, com?: false, jh?: false)
        allow(Gitlab.config).to receive(:cron_jobs).and_return(
          GitlabSettings::Options.build('pipeline_schedule_worker' => {
            'class' => 'SomeOtherWorker', 'status' => 'disabled'
          })
        )
      end

      it 'ignores class and status overrides' do
        job = loader.load['pipeline_schedule_worker']
        expect(job['class']).to eq('PipelineScheduleWorker')
        expect(job['status']).to be_nil
      end
    end

    context 'when override matches the default' do
      before do
        allow(Gitlab).to receive_messages(ee?: false, com?: false, jh?: false)
        allow(Gitlab.config).to receive(:cron_jobs).and_return(
          GitlabSettings::Options.build('pipeline_schedule_worker' => { 'cron' => '3-59/10 * * * *' })
        )
      end

      it 'does not log a warning' do
        expect(Gitlab::AppLogger).not_to receive(:warn)

        loader.load
      end
    end

    context 'with service ping worker in schedule' do
      before do
        allow(Gitlab).to receive_messages(ee?: false, com?: false, jh?: false)
      end

      it 'leaves cron nil — dynamic schedule applied at Sidekiq init time' do
        expect(loader.load['gitlab_service_ping_worker']['cron']).to be_nil
      end
    end
  end
end
