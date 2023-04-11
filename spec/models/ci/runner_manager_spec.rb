# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerManager, feature_category: :runner_fleet, type: :model do
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
    it { is_expected.to validate_length_of(:version).is_at_most(2048) }
    it { is_expected.to validate_length_of(:revision).is_at_most(255) }
    it { is_expected.to validate_length_of(:platform).is_at_most(255) }
    it { is_expected.to validate_length_of(:architecture).is_at_most(255) }
    it { is_expected.to validate_length_of(:ip_address).is_at_most(1024) }

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
  end

  describe '.stale', :freeze_time do
    subject { described_class.stale.ids }

    let!(:runner_manager1) { create(:ci_runner_machine, :stale) }
    let!(:runner_manager2) { create(:ci_runner_machine, :stale, contacted_at: nil) }
    let!(:runner_manager3) { create(:ci_runner_machine, created_at: 6.months.ago, contacted_at: Time.current) }
    let!(:runner_manager4) { create(:ci_runner_machine, created_at: 5.days.ago) }
    let!(:runner_manager5) do
      create(:ci_runner_machine, created_at: (7.days - 1.second).ago, contacted_at: (7.days - 1.second).ago)
    end

    it 'returns stale runner managers' do
      is_expected.to match_array([runner_manager1.id, runner_manager2.id])
    end
  end

  describe '.online_contact_time_deadline', :freeze_time do
    subject { described_class.online_contact_time_deadline }

    it { is_expected.to eq(2.hours.ago) }
  end

  describe '.stale_deadline', :freeze_time do
    subject { described_class.stale_deadline }

    it { is_expected.to eq(7.days.ago) }
  end

  describe '#status', :freeze_time do
    let(:runner_manager) { build(:ci_runner_machine, created_at: 8.days.ago) }

    subject { runner_manager.status }

    context 'if never connected' do
      before do
        runner_manager.contacted_at = nil
      end

      it { is_expected.to eq(:stale) }

      context 'if created recently' do
        before do
          runner_manager.created_at = 1.day.ago
        end

        it { is_expected.to eq(:never_contacted) }
      end
    end

    context 'if contacted 1s ago' do
      before do
        runner_manager.contacted_at = 1.second.ago
      end

      it { is_expected.to eq(:online) }
    end

    context 'if contacted recently' do
      before do
        runner_manager.contacted_at = 2.hours.ago
      end

      it { is_expected.to eq(:offline) }
    end

    context 'if contacted long time ago' do
      before do
        runner_manager.contacted_at = 7.days.ago
      end

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
          expect_redis_update(values.merge(contacted_at: Time.current))

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

        Ci::Runner::EXECUTOR_NAME_TO_TYPES.each_key do |executor|
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
end
