# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqConfig::CronJobInitializer, feature_category: :build do
  describe '.execute', :allow_unrouted_sidekiq_calls do
    subject(:execute) { described_class.execute }

    around do |example|
      Gitlab::SidekiqConfig::CronJobs.reset!
      example.run
      Gitlab::SidekiqConfig::CronJobs.reset!
    end

    before do
      allow(Gitlab::CurrentSettings).to receive(:uuid).and_return('d9e2f4e8-db1f-4e51-b03d-f427e1965c4a')
    end

    it 'loads the cron jobs into sidekiq-cron' do
      expect(Sidekiq::Cron::Job).to receive(:load_from_hash!).with(a_hash_including(
        'import_export_project_cleanup_worker' => {
          'cron' => '0 * * * *', 'class' => 'ImportExportProjectCleanupWorker'
        }
      ), source: 'schedule')

      execute
    end

    it 'computes service ping cron from instance UUID' do
      allow(Sidekiq::Cron::Job).to receive(:load_from_hash!)

      execute

      expect(Gitlab::SidekiqConfig.cron_jobs['gitlab_service_ping_worker']['cron']).to eq('44 10 * * 4')
    end

    it 'produces valid service ping cron when uuid is nil' do
      allow(Gitlab::CurrentSettings).to receive(:uuid).and_return(nil)
      allow(Sidekiq::Cron::Job).to receive(:load_from_hash!)

      execute

      expect(Gitlab::SidekiqConfig.cron_jobs['gitlab_service_ping_worker']['cron'])
        .to match(/\A\d+ \d+ \* \* \d\z/)
    end

    it 'does not override service ping cron configured in gitlab.yml' do
      allow(Gitlab.config).to receive(:cron_jobs).and_return(
        Gitlab::Configs.build_options('gitlab_service_ping_worker' => { 'cron' => '5 3 * * 1' })
      )
      allow(Sidekiq::Cron::Job).to receive(:load_from_hash!)

      execute

      expect(Gitlab::SidekiqConfig.cron_jobs['gitlab_service_ping_worker']['cron']).to eq('5 3 * * 1')
    end

    context 'when CronJobs#timezone_override is set' do
      before do
        allow_next_instance_of(Gitlab::SidekiqConfig::CronJobs) do |instance|
          allow(instance).to receive(:timezone_override).and_return('America/Chicago')
        end
      end

      it 'appends the timezone to the computed service ping cron' do
        allow(Sidekiq::Cron::Job).to receive(:load_from_hash!)

        execute

        expect(Gitlab::SidekiqConfig.cron_jobs['gitlab_service_ping_worker']['cron'])
          .to eq('44 10 * * 4 America/Chicago')
      end
    end

    context 'as integration tests', :allow_unrouted_sidekiq_calls do
      before do
        Sidekiq::Cron::Job.load_from_hash!({}, source: 'schedule')
        allow(Gitlab::CurrentSettings).to receive(:uuid).and_return('d9e2f4e8-db1f-4e51-b03d-f427e1965c4a')
      end

      after do
        Sidekiq::Cron::Job.load_from_hash!({}, source: 'schedule')
      end

      context 'with FOSS schedule' do
        it 'provisions FOSS cron jobs into the registry' do
          expect(Sidekiq::Cron::Job.find('pipeline_schedule_worker')).to be_nil

          described_class.execute

          job_names = Sidekiq::Cron::Job.all.map(&:name)
          expect(job_names).to include('pipeline_schedule_worker', 'stuck_ci_jobs_worker')
        end

        it 'sets a deterministic cron for gitlab_service_ping_worker' do
          described_class.execute

          expect(Sidekiq::Cron::Job.find('gitlab_service_ping_worker').cron).to eq('44 10 * * 4')
        end

        it 'removes jobs that are no longer in the schedule' do
          described_class.execute
          expect(Sidekiq::Cron::Job.find('pipeline_schedule_worker')).not_to be_nil

          allow(Gitlab::SidekiqConfig).to receive(:cron_jobs).and_return({})
          described_class.execute

          expect(Sidekiq::Cron::Job.find('pipeline_schedule_worker')).to be_nil
        end

        context 'when a cron override is configured in gitlab.yml' do
          before do
            cron_overrides = Gitlab::Configs.build_options(
              'pipeline_schedule_worker' => { 'cron' => '*/1 * * * *' }
            )
            allow(Gitlab.config).to receive(:cron_jobs).and_return(cron_overrides)
          end

          it 'applies the override to the live registry' do
            described_class.execute

            expect(Sidekiq::Cron::Job.find('pipeline_schedule_worker').cron).to eq('*/1 * * * *')
          end
        end
      end

      context 'with JH schedule' do
        before do
          stub_const(
            "#{Gitlab::SidekiqConfig::CronJobs}::JH_SCHEDULE_PATH",
            expand_fixture_path('gitlab/sidekiq_config/schedule_jh.yml')
          )
          allow(Gitlab).to receive(:jh?).and_return(true)
        end

        it 'merges JH overrides on top of the base schedule' do
          described_class.execute

          job = Sidekiq::Cron::Job.find('pipeline_schedule_worker')
          expect(job).not_to be_nil
          expect(job.status).to eq('disabled')
        end

        it 'preserves FOSS job class when JH only sets status' do
          described_class.execute

          expect(Sidekiq::Cron::Job.find('pipeline_schedule_worker').klass).to eq('PipelineScheduleWorker')
        end
      end
    end
  end
end
