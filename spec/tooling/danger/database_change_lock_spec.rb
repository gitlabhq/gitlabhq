# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'
require_relative '../../../tooling/danger/database_change_lock'

RSpec.describe Tooling::Danger::DatabaseChangeLock, feature_category: :database do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:fake_ddl_rule) { instance_double(Tooling::Danger::DatabaseUpgradeDdlLock, check_lock: nil) }
  let(:fake_pdm_rule) { instance_double(Tooling::Danger::PostDeploymentMigrationLock, check_lock: nil) }

  subject(:database_change_lock) { fake_danger.new(helper: fake_helper) }

  describe '#check_database_lock_contention', time_travel_to: '2025-11-01 09:00:00 UTC' do
    subject(:check_database_lock_contention) { database_change_lock.check_database_lock_contention }

    let(:active_ddl_lock) do
      {
        'start_date' => "2025-11-03T09:00:00Z",
        'end_date' => "2025-11-05T09:00:00Z",
        'details' => "Postgres 17 upgrade",
        'change_request_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3",
        'warning_days' => 7,
        'merge_buffer' => 2,
        'block_level' => 'only_ddl'
      }
    end

    let(:active_pcl_lock) do
      {
        'start_date' => "2025-11-03T09:00:00Z",
        'end_date' => "2025-11-05T09:00:00Z",
        'details' => "Soft PCL",
        'change_request_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/work_items/29078",
        'warning_days' => 7,
        'merge_buffer' => 2,
        'block_level' => 'only_pdm'
      }
    end

    let(:file_exists) { true }
    let(:config) { {} }

    before do
      allow(File).to receive(:exist?).and_return(file_exists)
      allow(YAML).to receive(:safe_load_file).and_return(config)
      allow(Tooling::Danger::DatabaseUpgradeDdlLock).to receive(:new).and_return(fake_ddl_rule)
      allow(Tooling::Danger::PostDeploymentMigrationLock).to receive(:new).and_return(fake_pdm_rule)
    end

    context 'when there is no config file' do
      let(:file_exists) { false }

      it 'does not invoke any rule' do
        expect(fake_ddl_rule).not_to receive(:check_lock)
        expect(fake_pdm_rule).not_to receive(:check_lock)

        check_database_lock_contention
      end
    end

    context 'when no lock entry matches the current time' do
      let(:config) { { 'locks' => [] } }

      it 'does not invoke any rule' do
        expect(fake_ddl_rule).not_to receive(:check_lock)
        expect(fake_pdm_rule).not_to receive(:check_lock)

        check_database_lock_contention
      end
    end

    context 'when active lock has block_level: only_ddl' do
      let(:config) { { 'locks' => [active_ddl_lock] } }

      it 'runs only the DDL rule with the dispatcher as context', :aggregate_failures do
        expect(Tooling::Danger::DatabaseUpgradeDdlLock).to receive(:new).with(database_change_lock)
        expect(fake_ddl_rule).to receive(:check_lock)
        expect(fake_pdm_rule).not_to receive(:check_lock)

        check_database_lock_contention
      end
    end

    context 'when active lock has block_level: only_pdm' do
      let(:config) { { 'locks' => [active_pcl_lock] } }

      it 'runs only the PDM rule with the dispatcher as context', :aggregate_failures do
        expect(Tooling::Danger::PostDeploymentMigrationLock).to receive(:new).with(database_change_lock)
        expect(fake_ddl_rule).not_to receive(:check_lock)
        expect(fake_pdm_rule).to receive(:check_lock)

        check_database_lock_contention
      end
    end

    context 'when active lock omits block_level' do
      let(:active_legacy_lock) do
        active_ddl_lock.tap { |h| h.delete('block_level') }
      end

      let(:config) { { 'locks' => [active_legacy_lock] } }

      it 'defaults to only_ddl' do
        expect(fake_ddl_rule).to receive(:check_lock)
        expect(fake_pdm_rule).not_to receive(:check_lock)

        check_database_lock_contention
      end
    end

    context 'when active lock has an unknown block_level' do
      let(:active_unknown_lock) do
        active_ddl_lock.merge('block_level' => 'something_weird')
      end

      let(:config) { { 'locks' => [active_unknown_lock] } }

      it 'falls back to only_ddl' do
        expect(fake_ddl_rule).to receive(:check_lock)
        expect(fake_pdm_rule).not_to receive(:check_lock)

        check_database_lock_contention
      end
    end
  end
end
