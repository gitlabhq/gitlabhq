# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::CodequalityReportsComparer do
  let(:comparer) { described_class.new(base_report, head_report) }
  let(:base_report) { Gitlab::Ci::Reports::CodequalityReports.new }
  let(:head_report) { Gitlab::Ci::Reports::CodequalityReports.new }
  let(:major_degradation) { build(:codequality_degradation, :major) }
  let(:minor_degradation) { build(:codequality_degradation, :minor) }
  let(:critical_degradation) { build(:codequality_degradation, :critical) }
  let(:blocker_degradation) { build(:codequality_degradation, :blocker) }

  describe '#status' do
    subject(:report_status) { comparer.status }

    context 'when head report has an error' do
      before do
        head_report.add_degradation(major_degradation)
      end

      it 'returns status failed' do
        expect(report_status).to eq(described_class::STATUS_FAILED)
      end
    end

    context 'when head report does not have errors' do
      it 'returns status success' do
        expect(report_status).to eq(described_class::STATUS_SUCCESS)
      end
    end

    context 'when head report does not exist' do
      let(:head_report) { nil }

      it 'returns status not found' do
        expect(report_status).to eq(described_class::STATUS_NOT_FOUND)
      end
    end

    context 'when base report does not exist' do
      let(:base_report) { nil }

      it 'returns status success' do
        expect(report_status).to eq(described_class::STATUS_NOT_FOUND)
      end
    end
  end

  describe '#errors_count' do
    subject(:errors_count) { comparer.errors_count }

    context 'when head report has an error' do
      before do
        head_report.add_degradation(major_degradation)
      end

      it 'returns the number of new errors' do
        expect(errors_count).to eq(1)
      end
    end

    context 'when head report does not have an error' do
      it 'returns zero' do
        expect(errors_count).to be_zero
      end
    end
  end

  describe '#resolved_count' do
    subject(:resolved_count) { comparer.resolved_count }

    context 'when base report has an error and head has a different error' do
      before do
        base_report.add_degradation(major_degradation)
        head_report.add_degradation(minor_degradation)
      end

      it 'counts the base report error as resolved' do
        expect(resolved_count).to eq(1)
      end
    end

    context 'when base report has errors head has no errors' do
      before do
        base_report.add_degradation(major_degradation)
      end

      it 'counts the base report errors as resolved' do
        expect(resolved_count).to eq(1)
      end
    end

    context 'when base report has errors and head has the same error' do
      before do
        base_report.add_degradation(major_degradation)
        head_report.add_degradation(major_degradation)
      end

      it 'returns zero' do
        expect(resolved_count).to eq(0)
      end
    end

    context 'when base report does not have errors and head has errors' do
      before do
        head_report.add_degradation(major_degradation)
      end

      it 'returns zero' do
        expect(resolved_count).to be_zero
      end
    end

    context 'when base report is nil' do
      let(:base_report) { nil }

      it 'returns zero' do
        expect(resolved_count).to be_zero
      end
    end
  end

  describe '#total_count' do
    subject(:total_count) { comparer.total_count }

    context 'when base report has an error' do
      before do
        base_report.add_degradation(major_degradation)
      end

      it 'returns zero' do
        expect(total_count).to be_zero
      end
    end

    context 'when head report has an error' do
      before do
        head_report.add_degradation(major_degradation)
      end

      it 'includes the head report error in the count' do
        expect(total_count).to eq(1)
      end
    end

    context 'when base report has errors and head report has errors' do
      before do
        base_report.add_degradation(major_degradation)
        head_report.add_degradation(minor_degradation)
      end

      it 'includes errors in the count' do
        expect(total_count).to eq(1)
      end
    end

    context 'when base report has errors and head report has the same error' do
      before do
        base_report.add_degradation(major_degradation)
        head_report.add_degradation(major_degradation)
        head_report.add_degradation(minor_degradation)
      end

      it 'includes errors in the count' do
        expect(total_count).to eq(2)
      end
    end

    context 'when base report is nil' do
      let(:base_report) { nil }

      it 'returns zero' do
        expect(total_count).to be_zero
      end
    end
  end

  describe '#existing_errors' do
    subject(:existing_errors) { comparer.existing_errors }

    context 'when base report has errors and head has the same error' do
      before do
        base_report.add_degradation(major_degradation)
        base_report.add_degradation(critical_degradation)
        base_report.add_degradation(blocker_degradation)
        head_report.add_degradation(critical_degradation)
        head_report.add_degradation(blocker_degradation)
        head_report.add_degradation(major_degradation)
        head_report.add_degradation(minor_degradation)
      end

      it 'includes the base report errors sorted by severity' do
        expect(existing_errors).to eq(
          [
            blocker_degradation,
            critical_degradation,
            major_degradation
          ])
      end
    end

    context 'when base report has errors and head has a different error' do
      before do
        base_report.add_degradation(major_degradation)
        head_report.add_degradation(minor_degradation)
      end

      it 'returns an empty array' do
        expect(existing_errors).to be_empty
      end
    end

    context 'when base report does not have errors and head has errors' do
      before do
        head_report.add_degradation(major_degradation)
      end

      it 'returns an empty array' do
        expect(existing_errors).to be_empty
      end
    end

    context 'when base report is nil' do
      let(:base_report) { nil }

      it 'returns an empty array' do
        expect(existing_errors).to be_empty
      end
    end
  end

  describe '#new_errors' do
    subject(:new_errors) { comparer.new_errors }

    context 'when base report has errors and head has more errors' do
      before do
        base_report.add_degradation(major_degradation)
        head_report.add_degradation(critical_degradation)
        head_report.add_degradation(minor_degradation)
        head_report.add_degradation(blocker_degradation)
        head_report.add_degradation(major_degradation)
      end

      it 'includes errors not found in the base report sorted by severity' do
        expect(new_errors).to eq(
          [
            blocker_degradation,
            critical_degradation,
            minor_degradation
          ])
      end
    end

    context 'when base report has an error and head has no errors' do
      before do
        base_report.add_degradation(major_degradation)
      end

      it 'returns an empty array' do
        expect(new_errors).to be_empty
      end
    end

    context 'when base report does not have errors and head has errors' do
      before do
        head_report.add_degradation(major_degradation)
      end

      it 'returns the head report error' do
        expect(new_errors).to eq([major_degradation])
      end
    end

    context 'when base report is nil' do
      let(:base_report) { nil }

      it 'returns an empty array' do
        expect(new_errors).to be_empty
      end
    end
  end

  describe '#resolved_errors' do
    subject(:resolved_errors) { comparer.resolved_errors }

    context 'when base report errors are still found in the head report' do
      before do
        base_report.add_degradation(major_degradation)
        head_report.add_degradation(major_degradation)
        head_report.add_degradation(minor_degradation)
      end

      it 'returns an empty array' do
        expect(resolved_errors).to be_empty
      end
    end

    context 'when base report has errors and head has a different error' do
      before do
        base_report.add_degradation(major_degradation)
        base_report.add_degradation(minor_degradation)
        base_report.add_degradation(critical_degradation)
        base_report.add_degradation(blocker_degradation)
        head_report.add_degradation(major_degradation)
      end

      it 'returns the base report errors not found in the head report, sorted by severity' do
        expect(resolved_errors).to eq(
          [
            blocker_degradation,
            critical_degradation,
            minor_degradation
          ])
      end
    end

    context 'when base report does not have errors and head has errors' do
      before do
        head_report.add_degradation(major_degradation)
      end

      it 'returns an empty array' do
        expect(resolved_errors).to be_empty
      end
    end

    context 'when base report is nil' do
      let(:base_report) { nil }

      it 'returns an empty array' do
        expect(resolved_errors).to be_empty
      end
    end
  end
end
