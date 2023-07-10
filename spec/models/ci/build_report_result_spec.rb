# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildReportResult, feature_category: :continuous_integration do
  let_it_be_with_reload(:build_report_result) { create(:ci_build_report_result, :with_junit_success) }

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:parent) { create(:project) }
    let!(:model) { create(:ci_build_report_result, project: parent) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:build) }
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:build) }

    context 'when attributes are valid' do
      it 'returns no errors' do
        expect(build_report_result).to be_valid
      end
    end

    context 'when data is invalid' do
      it 'returns errors' do
        build_report_result.data = { invalid: 'data' }

        expect(build_report_result).to be_invalid
        expect(build_report_result.errors.full_messages).to eq(["Data must be a valid json schema"])
      end
    end

    context 'when data tests is invalid' do
      it 'returns errors' do
        build_report_result.data = {
          'tests' => {
            'invalid' => 'invalid'
          }
        }

        expect(build_report_result).to be_invalid
        expect(build_report_result.errors.full_messages).to eq(["Data must be a valid json schema"])
      end
    end
  end

  describe '#tests_name' do
    it 'returns the suite name' do
      expect(build_report_result.tests_name).to eq("rspec")
    end
  end

  describe '#tests_duration' do
    it 'returns the suite duration' do
      expect(build_report_result.tests_duration).to eq(0.42)
    end
  end

  describe '#tests_success' do
    it 'returns the success count' do
      expect(build_report_result.tests_success).to eq(2)
    end
  end

  describe '#tests_failed' do
    it 'returns the failed count' do
      expect(build_report_result.tests_failed).to eq(0)
    end
  end

  describe '#tests_errored' do
    it 'returns the errored count' do
      expect(build_report_result.tests_errored).to eq(0)
    end
  end

  describe '#tests_skipped' do
    it 'returns the skipped count' do
      expect(build_report_result.tests_skipped).to eq(0)
    end
  end

  describe 'partitioning' do
    let(:build_report_result) { FactoryBot.build(:ci_build_report_result, build: build) }

    context 'with build' do
      let(:build) { FactoryBot.build(:ci_build, partition_id: ci_testing_partition_id) }

      it 'copies the partition_id from build' do
        expect { build_report_result.valid? }.to change { build_report_result.partition_id }.to(ci_testing_partition_id)
      end

      context 'when it is already set' do
        let(:build_report_result) { FactoryBot.build(:ci_build_report_result, partition_id: 125) }

        it 'does not change the partition_id value' do
          expect { build_report_result.valid? }.not_to change { build_report_result.partition_id }
        end
      end
    end

    context 'without build' do
      subject(:build_report_result) { FactoryBot.build(:ci_build_report_result, build: nil, partition_id: 125) }

      it { is_expected.to validate_presence_of(:partition_id) }

      it 'does not change the partition_id value' do
        expect { build_report_result.valid? }.not_to change { build_report_result.partition_id }
      end
    end
  end
end
