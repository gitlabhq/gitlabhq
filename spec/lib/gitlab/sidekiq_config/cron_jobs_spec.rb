# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqConfig::CronJobs, feature_category: :build do
  around do |example|
    described_class.reset!
    example.run
    described_class.reset!
  end

  subject(:cron) { described_class.config }

  describe '#jobs' do
    context 'with FOSS schedule only' do
      before do
        allow(Gitlab).to receive_messages(ee?: false, com?: false, jh?: false)
      end

      it 'returns FOSS cron jobs' do
        expect(cron.jobs).to include('pipeline_schedule_worker', 'stuck_ci_jobs_worker')
      end

      it 'does not include EE-only jobs' do
        expect(cron.jobs).not_to include('geo_registry_sync_worker')
      end
    end

    context 'with immutable result' do
      before do
        allow(Gitlab).to receive_messages(ee?: false, com?: false, jh?: false)
      end

      it 'returns a frozen hash' do
        expect(cron.jobs).to be_frozen
      end

      it 'returns frozen inner job hashes' do
        expect(cron.jobs['pipeline_schedule_worker']).to be_frozen
      end

      it 'raises FrozenError on direct mutation of the outer hash' do
        expect { cron.jobs['new_key'] = {} }.to raise_error(FrozenError)
      end

      it 'raises FrozenError on direct mutation of an inner job hash' do
        expect { cron.jobs['pipeline_schedule_worker']['cron'] = '0 0 * * *' }.to raise_error(FrozenError)
      end
    end

    context 'with EE schedule', if: Gitlab.ee? do
      before do
        allow(Gitlab).to receive_messages(com?: false, jh?: false)
      end

      it 'merges EE jobs alongside FOSS jobs', :aggregate_failures do
        expect(cron.jobs).to include('pipeline_schedule_worker')
        expect(cron.jobs).to include('geo_registry_sync_worker')
      end

      it 'does not include SaaS-only jobs' do
        expect(cron.jobs).not_to include('block_pipl_users_worker')
      end
    end

    context 'when on GitLab.com (SaaS)', if: Gitlab.ee? do
      before do
        allow(Gitlab).to receive_messages(com?: true, jh?: false)
      end

      it 'includes SaaS-only jobs' do
        expect(cron.jobs).to include('block_pipl_users_worker')
      end

      context 'when not on SaaS' do
        before do
          allow(Gitlab).to receive(:com?).and_return(false) # -- test-only stub
        end

        it 'does not include SaaS-only jobs' do
          expect(cron.jobs).not_to include('block_pipl_users_worker')
        end
      end
    end

    context 'when on JH' do
      before do
        allow(Gitlab).to receive_messages(ee?: false, com?: false, jh?: true)
        stub_const("#{described_class}::JH_SCHEDULE_PATH", expand_fixture_path('gitlab/sidekiq_config/schedule_jh.yml'))
      end

      it 'applies JH overrides on top of existing jobs', :aggregate_failures do
        expect(cron.jobs['pipeline_schedule_worker']['status']).to eq('disabled')
        expect(cron.jobs['pipeline_schedule_worker']['class']).to eq('PipelineScheduleWorker')
      end
    end

    context 'when schedule file is missing' do
      before do
        allow(Gitlab).to receive_messages(ee?: false, com?: false, jh?: false)
        stub_const("#{described_class}::SCHEDULE_PATH", '/nonexistent/path/schedule.yml')
      end

      it 'returns an empty hash' do
        expect(cron.jobs).to eq({})
      end
    end

    context 'when cron is overridden in config' do
      before do
        allow(Gitlab).to receive_messages(ee?: false, com?: false, jh?: false)
        allow(Gitlab.config).to receive(:cron_jobs).and_return(
          Gitlab::Configs.build_options('pipeline_schedule_worker' => { 'cron' => '*/5 * * * *' })
        )
      end

      it 'applies the override' do
        expect(cron.jobs['pipeline_schedule_worker']['cron']).to eq('*/5 * * * *')
      end

      it 'logs a warning' do
        expect(Gitlab::AppLogger).to receive(:warn).with(
          a_string_including("pipeline_schedule_worker.cron").and(including("overridden by instance configuration"))
        )

        cron.jobs
      end
    end

    context 'when args are overridden in config' do
      before do
        allow(Gitlab).to receive_messages(ee?: false, com?: false, jh?: false)
        allow(Gitlab.config).to receive(:cron_jobs).and_return(
          Gitlab::Configs.build_options(
            'cells_schedule_claims_verification_worker' => {
              'args' => { 'worker_class' => 'Cells::ScheduleClaimsVerificationWorker',
                          'within_minutes' => 30, 'within_hours' => 12 }
            }
          )
        )
      end

      it 'applies the args override', :aggregate_failures do
        args = cron.jobs['cells_schedule_claims_verification_worker']['args']
        expect(args['within_minutes']).to eq(30)
        expect(args['within_hours']).to eq(12)
      end

      it 'does not change cron' do
        expect(cron.jobs['cells_schedule_claims_verification_worker']['cron']).to eq('0 0 * * 6')
      end
    end

    context 'when class or status are overridden in config' do
      before do
        allow(Gitlab).to receive_messages(ee?: false, com?: false, jh?: false)
        allow(Gitlab.config).to receive(:cron_jobs).and_return(
          Gitlab::Configs.build_options('pipeline_schedule_worker' => {
            'class' => 'SomeOtherWorker', 'status' => 'disabled'
          })
        )
      end

      it 'ignores class and status overrides', :aggregate_failures do
        job = cron.jobs['pipeline_schedule_worker']
        expect(job['class']).to eq('PipelineScheduleWorker')
        expect(job['status']).to be_nil
      end
    end

    context 'when override matches the default' do
      before do
        allow(Gitlab).to receive_messages(ee?: false, com?: false, jh?: false)
        allow(Gitlab.config).to receive(:cron_jobs).and_return(
          Gitlab::Configs.build_options('pipeline_schedule_worker' => { 'cron' => '3-59/10 * * * *' })
        )
      end

      it 'does not log a warning' do
        expect(Gitlab::AppLogger).not_to receive(:warn)

        cron.jobs
      end
    end

    context 'with service ping worker in schedule' do
      before do
        allow(Gitlab).to receive_messages(ee?: false, com?: false, jh?: false)
      end

      it 'leaves cron nil — dynamic schedule applied at Sidekiq init time' do
        expect(cron.jobs['gitlab_service_ping_worker']['cron']).to be_nil
      end
    end

    context 'with timezone_override' do
      before do
        allow(Gitlab).to receive_messages(ee?: false, com?: false, jh?: false)
        stub_const("#{described_class}::SCHEDULE_PATH",
          expand_fixture_path('gitlab/sidekiq_config/schedule_test.yml'))
        allow(Gitlab.config).to receive(:cron_jobs).and_return(Gitlab::Configs.build_options({}))
      end

      context 'when timezone_override is nil' do
        it 'leaves cron strings unchanged' do
          expect(cron.jobs['test_cron_worker']['cron']).to eq('0 6 * * *')
        end
      end

      context 'when timezone_override returns a value' do
        before do
          allow_next_instance_of(described_class) do |instance|
            allow(instance).to receive(:timezone_override).and_return('UTC')
          end
        end

        it 'appends the timezone to cron strings' do
          expect(cron.jobs['test_cron_worker']['cron']).to eq('0 6 * * * UTC')
        end

        it 'leaves nil cron untouched (service ping is populated later)' do
          expect(cron.jobs['gitlab_service_ping_worker']['cron']).to be_nil
        end

        it 'does not double-append when cron already carries a timezone token' do
          stub_const("#{described_class}::SCHEDULE_PATH",
            expand_fixture_path('gitlab/sidekiq_config/schedule_already_tz.yml'))

          expect(cron.jobs['already_tz_worker']['cron']).to eq('0 0 * * * Europe/Berlin')
        end
      end

      context 'when timezone_override is an invalid IANA identifier' do
        before do
          allow_next_instance_of(described_class) do |instance|
            allow(instance).to receive(:timezone_override).and_return('Not/ATimezone')
          end
        end

        it 'leaves cron strings unchanged' do
          expect(cron.jobs['test_cron_worker']['cron']).to eq('0 6 * * *')
        end

        it 'logs a warning' do
          expect(Gitlab::AppLogger).to receive(:warn).with(
            a_string_including("invalid timezone_override", "Not/ATimezone")
          )

          cron.jobs
        end
      end

      context 'when timezone_override is blank' do
        before do
          allow_next_instance_of(described_class) do |instance|
            allow(instance).to receive(:timezone_override).and_return('')
          end
        end

        it 'leaves cron strings unchanged' do
          expect(cron.jobs['test_cron_worker']['cron']).to eq('0 6 * * *')
        end
      end

      context 'when both a user cron override and timezone_override are set' do
        before do
          allow_next_instance_of(described_class) do |instance|
            allow(instance).to receive(:timezone_override).and_return('UTC')
          end
          allow(Gitlab.config).to receive(:cron_jobs).and_return(
            Gitlab::Configs.build_options('test_cron_worker' => { 'cron' => '*/5 * * * *' })
          )
        end

        it 'appends timezone to the user-overridden cron' do
          expect(cron.jobs['test_cron_worker']['cron']).to eq('*/5 * * * * UTC')
        end
      end
    end
  end

  describe '#timezone_override' do
    let(:timezone_override) { cron.timezone_override }

    it 'returns nil by default' do
      expect(timezone_override).to be_nil
    end

    it 'returns the value from application settings' do
      stub_application_setting(sidekiq_timezone_override: 'America/Chicago')

      expect(timezone_override).to eq('America/Chicago')
    end
  end

  describe '#set_job' do
    before do
      allow(Gitlab).to receive_messages(ee?: false, com?: false, jh?: false)
      allow(Gitlab.config).to receive(:cron_jobs).and_return(Gitlab::Configs.build_options({}))
    end

    it 'makes a purely dynamic job available in jobs' do
      cron.set_job('my_dynamic_worker', { 'cron' => '0 1 * * *', 'class' => 'MyDynamicWorker' })

      expect(cron.jobs['my_dynamic_worker']).to include('cron' => '0 1 * * *', 'class' => 'MyDynamicWorker')
    end

    it 'merges into an existing static job without replacing other fields', :aggregate_failures do
      cron.set_job('pipeline_schedule_worker', { 'cron' => '0 2 * * *' })

      job = cron.jobs['pipeline_schedule_worker']

      expect(job['cron']).to eq('0 2 * * *')
      expect(job['class']).to eq('PipelineScheduleWorker')
    end

    it 'expires the jobs cache so the new job is reflected on the next call' do
      original_jobs = cron.jobs
      expect(original_jobs).not_to have_key('late_arrival_worker')

      cron.set_job('late_arrival_worker', { 'cron' => '0 3 * * *' })

      expect(cron.jobs).to have_key('late_arrival_worker')
    end

    context 'when timezone_override is set' do
      before do
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:timezone_override).and_return('America/Chicago')
        end
      end

      it 'applies timezone override to the dynamic job cron' do
        cron.set_job('my_dynamic_worker', { 'cron' => '0 4 * * *', 'class' => 'MyDynamicWorker' })

        expect(cron.jobs['my_dynamic_worker']['cron']).to eq('0 4 * * * America/Chicago')
      end
    end
  end
end
