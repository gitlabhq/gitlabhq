# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AccessibilityReportsComparerEntity do
  let(:entity) { described_class.new(comparer) }
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
        selector: "#main-nav > div:nth-child(1) > a",
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
        selector: "#main-nav > div:nth-child(2) > ul > li:nth-child(1) > a",
        runner: "htmlcs",
        runnerExtras: {}
      }
    ]
  end

  describe '#as_json' do
    subject { entity.as_json }

    context 'when base report has error and head has a different error' do
      before do
        base_report.add_url(url, single_error)
        head_report.add_url(url, different_error)
      end

      it 'contains correct compared accessibility report details', :aggregate_failures do
        expect(subject[:status]).to eq(Gitlab::Ci::Reports::AccessibilityReportsComparer::STATUS_FAILED)
        expect(subject[:resolved_errors].first).to include(:code, :type, :type_code, :message, :context, :selector, :runner, :runner_extras)
        expect(subject[:new_errors].first).to include(:code, :type, :type_code, :message, :context, :selector, :runner, :runner_extras)
        expect(subject[:existing_errors]).to be_empty
        expect(subject[:summary]).to include(total: 1, resolved: 1, errored: 1)
      end
    end

    context 'when base report has error and head has the same error' do
      before do
        base_report.add_url(url, single_error)
        head_report.add_url(url, single_error)
      end

      it 'contains correct compared accessibility report details', :aggregate_failures do
        expect(subject[:status]).to eq(Gitlab::Ci::Reports::AccessibilityReportsComparer::STATUS_FAILED)
        expect(subject[:new_errors]).to be_empty
        expect(subject[:resolved_errors]).to be_empty
        expect(subject[:existing_errors].first).to include(:code, :type, :type_code, :message, :context, :selector, :runner, :runner_extras)
        expect(subject[:summary]).to include(total: 1, resolved: 0, errored: 1)
      end
    end

    context 'when base report has no error and head has errors' do
      before do
        head_report.add_url(url, single_error)
      end

      it 'contains correct compared accessibility report details', :aggregate_failures do
        expect(subject[:status]).to eq(Gitlab::Ci::Reports::AccessibilityReportsComparer::STATUS_FAILED)
        expect(subject[:resolved_errors]).to be_empty
        expect(subject[:existing_errors]).to be_empty
        expect(subject[:new_errors].first).to include(:code, :type, :type_code, :message, :context, :selector, :runner, :runner_extras)
        expect(subject[:summary]).to include(total: 1, resolved: 0, errored: 1)
      end
    end
  end
end
