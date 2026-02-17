# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'
require_relative '../../../tooling/danger/database_upgrade_ddl_lock'

RSpec.describe Tooling::Danger::DatabaseUpgradeDdlLock, feature_category: :database do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }

  subject(:database_upgrade_ddl_lock) { fake_danger.new(helper: fake_helper) }

  describe '#check_ddl_lock_contention', time_travel_to: '2025-11-01 09:00:00 UTC' do
    subject(:check_ddl_lock_contention) { database_upgrade_ddl_lock.check_ddl_lock_contention }

    let(:file_exists) { false }
    # Past lock (already completed)
    let(:past_lock) do
      {
        'start_date' => "2023-11-14T09:00:00Z",
        'end_date' => "2023-11-15T09:00:00Z",
        'details' => "Contention due to Postgres 15 upgrade",
        'upgrade_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/1",
        'warning_days' => 7,
        'merge_buffer' => 2
      }
    end

    # Future lock (not yet in warning period)
    let(:future_lock) do
      {
        'start_date' => "2025-12-03T09:00:00Z",
        'end_date' => "2025-12-05T09:00:00Z",
        'details' => "Contention due to Postgres 17 upgrade",
        'upgrade_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3",
        'warning_days' => 7,
        'merge_buffer' => 2
      }
    end

    # Active lock (currently in lock period)
    let(:active_lock) do
      {
        'start_date' => "2025-11-03T09:00:00Z",
        'end_date' => "2025-11-05T09:00:00Z",
        'details' => "Contention due to Postgres 17 upgrade",
        'upgrade_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3",
        'warning_days' => 7,
        'merge_buffer' => 2
      }
    end

    # Warning period lock (in warning period, lock starts soon)
    let(:warning_lock) do
      {
        'start_date' => "2025-11-14T09:00:00Z",
        'end_date' => "2025-11-15T09:00:00Z",
        'details' => "Contention due to Postgres 17 upgrade",
        'upgrade_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3",
        'warning_days' => 13,
        'merge_buffer' => 2
      }
    end

    let(:ci) { false }
    let(:config) { {} }
    let(:modified_files) { [] }

    before do
      allow(File).to receive(:exist?).and_return(file_exists)
      allow(YAML).to receive(:safe_load_file).and_return(config)
      allow(database_upgrade_ddl_lock).to receive(:fail)
      allow(fake_helper).to receive_messages(all_changed_files: modified_files, ci?: ci)
    end

    shared_examples 'skipping warning and fail' do
      it 'does not warn' do
        expect(database_upgrade_ddl_lock).not_to receive(:warn)
        check_ddl_lock_contention
      end

      it 'does not fail' do
        expect(database_upgrade_ddl_lock).not_to receive(:fail)
        check_ddl_lock_contention
      end
    end

    context "when there's no config file available" do
      it_behaves_like 'skipping warning and fail'
    end

    context "when config has an empty array" do
      let(:config) { { 'locks' => [] } }

      it_behaves_like 'skipping warning and fail'
    end

    context "when config is invalid" do
      let(:file_exists) { true }
      let(:config) do
        {
          'locks' => [
            {
              'start_date' => nil,
              'end_date' => nil,
              'details' => nil,
              'upgrade_issue_url' => nil,
              'warning_days' => nil
            }
          ]
        }
      end

      it_behaves_like 'skipping warning and fail'
    end

    context 'when config is valid and out of locking and warning period' do
      let(:file_exists) { true }
      let(:config) { { 'locks' => [past_lock, future_lock] } }

      it_behaves_like 'skipping warning and fail'
    end

    context 'when config is valid and is within warning period with no schema changes' do
      let(:file_exists) { true }
      let(:config) { { 'locks' => [past_lock, warning_lock] } }

      it_behaves_like 'skipping warning and fail'
    end

    context 'when config is valid and is within lock period with no schema changes' do
      let(:file_exists) { true }
      let(:ci) { true }
      let(:config) { { 'locks' => [past_lock, active_lock] } }

      it_behaves_like 'skipping warning and fail'
    end

    context 'when config is valid and is within warning period' do
      let(:file_exists) { true }
      let(:modified_files) { ['db/structure.sql'] }
      let(:config) { { 'locks' => [past_lock, warning_lock] } }

      it 'warns about upcoming ddl lock' do
        expect(database_upgrade_ddl_lock).to receive(:warn).with(
          <<~MSG
            A database upgrade lock will be active in 11 day(s). Starting at 2025-11-12 09:00:00 UTC, merging
            migrations that changes the schema (DDL) will be disabled. The maintenance window is scheduled for 2025-11-14 09:00:00 UTC,
            but merges are blocked 2 day(s) earlier to allow time for deployment ahead of the upgrade.

            See change request: https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3

            Maintenance starts at: 2025-11-14 09:00:00 UTC
            Merge lock starts at: 2025-11-12 09:00:00 UTC
            Locked until: 2025-11-15 09:00:00 UTC
            Details: Contention due to Postgres 17 upgrade
            Background: https://gitlab.com/gitlab-org/gitlab/-/issues/579388
          MSG
        )

        check_ddl_lock_contention
      end

      it 'does not fail' do
        expect(database_upgrade_ddl_lock).not_to receive(:fail)
        check_ddl_lock_contention
      end
    end

    context 'when config is valid and lock starts in a hour' do
      let(:file_exists) { true }
      let(:modified_files) { ['db/structure.sql'] }
      let(:imminent_lock) do
        {
          'start_date' => "2025-11-03T12:00:00Z",
          'end_date' => "2025-11-05T09:00:00Z",
          'details' => "Contention due to Postgres 17 upgrade",
          'upgrade_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3",
          'warning_days' => 13,
          'merge_buffer' => 2
        }
      end

      let(:config) { { 'locks' => [past_lock, imminent_lock] } }

      it 'warns about upcoming ddl lock' do
        expect(database_upgrade_ddl_lock).to receive(:warn)
        check_ddl_lock_contention
      end

      it 'does not fail' do
        expect(database_upgrade_ddl_lock).not_to receive(:fail)
        check_ddl_lock_contention
      end
    end

    context 'when config is valid and is within lock period and has schema changes' do
      let(:file_exists) { true }
      let(:ci) { true }
      let(:modified_files) { ['db/structure.sql'] }
      let(:config) { { 'locks' => [past_lock, active_lock] } }

      it 'does not warn' do
        expect(database_upgrade_ddl_lock).not_to receive(:warn)
        check_ddl_lock_contention
      end

      it 'warns about effective ddl lock in place' do
        expect(database_upgrade_ddl_lock).to(
          receive(:fail).with(
            <<~MSG
              Merging migrations that change schema is currently disabled while a major database upgrade is
              performed. After the lock expires, retry this job and danger will pass.

              See change request: https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3

              Maintenance starts at: 2025-11-03 09:00:00 UTC
              Merge lock started at: 2025-11-01 09:00:00 UTC
              Locked until: 2025-11-05 09:00:00 UTC
              Details: Contention due to Postgres 17 upgrade
              Background: https://gitlab.com/gitlab-org/gitlab/-/issues/579388
            MSG
          )
        )

        check_ddl_lock_contention
      end
    end

    context 'when config uses custom merge_buffer value' do
      let(:file_exists) { true }
      let(:modified_files) { ['db/structure.sql'] }
      let(:custom_buffer_lock) do
        {
          'start_date' => "2025-11-13T09:00:00Z",
          'end_date' => "2025-11-15T09:00:00Z",
          'details' => "Contention due to Postgres 17 upgrade",
          'upgrade_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3",
          'warning_days' => 10,
          'merge_buffer' => 5
        }
      end

      let(:config) { { 'locks' => [custom_buffer_lock] } }

      it 'warns with correct merge buffer days' do
        expect(database_upgrade_ddl_lock).to receive(:warn).with(
          <<~MSG
            A database upgrade lock will be active in 7 day(s). Starting at 2025-11-08 09:00:00 UTC, merging
            migrations that changes the schema (DDL) will be disabled. The maintenance window is scheduled for 2025-11-13 09:00:00 UTC,
            but merges are blocked 5 day(s) earlier to allow time for deployment ahead of the upgrade.

            See change request: https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3

            Maintenance starts at: 2025-11-13 09:00:00 UTC
            Merge lock starts at: 2025-11-08 09:00:00 UTC
            Locked until: 2025-11-15 09:00:00 UTC
            Details: Contention due to Postgres 17 upgrade
            Background: https://gitlab.com/gitlab-org/gitlab/-/issues/579388
          MSG
        )

        check_ddl_lock_contention
      end
    end

    context 'when config omits merge_buffer (uses default)' do
      let(:file_exists) { true }
      let(:modified_files) { ['db/structure.sql'] }
      let(:default_buffer_lock) do
        {
          'start_date' => "2025-11-14T09:00:00Z",
          'end_date' => "2025-11-15T09:00:00Z",
          'details' => "Contention due to Postgres 17 upgrade",
          'upgrade_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3",
          'warning_days' => 13
        }
      end

      let(:config) { { 'locks' => [default_buffer_lock] } }

      it 'uses default merge buffer of 2 days' do
        expect(database_upgrade_ddl_lock).to receive(:warn).with(
          <<~MSG
            A database upgrade lock will be active in 11 day(s). Starting at 2025-11-12 09:00:00 UTC, merging
            migrations that changes the schema (DDL) will be disabled. The maintenance window is scheduled for 2025-11-14 09:00:00 UTC,
            but merges are blocked 2 day(s) earlier to allow time for deployment ahead of the upgrade.

            See change request: https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3

            Maintenance starts at: 2025-11-14 09:00:00 UTC
            Merge lock starts at: 2025-11-12 09:00:00 UTC
            Locked until: 2025-11-15 09:00:00 UTC
            Details: Contention due to Postgres 17 upgrade
            Background: https://gitlab.com/gitlab-org/gitlab/-/issues/579388
          MSG
        )

        check_ddl_lock_contention
      end
    end
  end
end
