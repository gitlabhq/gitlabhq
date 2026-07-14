# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobArtifactReport, feature_category: :job_artifacts do
  it { is_expected.to belong_to(:job_artifact) }

  describe 'validation' do
    it { is_expected.to validate_presence_of(:job_artifact) }
    it { is_expected.to validate_presence_of(:project_id) }
  end

  describe '#validation_error=' do
    it 'truncates validation_error to 255 characters' do
      report = described_class.new
      report.validation_error = 'A' * 1000
      expect(report.validation_error.size).to eq(255)
    end
  end

  describe 'partitioning' do
    context 'with job_artifact' do
      let_it_be(:job_artifact) { build(:ci_job_artifact, partition_id: ci_testing_partition_id) }
      # `freeze: false` is required in this spec: one or more `let_it_be` subjects
      # cannot be frozen by default (deep_freeze traversal failure, a non-AR
      # subject, or an in-memory mutation that survives reload/refind). Do not
      # drop these opt-outs or convert them to `let_it_be_with_reload`/`refind`
      # (see gitlab-org/gitlab#602925).
      let_it_be(:job_artifact_report, freeze: false) { build(:ci_job_artifact_report, job_artifact: job_artifact) }

      it 'sets partition_id to the current partition value' do
        expect { job_artifact_report.valid? }.to change { job_artifact_report.partition_id }.to(ci_testing_partition_id)
      end

      context 'when it is already set' do
        let_it_be(:job_artifact_report, freeze: false) { build(:ci_job_artifact_report, partition_id: 125) }

        it 'does not change the partition_id value' do
          expect { job_artifact_report.valid? }.not_to change { job_artifact_report.partition_id }
        end
      end
    end
  end
end
