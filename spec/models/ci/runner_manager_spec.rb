# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerManager, feature_category: :fleet_visibility, type: :model do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  it_behaves_like 'having unique enum values'

  it_behaves_like 'it has loose foreign keys' do
    let(:factory_name) { :ci_runner_machine }
  end

  it { is_expected.to belong_to(:runner) }
  it { is_expected.to belong_to(:runner_version).with_foreign_key(:version) }
  it { is_expected.to have_many(:runner_manager_builds) }
  it { is_expected.to have_many(:builds).through(:runner_manager_builds) }

  describe 'validation' do
    it { is_expected.to validate_presence_of(:runner) }
    it { is_expected.to validate_presence_of(:system_xid) }
    it { is_expected.to validate_length_of(:system_xid).is_at_most(64) }
    it { is_expected.to validate_presence_of(:runner_type).on(:create) }
    it { is_expected.to validate_presence_of(:sharding_key_id).on(:create) }
    it { is_expected.to validate_length_of(:version).is_at_most(2048) }
    it { is_expected.to validate_length_of(:revision).is_at_most(255) }
    it { is_expected.to validate_length_of(:platform).is_at_most(255) }
    it { is_expected.to validate_length_of(:architecture).is_at_most(255) }
    it { is_expected.to validate_length_of(:ip_address).is_at_most(1024) }

    context 'when runner manager is instance type', :aggregate_failures do
      let(:runner_manager) { build(:ci_runner_machine, runner_type: :instance_type) }

      it { expect(runner_manager).to be_valid }

      context 'when sharding_key_id is present' do
        let(:runner_manager) do
          build(:ci_runner_machine, runner: build(:ci_runner, sharding_key_id: non_existing_record_id))
        end

        it 'is invalid' do
          expect(runner_manager).to be_invalid
          expect(runner_manager.errors.full_messages).to contain_exactly(
            'Runner manager cannot have sharding_key_id assigned')
        end
      end
    end

    context 'when runner has config' do
      it 'is valid' do
        runner_manager = build(:ci_runner_machine, config: { gpus: "all" })

        expect(runner_manager).to be_valid
      end
    end

    context 'when runner has an invalid config' do
      it 'is invalid' do
        runner_manager = build(:ci_runner_machine, config: { test: 1 })

        expect(runner_manager).not_to be_valid
      end
    end

    describe 'shading_key_id validations' do
      let(:runner_manager) { build(:ci_runner_machine, runner: runner) }

      context 'with instance runner' do
        let(:runner) { build(:ci_runner, :instance) }

        it { expect(runner).to be_valid }

        context 'when sharding_key_id is not present' do
          before do
            runner.sharding_key_id = nil
            runner_manager.sharding_key_id = nil
          end

          it { expect(runner_manager).to be_valid }
        end
      end

      context 'with group runner' do
        let(:runner) { build(:ci_runner, :group, groups: [group]) }

        it { expect(runner_manager).to be_valid }

        context 'when sharding_key_id is not present' do
          before do
            runner.sharding_key_id = nil
            runner_manager.sharding_key_id = nil
          end

          it 'adds error to model', :aggregate_failures do
            expect(runner_manager).not_to be_valid
            expect(runner_manager.errors[:sharding_key_id]).to contain_exactly("can't be blank")
          end
        end
      end

      context 'with project runner' do
        let(:runner) { build(:ci_runner, :project, projects: [project]) }

        it { expect(runner).to be_valid }

        context 'when sharding_key_id is not present' do
          before do
            runner.sharding_key_id = nil
          end

          it 'adds error to model', :aggregate_failures do
            expect(runner_manager).not_to be_valid
            expect(runner_manager.errors[:sharding_key_id]).to contain_exactly("can't be blank")
          end
        end
      end
    end
  end

  describe 'status scopes', :freeze_time do
    before_all do
      freeze_time # Freeze time before `let_it_be` runs, so that runner statuses are frozen during execution
    end

    after :all do
      unfreeze_time
    end

    let_it_be(:runner) { create(:ci_runner, :instance) }
    let_it_be(:never_contacted_runner_manager) { create(:ci_runner_machine, :unregistered, runner: runner) }
    let_it_be(:offline_runner_manager) { create(:ci_runner_machine, :offline, runner: runner) }
    let_it_be(:online_runner_manager) { create(:ci_runner_machine, :almost_offline, runner: runner) }

    describe '.online' do
      subject(:runner_managers) { described_class.online }

      it 'returns online runner managers' do
        expect(runner_managers).to contain_exactly(online_runner_manager)
      end
    end

    describe '.offline' do
      subject(:runner_managers) { described_class.offline }

      it 'returns offline runner managers' do
        expect(runner_managers).to contain_exactly(offline_runner_manager)
      end
    end

    describe '.never_contacted' do
      subject(:runner_managers) { described_class.never_contacted }

      it 'returns never contacted runner managers' do
        expect(runner_managers).to contain_exactly(never_contacted_runner_manager)
      end
    end

    describe '.stale', :freeze_time do
      subject { described_class.stale }

      let!(:stale_runner_manager1) do
        create(
          :ci_runner_machine,
          runner: runner,
          created_at: described_class.stale_deadline - 1.second,
          contacted_at: nil
        )
      end

      let!(:stale_runner_manager2) do
        create(
          :ci_runner_machine,
          runner: runner,
          created_at: 8.days.ago,
          contacted_at: described_class.stale_deadline - 1.second
        )
      end

      it 'returns stale runner managers' do
        is_expected.to contain_exactly(stale_runner_manager1, stale_runner_manager2)
      end
    end

    include_examples 'runner with status scope'
  end

  describe '.available_statuses' do
    subject { described_class.available_statuses }

    it { is_expected.to eq(%w[online offline never_contacted stale]) }
  end

  describe '.online_contact_time_deadline', :freeze_time do
    subject { described_class.online_contact_time_deadline }

    it { is_expected.to eq(2.hours.ago) }
  end

  describe '.stale_deadline', :freeze_time do
    subject { described_class.stale_deadline }

    it { is_expected.to eq(7.days.ago) }
  end

  describe '.for_runner' do
    subject(:runner_managers) { described_class.for_runner(runner_arg) }

    let_it_be(:runner_a) { create(:ci_runner) }
    let_it_be(:runner_manager_a1) { create(:ci_runner_machine, runner: runner_a) }
    let_it_be(:runner_manager_a2) { create(:ci_runner_machine, runner: runner_a) }

    context 'with single runner' do
      let(:runner_arg) { runner_a }

      it { is_expected.to contain_exactly(runner_manager_a1, runner_manager_a2) }
    end

    context 'with numeric id for single runner' do
      let(:runner_arg) { runner_a.id }

      it { is_expected.to contain_exactly(runner_manager_a1, runner_manager_a2) }
    end

    context 'with multiple runners' do
      let(:runner_arg) { [runner_a, runner_b] }

      let_it_be(:runner_b) { create(:ci_runner) }
      let_it_be(:runner_manager_b1) { create(:ci_runner_machine, runner: runner_b) }

      it { is_expected.to contain_exactly(runner_manager_a1, runner_manager_a2, runner_manager_b1) }
    end
  end

  describe '.with_system_xid' do
    subject(:runner_managers) { described_class.with_system_xid(system_xid) }

    let_it_be(:runner_a) { create(:ci_runner) }
    let_it_be(:runner_b) { create(:ci_runner) }
    let_it_be(:runner_manager_a1) { create(:ci_runner_machine, runner: runner_a, system_xid: 'id1') }
    let_it_be(:runner_manager_a2) { create(:ci_runner_machine, runner: runner_a, system_xid: 'id2') }
    let_it_be(:runner_manager_b1) { create(:ci_runner_machine, runner: runner_b, system_xid: 'id1') }

    context 'with single system id' do
      let(:system_xid) { 'id2' }

      it { is_expected.to contain_exactly(runner_manager_a2) }
    end

    context 'with multiple system ids' do
      let(:system_xid) { %w[id1 id2] }

      it { is_expected.to contain_exactly(runner_manager_a1, runner_manager_a2, runner_manager_b1) }
    end

    context 'when chained with another scope' do
      subject(:runner_managers) { described_class.for_runner(runner).with_system_xid(system_xid) }

      let(:runner) { runner_a }
      let(:system_xid) { 'id1' }

      it { is_expected.to contain_exactly(runner_manager_a1) }

      context 'with another runner' do
        let(:runner) { runner_b }

        it { is_expected.to contain_exactly(runner_manager_b1) }
      end
    end
  end

  describe '.aggregate_upgrade_status_by_runner_id' do
    let!(:runner_version1) { create(:ci_runner_version, version: '16.0.0', status: :recommended) }
    let!(:runner_version2) { create(:ci_runner_version, version: '16.0.1', status: :available) }

    let!(:runner_a) { create(:ci_runner) }
    let!(:runner_b) { create(:ci_runner) }
    let!(:runner_manager_a1) { create(:ci_runner_machine, runner: runner_a, version: runner_version1.version) }
    let!(:runner_manager_a2) { create(:ci_runner_machine, runner: runner_a, version: runner_version2.version) }
    let!(:runner_manager_b1) { create(:ci_runner_machine, runner: runner_b, version: runner_version2.version) }

    subject { described_class.aggregate_upgrade_status_by_runner_id }

    it 'contains aggregate runner upgrade status by runner ID' do
      is_expected.to eq({
        runner_a.id => :recommended,
        runner_b.id => :available
      })
    end
  end

  describe '.with_executing_builds' do
    subject(:scope) { described_class.with_executing_builds }

    let_it_be(:runner) { create(:ci_runner) }
    let_it_be(:runner_managers_by_status) do
      Ci::HasStatus::AVAILABLE_STATUSES.index_with { |_status| create(:ci_runner_machine, runner: runner) }
    end

    let_it_be(:busy_runner_managers) do
      Ci::HasStatus::EXECUTING_STATUSES.map { |status| runner_managers_by_status[status] }
    end

    context 'with no builds running' do
      it { is_expected.to be_empty }
    end

    context 'with builds' do
      before_all do
        Ci::HasStatus::AVAILABLE_STATUSES.each do |status|
          runner_manager = runner_managers_by_status[status]
          build = create(:ci_build, status, runner: runner)
          create(:ci_runner_machine_build, runner_manager: runner_manager, build: build)
        end
      end

      it { is_expected.to match_array(busy_runner_managers) }
    end
  end

  describe '.order_id_desc' do
    subject(:scope) { described_class.order_id_desc }

    let_it_be(:runner_manager1) { create(:ci_runner_machine) }
    let_it_be(:runner_manager2) { create(:ci_runner_machine) }

    specify { expect(described_class.all).to eq([runner_manager1, runner_manager2]) }
    it { is_expected.to eq([runner_manager2, runner_manager1]) }
  end

  describe '.order_contacted_at_desc', :freeze_time do
    subject(:scope) { described_class.order_contacted_at_desc }

    let_it_be(:runner_manager1) { create(:ci_runner_machine, contacted_at: 1.second.ago) }
    let_it_be(:runner_manager2) { create(:ci_runner_machine, contacted_at: 3.seconds.ago) }
    let_it_be(:runner_manager3) { create(:ci_runner_machine, contacted_at: nil) }
    let_it_be(:runner_manager4) { create(:ci_runner_machine, contacted_at: 2.seconds.ago) }

    it { is_expected.to eq([runner_manager1, runner_manager4, runner_manager2, runner_manager3]) }
  end

  describe '.with_upgrade_status' do
    subject(:scope) { described_class.with_upgrade_status(upgrade_status) }

    let_it_be(:runner_manager_14_0_0) { create(:ci_runner_machine, version: '14.0.0') }
    let_it_be(:runner_manager_14_1_0) { create(:ci_runner_machine, version: '14.1.0') }
    let_it_be(:runner_manager_14_1_1) { create(:ci_runner_machine, version: '14.1.1') }

    before_all do
      create(:ci_runner_version, version: '14.0.0', status: :available)
      create(:ci_runner_version, version: '14.1.0', status: :recommended)
      create(:ci_runner_version, version: '14.1.1', status: :unavailable)
    end

    context 'as :unavailable' do
      let(:upgrade_status) { :unavailable }

      it 'returns runners with runner managers whose version is assigned :unavailable' do
        is_expected.to contain_exactly(runner_manager_14_1_1)
      end
    end

    context 'as :available' do
      let(:upgrade_status) { :available }

      it 'returns runners with runner managers whose version is assigned :available' do
        is_expected.to contain_exactly(runner_manager_14_0_0)
      end
    end

    context 'as :recommended' do
      let(:upgrade_status) { :recommended }

      it 'returns runners with runner managers whose version is assigned :recommended' do
        is_expected.to contain_exactly(runner_manager_14_1_0)
      end
    end
  end

  describe '.with_version_prefix' do
    subject { described_class.with_version_prefix(version_prefix) }

    let_it_be(:runner_manager1) { create(:ci_runner_machine, version: '15.11.0') }
    let_it_be(:runner_manager2) { create(:ci_runner_machine, version: '15.9.0') }
    let_it_be(:runner_manager3) { create(:ci_runner_machine, version: '15.11.5') }

    context 'with a prefix string of "15."' do
      let(:version_prefix) { "15." }

      it 'returns runner managers' do
        is_expected.to contain_exactly(runner_manager1, runner_manager2, runner_manager3)
      end
    end

    context 'with a prefix string of "15"' do
      let(:version_prefix) { "15" }

      it 'returns runner managers' do
        is_expected.to contain_exactly(runner_manager1, runner_manager2, runner_manager3)
      end
    end

    context 'with a prefix string of "15.11."' do
      let(:version_prefix) { "15.11." }

      it 'returns runner managers' do
        is_expected.to contain_exactly(runner_manager1, runner_manager3)
      end
    end

    context 'with a prefix string of "15.11"' do
      let(:version_prefix) { "15.11" }

      it 'returns runner managers' do
        is_expected.to contain_exactly(runner_manager1, runner_manager3)
      end
    end

    context 'with a prefix string of "15.9"' do
      let(:version_prefix) { "15.9" }

      it 'returns runner managers' do
        is_expected.to contain_exactly(runner_manager2)
      end
    end

    context 'with a prefix string of "15.11.5"' do
      let(:version_prefix) { "15.11.5" }

      it 'returns runner managers' do
        is_expected.to contain_exactly(runner_manager3)
      end
    end

    context 'with a malformed prefix of "V2"' do
      let(:version_prefix) { "V2" }

      it 'returns no runner managers' do
        is_expected.to be_empty
      end
    end
  end

  describe '#status', :freeze_time do
    subject { runner_manager.status }

    context 'if never connected' do
      let(:runner_manager) { build(:ci_runner_machine, :unregistered, :stale) }

      it { is_expected.to eq(:stale) }

      context 'if created recently' do
        let(:runner_manager) { build(:ci_runner_machine, :unregistered, :created_within_stale_deadline) }

        it { is_expected.to eq(:never_contacted) }
      end
    end

    context 'if contacted just now' do
      let(:runner_manager) { build(:ci_runner_machine, :online) }

      it { is_expected.to eq(:online) }
    end

    context 'if almost offline' do
      let(:runner_manager) { build(:ci_runner_machine, :almost_offline) }

      it { is_expected.to eq(:online) }
    end

    context 'if contacted recently' do
      let(:runner_manager) { build(:ci_runner_machine, :offline) }

      it { is_expected.to eq(:offline) }
    end

    context 'if contacted long time ago' do
      let(:runner_manager) { build(:ci_runner_machine, :stale) }

      it { is_expected.to eq(:stale) }
    end
  end

  describe '#heartbeat', :freeze_time do
    let(:runner_manager) { create(:ci_runner_machine, version: '15.0.0') }
    let(:executor) { 'shell' }
    let(:values) do
      {
        ip_address: '8.8.8.8',
        architecture: '18-bit',
        config: { gpus: "all" },
        executor: executor,
        version: version
      }
    end

    subject(:heartbeat) do
      runner_manager.heartbeat(values)
    end

    context 'when database was updated recently' do
      before do
        runner_manager.contacted_at = Time.current
      end

      context 'when version is changed' do
        let(:version) { '15.0.1' }

        before do
          allow(Ci::Runners::ProcessRunnerVersionUpdateWorker).to receive(:perform_async).with(version)
        end

        it 'schedules version information update' do
          heartbeat

          expect(Ci::Runners::ProcessRunnerVersionUpdateWorker).to have_received(:perform_async).with(version).once
        end

        it 'updates cache' do
          expect_redis_update

          heartbeat

          expect(runner_manager.runner_version).to be_nil
        end

        context 'when fetching runner releases is disabled' do
          before do
            stub_application_setting(update_runner_versions_enabled: false)
          end

          it 'does not schedule version information update' do
            heartbeat

            expect(Ci::Runners::ProcessRunnerVersionUpdateWorker).not_to have_received(:perform_async)
          end
        end
      end

      context 'with only ip_address specified' do
        let(:values) do
          { ip_address: '1.1.1.1' }
        end

        it 'updates only ip_address' do
          expect_redis_update(values.merge(contacted_at: Time.current, creation_state: :finished))

          heartbeat
        end

        context 'with new version having been cached' do
          let(:version) { '15.0.1' }

          before do
            runner_manager.cache_attributes(version: version)
          end

          it 'does not lose cached version value' do
            expect { heartbeat }.not_to change { runner_manager.version }.from(version)
          end
        end
      end
    end

    context 'when database was not updated recently' do
      before do
        runner_manager.contacted_at = 2.hours.ago

        allow(Ci::Runners::ProcessRunnerVersionUpdateWorker).to receive(:perform_async).with(version)
      end

      context 'when version is changed' do
        let(:version) { '15.0.1' }

        context 'with invalid runner_manager' do
          before do
            runner_manager.runner = nil
          end

          it 'still updates redis cache and database' do
            expect(runner_manager).to be_invalid

            expect_redis_update
            does_db_update

            expect(Ci::Runners::ProcessRunnerVersionUpdateWorker).to have_received(:perform_async)
              .with(version).once
          end
        end

        it 'updates redis cache and database' do
          expect_redis_update
          does_db_update

          expect(Ci::Runners::ProcessRunnerVersionUpdateWorker).to have_received(:perform_async)
            .with(version).once
        end
      end

      context 'with unchanged runner_manager version' do
        let(:version) { runner_manager.version }

        it 'does not schedule ci_runner_versions update' do
          heartbeat

          expect(Ci::Runners::ProcessRunnerVersionUpdateWorker).not_to have_received(:perform_async)
        end

        described_class::EXECUTOR_NAME_TO_TYPES.each_key do |executor|
          context "with #{executor} executor" do
            let(:executor) { executor }

            it 'updates with expected executor type' do
              expect_redis_update

              heartbeat

              expect(runner_manager.reload.read_attribute(:executor_type)).to eq(expected_executor_type)
            end

            def expected_executor_type
              executor.gsub(/[+-]/, '_')
            end
          end
        end

        context 'with an unknown executor type' do
          let(:executor) { 'some-unknown-type' }

          it 'updates with unknown executor type' do
            expect_redis_update

            heartbeat

            expect(runner_manager.reload.read_attribute(:executor_type)).to eq('unknown')
          end
        end
      end
    end

    def expect_redis_update(values = anything)
      values_json = values == anything ? anything : Gitlab::Json.dump(values)

      Gitlab::Redis::Cache.with do |redis|
        redis_key = runner_manager.send(:cache_attribute_key)
        expect(redis).to receive(:set).with(redis_key, values_json, any_args).and_call_original
      end
    end

    def does_db_update
      expect { heartbeat }.to change { runner_manager.reload.read_attribute(:contacted_at) }
                          .and change { runner_manager.reload.read_attribute(:architecture) }
                          .and change { runner_manager.reload.read_attribute(:config) }
                          .and change { runner_manager.reload.read_attribute(:executor_type) }
    end
  end

  describe '#builds' do
    let_it_be(:runner_manager) { create(:ci_runner_machine) }

    subject(:builds) { runner_manager.builds }

    it { is_expected.to be_empty }

    context 'with an existing build' do
      let!(:existing_build) { create(:ci_build) }
      let!(:runner_machine_build) do
        create(:ci_runner_machine_build, runner_manager: runner_manager, build: existing_build)
      end

      it { is_expected.to contain_exactly existing_build }
    end
  end
end
