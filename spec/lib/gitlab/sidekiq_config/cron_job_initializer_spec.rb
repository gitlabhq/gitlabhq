# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqConfig::CronJobInitializer, feature_category: :build do
  describe '#execute' do
    subject(:execute) { described_class.execute }

    let(:cron_for_service_ping) { '4 7 * * 4' }

    let(:cron_jobs_settings) do
      {
        'gitlab_service_ping_worker' => {
          'cron' => nil,
          'job_class' => 'GitlabServicePingWorker'
        },
        'import_export_project_cleanup_worker' => {
          'cron' => '0 * * * *',
          'job_class' => 'ImportExportProjectCleanupWorker'
        },
        "invalid_worker" => {
          'cron' => '0 * * * *'
        }
      }
    end

    let(:cron_jobs_hash) do
      {
        'gitlab_service_ping_worker' => {
          'cron' => cron_for_service_ping,
          'class' => 'GitlabServicePingWorker'
        },
        'import_export_project_cleanup_worker' => {
          'cron' => '0 * * * *',
          'class' => 'ImportExportProjectCleanupWorker'
        }
      }
    end

    around do |example|
      Gitlab::SidekiqConfig.clear_memoization(:cron_jobs)
      original_settings = Gitlab.config['cron_jobs']
      Gitlab.config['cron_jobs'] = cron_jobs_settings

      Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
        example.run
      end

      Gitlab::SidekiqConfig.clear_memoization(:cron_jobs)
      Gitlab.config['cron_jobs'] = original_settings
    end

    it 'loads the cron jobs into sidekiq-cron' do
      expect(Sidekiq::Cron::Job).to receive(:load_from_hash!).with(cron_jobs_hash, source: 'schedule')

      execute
    end

    context 'when EE files are available', if: Gitlab.ee? do
      it 'configures mirror and geo cron jobs' do
        expect(Gitlab::Mirror).to receive(:configure_cron_job!)
        expect(Gitlab::Geo).to receive(:configure_cron_jobs!)

        execute
      end

      context 'for FOSS' do
        before do
          allow(GitlabEdition).to receive(:ee?).and_return(false)
        end

        it 'does not configure mirror and geo cron jobs' do
          expect(Gitlab::Mirror).not_to receive(:configure_cron_job!)
          expect(Gitlab::Geo).not_to receive(:configure_cron_jobs!)

          execute
        end
      end
    end
  end
end
