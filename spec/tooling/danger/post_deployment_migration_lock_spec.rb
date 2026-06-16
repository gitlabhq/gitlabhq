# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'
require_relative '../../../tooling/danger/post_deployment_migration_lock'
require_relative 'support/database_change_lock_rule_context'

RSpec.describe Tooling::Danger::PostDeploymentMigrationLock, feature_category: :database do
  include_context "with dangerfile"
  include_context 'with database change lock rule context'

  subject(:post_deployment_migration_lock) { described_class.new(context) }

  describe '#check_lock', time_travel_to: '2025-11-01 09:00:00 UTC' do
    subject(:check_lock) { post_deployment_migration_lock.check_lock }

    let(:file_exists) { false }

    let(:past_lock) do
      {
        'start_date' => "2023-11-14T09:00:00Z",
        'end_date' => "2023-11-15T09:00:00Z",
        'details' => "Contention due to Postgres 15 upgrade",
        'change_request_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/1",
        'warning_days' => 7,
        'merge_buffer' => 2
      }
    end

    let(:future_lock) do
      {
        'start_date' => "2025-12-03T09:00:00Z",
        'end_date' => "2025-12-05T09:00:00Z",
        'details' => "Contention due to Postgres 17 upgrade",
        'change_request_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3",
        'warning_days' => 7,
        'merge_buffer' => 2
      }
    end

    let(:active_lock) do
      {
        'start_date' => "2025-11-03T09:00:00Z",
        'end_date' => "2025-11-05T09:00:00Z",
        'details' => "Contention due to Postgres 17 upgrade",
        'change_request_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3",
        'warning_days' => 7,
        'merge_buffer' => 2
      }
    end

    let(:warning_lock) do
      {
        'start_date' => "2025-11-14T09:00:00Z",
        'end_date' => "2025-11-15T09:00:00Z",
        'details' => "Contention due to Postgres 17 upgrade",
        'change_request_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3",
        'warning_days' => 13,
        'merge_buffer' => 2
      }
    end

    let(:ci) { false }
    let(:config) { {} }
    let(:added_files) { [] }

    before do
      allow(File).to receive(:exist?).and_return(file_exists)
      allow(YAML).to receive(:safe_load_file).and_return(config)
      allow(context).to receive(:warn)
      allow(context).to receive(:fail)
      allow(fake_helper).to receive_messages(added_files: added_files, ci?: ci)
    end

    shared_examples 'skipping warning and fail' do
      it 'does not warn' do
        expect(context).not_to receive(:warn)
        check_lock
      end

      it 'does not fail' do
        expect(context).not_to receive(:fail)
        check_lock
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
              'change_request_issue_url' => nil,
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

    context 'when config is valid and is within warning period with no PDM additions' do
      let(:file_exists) { true }
      let(:config) { { 'locks' => [past_lock, warning_lock] } }

      it_behaves_like 'skipping warning and fail'
    end

    context 'when config is valid and is within lock period with no PDM additions' do
      let(:file_exists) { true }
      let(:ci) { true }
      let(:config) { { 'locks' => [past_lock, active_lock] } }

      it_behaves_like 'skipping warning and fail'
    end

    context 'when only a DDL change is present (no PDM)' do
      let(:file_exists) { true }
      let(:ci) { true }
      let(:added_files) { ['db/structure.sql', 'db/migrate/20251101_add_foo.rb'] }
      let(:config) { { 'locks' => [past_lock, active_lock] } }

      it_behaves_like 'skipping warning and fail'
    end

    context 'when config is valid and is within warning period with an added PDM' do
      let(:file_exists) { true }
      let(:added_files) { ['db/post_migrate/20251101_cleanup_foo.rb'] }
      let(:config) { { 'locks' => [past_lock, warning_lock] } }

      it 'warns about upcoming pdm lock' do
        expect(context).to receive(:warn).with(
          <<~MSG
            A post-deployment migration (PDM) lock will be active in 11 day(s). Starting at 2025-11-12 09:00:00 UTC,
            merging new PDMs will be disabled because PDMs are not executed during the upcoming soft Production Change Lock (PCL),
            and merging them anyway would pile them up into a larger, riskier post-PCL migration run.

            See change request: https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3

            Soft PCL starts at: 2025-11-14 09:00:00 UTC
            Merge lock starts at: 2025-11-12 09:00:00 UTC
            Locked until: 2025-11-15 09:00:00 UTC
            Details: Contention due to Postgres 17 upgrade
            What is a soft PCL: https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/change-management/#soft-pcl
            Background: https://gitlab.com/gitlab-com/gl-infra/change-lock/-/blob/master/config/changelock.yml
          MSG
        )

        check_lock
      end

      it 'does not fail' do
        expect(context).not_to receive(:fail)
        check_lock
      end
    end

    context 'when config is valid and is within lock period and a PDM is added under db/post_migrate' do
      let(:file_exists) { true }
      let(:ci) { true }
      let(:added_files) { ['db/post_migrate/20251103_cleanup_foo.rb'] }
      let(:config) { { 'locks' => [past_lock, active_lock] } }

      it 'does not warn' do
        expect(context).not_to receive(:warn)
        check_lock
      end

      it 'fails about effective pdm lock in place' do
        expect(context).to(
          receive(:fail).with(
            <<~MSG
              Merging post-deployment migrations (PDMs) is currently disabled because a soft Production Change Lock (PCL)
              is in effect. PDMs are not executed during a soft PCL, so merging new ones would pile them up and grow the
              backlog that has to run once the PCL ends, increasing the size and risk of that post-PCL migration run.
              After the lock expires, retry this job and danger will pass.

              See change request: https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3

              Soft PCL starts at: 2025-11-03 09:00:00 UTC
              Merge lock started at: 2025-11-01 09:00:00 UTC
              Locked until: 2025-11-05 09:00:00 UTC
              Details: Contention due to Postgres 17 upgrade
              What is a soft PCL: https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/change-management/#soft-pcl
              Background: https://gitlab.com/gitlab-com/gl-infra/change-lock/-/blob/master/config/changelock.yml
            MSG
          )
        )

        check_lock
      end
    end

    context 'when an EE PDM is added under ee/db/post_migrate during the lock period' do
      let(:file_exists) { true }
      let(:ci) { true }
      let(:added_files) { ['ee/db/post_migrate/20251103_cleanup_foo.rb'] }
      let(:config) { { 'locks' => [past_lock, active_lock] } }

      it 'fails' do
        expect(context).to receive(:fail)
        check_lock
      end
    end

    context 'when a non-PDM migration is added during the lock period' do
      let(:file_exists) { true }
      let(:ci) { true }
      let(:added_files) { ['db/migrate/20251103_add_index.rb'] }
      let(:config) { { 'locks' => [past_lock, active_lock] } }

      it_behaves_like 'skipping warning and fail'
    end

    context 'when CI is not running and a PDM is added during the lock period' do
      let(:file_exists) { true }
      let(:ci) { false }
      let(:added_files) { ['db/post_migrate/20251103_cleanup_foo.rb'] }
      let(:config) { { 'locks' => [past_lock, active_lock] } }

      it 'does not warn' do
        expect(context).not_to receive(:warn)
        check_lock
      end

      it 'does not fail' do
        expect(context).not_to receive(:fail)
        check_lock
      end
    end

    context 'when merge_buffer is 0 and the lock has not yet started' do
      let(:file_exists) { true }
      let(:ci) { true }
      let(:added_files) { ['db/post_migrate/20251102_cleanup_foo.rb'] }
      let(:zero_buffer_lock) do
        {
          'start_date' => "2025-11-02T09:00:00Z",
          'end_date' => "2025-11-03T09:00:00Z",
          'details' => "Soft PCL",
          'change_request_issue_url' => "https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/work_items/29078",
          'warning_days' => 7,
          'merge_buffer' => 0
        }
      end

      let(:config) { { 'locks' => [zero_buffer_lock] } }

      it 'warns but does not fail (lock starts exactly at start_date)', :aggregate_failures do
        expect(context).to receive(:warn)
        expect(context).not_to receive(:fail)
        check_lock
      end

      it 'collapses the schedule to a single line when there is no merge buffer' do
        expect(context).to receive(:warn) do |message|
          expect(message).to include('Soft PCL starts at: 2025-11-02 09:00:00 UTC')
          expect(message).not_to include('Merge lock starts at')
        end

        check_lock
      end
    end
  end
end
