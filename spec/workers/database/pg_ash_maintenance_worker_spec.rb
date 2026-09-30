# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::PgAshMaintenanceWorker, feature_category: :database do
  let(:installer) { instance_double(Gitlab::Database::PgAsh::Installer, installed?: true) }
  let(:maintenance) { instance_double(Gitlab::Database::PgAsh::Maintenance, run: '3') }

  before do
    stub_application_setting(pg_ash_sampling_enabled: true)

    allow(Gitlab::Database::PgAsh::Installer).to receive(:new).and_return(installer)
    allow(Gitlab::Database::PgAsh::Maintenance).to receive(:new).and_return(maintenance)
  end

  it 'is scheduled only with tasks that the maintenance class accepts' do
    scheduled = YAML.safe_load_file(Gitlab::SidekiqConfig::CronJobs::SCHEDULE_PATH)
      .values.select { |job| job['class'] == described_class.name }

    expect(scheduled).to be_present
    expect(scheduled.map { |job| job['args'] })
      .to all(match([be_in(Gitlab::Database::PgAsh::Maintenance::TASKS)]))
  end

  describe '#perform' do
    subject(:worker) { described_class.new }

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { ['rollup_minute'] }
    end

    it 'runs the task and logs what pg_ash reported' do
      expect(worker).to receive(:log_extra_metadata_on_done).with(:result, '3')

      worker.perform('rollup_minute')

      expect(maintenance).to have_received(:run).with('rollup_minute')
    end

    context 'when sampling is disabled' do
      before do
        stub_application_setting(pg_ash_sampling_enabled: false)
      end

      it 'does nothing' do
        worker.perform('rotate')

        expect(Gitlab::Database::PgAsh::Maintenance).not_to have_received(:new)
      end
    end

    context 'when the database is read-only' do
      before do
        allow(Gitlab::Database).to receive(:read_only?).and_return(true)
      end

      it 'does nothing' do
        worker.perform('rotate')

        expect(Gitlab::Database::PgAsh::Maintenance).not_to have_received(:new)
      end
    end

    context 'when pg_ash is not installed' do
      let(:installer) { instance_double(Gitlab::Database::PgAsh::Installer, installed?: false) }

      it 'does nothing' do
        worker.perform('rotate')

        expect(Gitlab::Database::PgAsh::Maintenance).not_to have_received(:new)
      end
    end
  end
end
