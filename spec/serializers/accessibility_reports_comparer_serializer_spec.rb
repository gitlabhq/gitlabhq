# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AccessibilityReportsComparerSerializer do
  let(:project) { double(:project) }
  let(:serializer) { described_class.new(project: project).represent(comparer) }
  let(:comparer) { Gitlab::Ci::Reports::AccessibilityReportsComparer.new(base_report, head_report) }
  let(:base_report) { Gitlab::Ci::Reports::AccessibilityReports.new }
  let(:head_report) { Gitlab::Ci::Reports::AccessibilityReports.new }
  let(:url) { "https://gitlab.com" }
  let(:single_error) do
    [
      {
        code: "WCAG2AA.Principle4.Guideline4_1.4_1_2.H91.A.NoContent",
        type: "error",
        typeCode: 1,
        message: "Anchor element found with a valid href attribute, but no link content has been supplied.",
        context: "<a href=\"/\" class=\"navbar-brand animated\"><svg height=\"36\" viewBox=\"0 0 1...</a>",
        selector: "#main-nav > divnth-child(1) > a",
        runner: "htmlcs",
        runnerExtras: {}
      }
    ]
  end

  let(:different_error) do
    [
      {
        code: "WCAG2AA.Principle1.Guideline1_4.1_4_3.G18.Fail",
        type: "error",
        typeCode: 1,
        message: "This element has insufficient contrast at this conformance level.",
        context: "<a href=\"/stages-devops-lifecycle/\" class=\"main-nav-link\">Product</a>",
        selector: "#main-nav > divnth-child(2) > ul > linth-child(1) > a",
        runner: "htmlcs",
        runnerExtras: {}
      }
    ]
  end

  describe '#to_json' do
    subject { serializer.as_json }

    context 'when base report has error and head has a different error' do
      before do
        base_report.add_url(url, single_error)
        head_report.add_url(url, different_error)
      end

      it 'matches the schema' do
        expect(subject).to match_schema('entities/accessibility_reports_comparer')
      end
    end

    context 'when base report has no error and head has errors' do
      before do
        head_report.add_url(url, single_error)
      end

      it 'matches the schema' do
        expect(subject).to match_schema('entities/accessibility_reports_comparer')
      end
    end
  end
end
