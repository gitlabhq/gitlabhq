# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::UnitTestFailure do
  describe 'relationships' do
    it { is_expected.to belong_to(:build) }
    it { is_expected.to belong_to(:unit_test) }
  end

  describe 'validations' do
    subject { build(:ci_unit_test_failure) }

    it { is_expected.to validate_presence_of(:unit_test) }
    it { is_expected.to validate_presence_of(:build) }
    it { is_expected.to validate_presence_of(:failed_at) }
  end

  describe '.recent_failures_count' do
    let_it_be(:project) { create(:project) }

    subject(:recent_failures) do
      described_class.recent_failures_count(
        project: project,
        unit_test_keys: unit_test_keys
      )
    end

    context 'when unit test failures are within the date range and are for the unit test keys' do
      let(:test_1) { create(:ci_unit_test, project: project) }
      let(:test_2) { create(:ci_unit_test, project: project) }
      let(:unit_test_keys) { [test_1.key_hash, test_2.key_hash] }

      before do
        create_list(:ci_unit_test_failure, 3, unit_test: test_1, failed_at: 1.day.ago)
        create_list(:ci_unit_test_failure, 2, unit_test: test_2, failed_at: 3.days.ago)
      end

      it 'returns the number of failures for each unit test key hash for the past 14 days by default' do
        expect(recent_failures).to eq(
          test_1.key_hash => 3,
          test_2.key_hash => 2
        )
      end
    end

    context 'when unit test failures are within the date range but are not for the unit test keys' do
      let(:test) { create(:ci_unit_test, project: project) }
      let(:unit_test_keys) { ['some-other-key-hash'] }

      before do
        create(:ci_unit_test_failure, unit_test: test, failed_at: 1.day.ago)
      end

      it 'excludes them from the count' do
        expect(recent_failures[test.key_hash]).to be_nil
      end
    end

    context 'when unit test failures are not within the date range but are for the unit test keys' do
      let(:test) { create(:ci_unit_test, project: project) }
      let(:unit_test_keys) { [test.key_hash] }

      before do
        create(:ci_unit_test_failure, unit_test: test, failed_at: 15.days.ago)
      end

      it 'excludes them from the count' do
        expect(recent_failures[test.key_hash]).to be_nil
      end
    end
  end

  describe 'partitioning' do
    let(:project) { FactoryBot.build(:project) }
    let(:unit_test) { FactoryBot.build(:ci_unit_test, project: project) }

    context 'with build' do
      let(:build) { FactoryBot.build(:ci_build, partition_id: ci_testing_partition_id) }
      let(:unit_test_failure) do
        FactoryBot.build(:ci_unit_test_failure, build: build, unit_test: unit_test, failed_at: 1.day.ago)
      end

      it 'copies the partition_id from build' do
        expect { unit_test_failure.valid? }.to change { unit_test_failure.partition_id }.to(ci_testing_partition_id)
      end

      context 'when it is already set' do
        let(:unit_test_failure) do
          FactoryBot.build(
            :ci_unit_test_failure,
            build: build,
            unit_test: unit_test,
            failed_at: 1.day.ago,
            partition_id: 125
          )
        end

        it 'does not change the partition_id value' do
          expect { unit_test_failure.valid? }.not_to change { unit_test_failure.partition_id }
        end
      end
    end

    context 'without build' do
      subject(:unit_test_failure) { FactoryBot.build(:ci_unit_test_failure, build: nil, partition_id: 125) }

      it { is_expected.to validate_presence_of(:partition_id) }

      it 'does not change the partition_id value' do
        expect { unit_test_failure.valid? }.not_to change { unit_test_failure.partition_id }
      end
    end
  end
end
