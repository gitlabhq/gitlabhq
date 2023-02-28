# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerMachine, feature_category: :runner_fleet, type: :model do
  it_behaves_like 'having unique enum values'

  it { is_expected.to belong_to(:runner) }
  it { is_expected.to belong_to(:runner_version).with_foreign_key(:version) }
  it { is_expected.to have_many(:runner_machine_builds) }
  it { is_expected.to have_many(:builds).through(:runner_machine_builds) }

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
        runner_machine = build(:ci_runner_machine, config: { gpus: "all" })

        expect(runner_machine).to be_valid
      end
    end

    context 'when runner has an invalid config' do
      it 'is invalid' do
        runner_machine = build(:ci_runner_machine, config: { test: 1 })

        expect(runner_machine).not_to be_valid
      end
    end
  end

  describe '.stale', :freeze_time do
    subject { described_class.stale.ids }

    let!(:runner_machine1) { create(:ci_runner_machine, :stale) }
    let!(:runner_machine2) { create(:ci_runner_machine, :stale, contacted_at: nil) }
    let!(:runner_machine3) { create(:ci_runner_machine, created_at: 6.months.ago, contacted_at: Time.current) }
    let!(:runner_machine4) { create(:ci_runner_machine, created_at: 5.days.ago) }
    let!(:runner_machine5) do
      create(:ci_runner_machine, created_at: (7.days - 1.second).ago, contacted_at: (7.days - 1.second).ago)
    end

    it 'returns stale runner machines' do
      is_expected.to match_array([runner_machine1.id, runner_machine2.id])
    end
  end

  describe '#heartbeat', :freeze_time do
    let(:runner_machine) { create(:ci_runner_machine, version: '15.0.0') }
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
      runner_machine.heartbeat(values)
    end

    context 'when database was updated recently' do
      before do
        runner_machine.contacted_at = Time.current
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

          expect(runner_machine.runner_version).to be_nil
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
            runner_machine.cache_attributes(version: version)
          end

          it 'does not lose cached version value' do
            expect { heartbeat }.not_to change { runner_machine.version }.from(version)
          end
        end
      end
    end

    context 'when database was not updated recently' do
      before do
        runner_machine.contacted_at = 2.hours.ago

        allow(Ci::Runners::ProcessRunnerVersionUpdateWorker).to receive(:perform_async).with(version)
      end

      context 'when version is changed' do
        let(:version) { '15.0.1' }

        context 'with invalid runner_machine' do
          before do
            runner_machine.runner = nil
          end

          it 'still updates redis cache and database' do
            expect(runner_machine).to be_invalid

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

      context 'with unchanged runner_machine version' do
        let(:version) { runner_machine.version }

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

              expect(runner_machine.reload.read_attribute(:executor_type)).to eq(expected_executor_type)
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

            expect(runner_machine.reload.read_attribute(:executor_type)).to eq('unknown')
          end
        end
      end
    end

    def expect_redis_update(values = anything)
      values_json = values == anything ? anything : Gitlab::Json.dump(values)

      Gitlab::Redis::Cache.with do |redis|
        redis_key = runner_machine.send(:cache_attribute_key)
        expect(redis).to receive(:set).with(redis_key, values_json, any_args).and_call_original
      end
    end

    def does_db_update
      expect { heartbeat }.to change { runner_machine.reload.read_attribute(:contacted_at) }
                          .and change { runner_machine.reload.read_attribute(:architecture) }
                          .and change { runner_machine.reload.read_attribute(:config) }
                          .and change { runner_machine.reload.read_attribute(:executor_type) }
    end
  end
end
