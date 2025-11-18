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
      let(:config) do
        { 'locks' => [] }
      end

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
      let(:config) do
        {
          'locks' => [
            {
              'start_date' => "2024-11-12T09:00:00Z",
              'end_date' => "2024-11-15T09:00:00Z",
              'details' => "Contention due to Postgres 16 upgrade",
              'upgrade_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/2",
              'warning_days' => 7
            },
            {
              'start_date' => "2025-12-01T09:00:00Z",
              'end_date' => "2024-12-03T09:00:00Z",
              'details' => "Contention due to Postgres 17 upgrade",
              'upgrade_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3",
              'warning_days' => 7
            }
          ]
        }
      end

      it_behaves_like 'skipping warning and fail'
    end

    context 'when config is valid and is within warning period with no schema changes' do
      let(:file_exists) { true }
      let(:config) do
        {
          'locks' => [
            {
              'start_date' => "2023-11-12T09:00:00Z",
              'end_date' => "2023-11-15T09:00:00Z",
              'details' => "Contention due to Postgres 15 upgrade",
              'upgrade_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/1",
              'warning_days' => 7
            },
            {
              'start_date' => "2024-11-12T09:00:00Z",
              'end_date' => "2024-11-15T09:00:00Z",
              'details' => "Contention due to Postgres 16 upgrade",
              'upgrade_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/2",
              'warning_days' => 7
            },
            {
              'start_date' => "2025-11-12T09:00:00Z",
              'end_date' => "2025-11-15T09:00:00Z",
              'details' => "Contention due to Postgres 17 upgrade",
              'upgrade_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3",
              'warning_days' => 13
            }
          ]
        }
      end

      it_behaves_like 'skipping warning and fail'
    end

    context 'when config is valid and is within lock period with no schema changes' do
      let(:file_exists) { true }
      let(:ci) { true }
      let(:config) do
        {
          'locks' => [
            {
              'start_date' => "2023-11-12T09:00:00Z",
              'end_date' => "2023-11-15T09:00:00Z",
              'details' => "Contention due to Postgres 15 upgrade",
              'upgrade_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/1",
              'warning_days' => 7
            },
            {
              'start_date' => "2024-11-12T09:00:00Z",
              'end_date' => "2024-11-15T09:00:00Z",
              'details' => "Contention due to Postgres 16 upgrade",
              'upgrade_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/2",
              'warning_days' => 7
            },
            {
              'start_date' => "2025-11-01T09:00:00Z",
              'end_date' => "2025-11-03T09:00:00Z",
              'details' => "Contention due to Postgres 17 upgrade",
              'upgrade_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3",
              'warning_days' => 7
            }
          ]
        }
      end

      it_behaves_like 'skipping warning and fail'
    end

    context 'when config is valid and is within warning period' do
      let(:file_exists) { true }
      let(:modified_files) { ['db/structure.sql'] }
      let(:config) do
        {
          'locks' => [
            {
              'start_date' => "2023-11-12T09:00:00Z",
              'end_date' => "2023-11-15T09:00:00Z",
              'details' => "Contention due to Postgres 15 upgrade",
              'upgrade_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/1",
              'warning_days' => 7
            },
            {
              'start_date' => "2024-11-12T09:00:00Z",
              'end_date' => "2024-11-15T09:00:00Z",
              'details' => "Contention due to Postgres 16 upgrade",
              'upgrade_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/2",
              'warning_days' => 7
            },
            {
              'start_date' => "2025-11-12T09:00:00Z",
              'end_date' => "2025-11-15T09:00:00Z",
              'details' => "Contention due to Postgres 17 upgrade",
              'upgrade_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3",
              'warning_days' => 13
            }
          ]
        }
      end

      it 'warns about upcoming ddl lock' do
        expect(database_upgrade_ddl_lock).to receive(:warn).with(
          <<~MSG
            A database upgrade lock will be active in 11 day(s). Starting at 2025-11-12 09:00:00 UTC, merging
            migrations that changes the schema (DDL) will be disabled while a major database upgrade is performed.
            Plan accordingly or consider merging your changes before the lock begins.

            See change request: https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3

            Starts at: 2025-11-12 09:00:00 UTC
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
      let(:config) do
        {
          'locks' => [
            {
              'start_date' => "2023-11-12T09:00:00Z",
              'end_date' => "2023-11-15T09:00:00Z",
              'details' => "Contention due to Postgres 15 upgrade",
              'upgrade_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/1",
              'warning_days' => 7
            },
            {
              'start_date' => "2024-11-12T09:00:00Z",
              'end_date' => "2024-11-15T09:00:00Z",
              'details' => "Contention due to Postgres 16 upgrade",
              'upgrade_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/2",
              'warning_days' => 7
            },
            {
              'start_date' => "2025-11-01T10:00:00Z",
              'end_date' => "2025-11-03T09:00:00Z",
              'details' => "Contention due to Postgres 17 upgrade",
              'upgrade_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3",
              'warning_days' => 13
            }
          ]
        }
      end

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
      let(:config) do
        {
          'locks' => [
            {
              'start_date' => "2023-11-12T09:00:00Z",
              'end_date' => "2023-11-15T09:00:00Z",
              'details' => "Contention due to Postgres 15 upgrade",
              'upgrade_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/1",
              'warning_days' => 7
            },
            {
              'start_date' => "2024-11-12T09:00:00Z",
              'end_date' => "2024-11-15T09:00:00Z",
              'details' => "Contention due to Postgres 16 upgrade",
              'upgrade_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/2",
              'warning_days' => 7
            },
            {
              'start_date' => "2025-11-01T09:00:00Z",
              'end_date' => "2025-11-03T09:00:00Z",
              'details' => "Contention due to Postgres 17 upgrade",
              'upgrade_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3",
              'warning_days' => 7
            }
          ]
        }
      end

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

              Started at: 2025-11-01 09:00:00 UTC
              Locked until: 2025-11-03 09:00:00 UTC
              Details: Contention due to Postgres 17 upgrade
              Background: https://gitlab.com/gitlab-org/gitlab/-/issues/579388
            MSG
          )
        )

        check_ddl_lock_contention
      end
    end
  end
end
