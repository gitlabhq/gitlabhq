# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodequalityReportsComparerEntity do
  let(:entity) { described_class.new(comparer) }
  let(:comparer) { Gitlab::Ci::Reports::CodequalityReportsComparer.new(base_report, head_report) }
  let(:base_report) { Gitlab::Ci::Reports::CodequalityReports.new }
  let(:head_report) { Gitlab::Ci::Reports::CodequalityReports.new }
  let(:degradation_1) { build(:codequality_degradation_1) }
  let(:degradation_2) { build(:codequality_degradation_2) }

  describe '#as_json' do
    subject { entity.as_json }

    context 'when base and head report have errors' do
      before do
        base_report.add_degradation(degradation_1)
        head_report.add_degradation(degradation_2)
      end

      it 'contains correct compared codequality report details', :aggregate_failures do
        expect(subject[:status]).to eq(Gitlab::Ci::Reports::CodequalityReportsComparer::STATUS_FAILED)
        expect(subject[:resolved_errors].first).to include(:description, :severity, :file_path, :line)
        expect(subject[:new_errors].first).to include(:description, :severity, :file_path, :line)
        expect(subject[:existing_errors]).to be_empty
        expect(subject[:summary]).to include(total: 1, resolved: 1, errored: 1)
      end
    end
  end
end
