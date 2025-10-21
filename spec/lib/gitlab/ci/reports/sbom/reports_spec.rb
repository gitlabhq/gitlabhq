# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Reports::Sbom::Reports, feature_category: :dependency_management do
  subject(:reports_list) { described_class.new }

  describe '#add_report' do
    let(:rep1) { Gitlab::Ci::Reports::Sbom::Report.new }
    let(:rep2) { Gitlab::Ci::Reports::Sbom::Report.new }

    it 'appends the report to the report list' do
      reports_list.add_report(rep1)
      reports_list.add_report(rep2)

      expect(reports_list.reports.length).to eq(2)
      expect(reports_list.reports.first).to eq(rep1)
      expect(reports_list.reports.last).to eq(rep2)
    end
  end

  describe '#valid_reports' do
    let(:invalid_report) { instance_double(Gitlab::Ci::Reports::Sbom::Report, valid?: false) }
    let(:valid_report) { instance_double(Gitlab::Ci::Reports::Sbom::Report, valid?: true) }

    subject(:value_reports) { described_class.new([invalid_report, valid_report]).valid_reports }

    it { is_expected.to eq([valid_report]) }
  end
end
