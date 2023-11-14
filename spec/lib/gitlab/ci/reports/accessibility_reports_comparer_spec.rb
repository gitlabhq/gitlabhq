# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Reports::AccessibilityReportsComparer do
  let(:comparer) { described_class.new(base_report, head_report) }
  let(:base_report) { Gitlab::Ci::Reports::AccessibilityReports.new }
  let(:head_report) { Gitlab::Ci::Reports::AccessibilityReports.new }
  let(:url) { "https://gitlab.com" }
  let(:single_error) do
    [
      {
        "code" => "WCAG2AA.Principle4.Guideline4_1.4_1_2.H91.A.NoContent",
        "type" => "error",
        "typeCode" => 1,
        "message" => "Anchor element found with a valid href attribute, but no link content has been supplied.",
        "context" => %(<a href="/" class="navbar-brand animated"><svg height="36" viewBox="0 0 1...</a>),
        "selector" => "#main-nav > div:nth-child(1) > a",
        "runner" => "htmlcs",
        "runnerExtras" => {}
      }
    ]
  end

  let(:different_error) do
    [
      {
        "code" => "WCAG2AA.Principle1.Guideline1_4.1_4_3.G18.Fail",
        "type" => "error",
        "typeCode" => 1,
        "message" => "This element has insufficient contrast at this conformance level.",
        "context" => %(<a href="/stages-devops-lifecycle/" class="main-nav-link">Product</a>),
        "selector" => "#main-nav > div:nth-child(2) > ul > li:nth-child(1) > a",
        "runner" => "htmlcs",
        "runnerExtras" => {}
      }
    ]
  end

  describe '#status' do
    subject(:status) { comparer.status }

    context 'when head report has an error' do
      before do
        head_report.add_url(url, single_error)
      end

      it 'returns status failed' do
        expect(status).to eq(described_class::STATUS_FAILED)
      end
    end

    context 'when head reports does not have errors' do
      before do
        head_report.add_url(url, [])
      end

      it 'returns status success' do
        expect(status).to eq(described_class::STATUS_SUCCESS)
      end
    end
  end

  describe '#errors_count' do
    subject(:errors_count) { comparer.errors_count }

    context 'when head report has an error' do
      before do
        head_report.add_url(url, single_error)
      end

      it 'returns the number of new errors' do
        expect(errors_count).to eq(1)
      end
    end

    context 'when head reports does not have an error' do
      before do
        head_report.add_url(url, [])
      end

      it 'returns the number new errors' do
        expect(errors_count).to eq(0)
      end
    end
  end

  describe '#resolved_count' do
    subject(:resolved_count) { comparer.resolved_count }

    context 'when base reports has an error and head has a different error' do
      before do
        base_report.add_url(url, single_error)
        head_report.add_url(url, different_error)
      end

      it 'returns the resolved count' do
        expect(resolved_count).to eq(1)
      end
    end

    context 'when base reports has errors head has no errors' do
      before do
        base_report.add_url(url, single_error)
        head_report.add_url(url, [])
      end

      it 'returns the resolved count' do
        expect(resolved_count).to eq(1)
      end
    end

    context 'when base reports has errors and head has the same error' do
      before do
        base_report.add_url(url, single_error)
        head_report.add_url(url, single_error)
      end

      it 'returns zero' do
        expect(resolved_count).to eq(0)
      end
    end

    context 'when base reports does not have errors and head has errors' do
      before do
        head_report.add_url(url, single_error)
      end

      it 'returns the number of resolved errors' do
        expect(resolved_count).to eq(0)
      end
    end
  end

  describe '#total_count' do
    subject(:total_count) { comparer.total_count }

    context 'when base reports has an error' do
      before do
        base_report.add_url(url, single_error)
      end

      it 'returns zero' do
        expect(total_count).to be_zero
      end
    end

    context 'when head report has an error' do
      before do
        head_report.add_url(url, single_error)
      end

      it 'returns the total count' do
        expect(total_count).to eq(1)
      end
    end

    context 'when base report has errors and head report has errors' do
      before do
        base_report.add_url(url, single_error)
        head_report.add_url(url, different_error)
      end

      it 'returns the total count' do
        expect(total_count).to eq(1)
      end
    end

    context 'when base report has errors and head report has the same error' do
      before do
        base_report.add_url(url, single_error)
        head_report.add_url(url, single_error + different_error)
      end

      it 'returns the total count' do
        expect(total_count).to eq(2)
      end
    end
  end

  describe '#existing_errors' do
    subject(:existing_errors) { comparer.existing_errors }

    context 'when base report has errors and head has a different error' do
      before do
        base_report.add_url(url, single_error)
        head_report.add_url(url, different_error)
      end

      it 'returns an empty array' do
        expect(existing_errors).to be_empty
      end
    end

    context 'when base report does not have errors and head has errors' do
      before do
        base_report.add_url(url, [])
        head_report.add_url(url, single_error)
      end

      it 'returns an empty array' do
        expect(existing_errors).to be_empty
      end
    end

    context 'when base report has errors and head report has the same error' do
      before do
        base_report.add_url(url, single_error)
        head_report.add_url(url, single_error + different_error)
      end

      it 'returns the existing error' do
        expect(existing_errors).to eq(single_error)
      end
    end
  end

  describe '#new_errors' do
    subject(:new_errors) { comparer.new_errors }

    context 'when base reports has errors and head has more errors' do
      before do
        base_report.add_url(url, single_error)
        head_report.add_url(url, single_error + different_error)
      end

      it 'returns new errors between base and head reports' do
        expect(new_errors.size).to eq(1)
        expect(new_errors.first["code"]).to eq("WCAG2AA.Principle1.Guideline1_4.1_4_3.G18.Fail")
      end
    end

    context 'when base reports has an error and head has no errors' do
      before do
        base_report.add_url(url, single_error)
        head_report.add_url(url, [])
      end

      it 'returns an empty array' do
        expect(new_errors).to be_empty
      end
    end

    context 'when base reports does not have errors and head has errors' do
      before do
        head_report.add_url(url, single_error)
      end

      it 'returns the new error' do
        expect(new_errors.size).to eq(1)
        expect(new_errors.first["code"]).to eq("WCAG2AA.Principle4.Guideline4_1.4_1_2.H91.A.NoContent")
      end
    end
  end

  describe '#resolved_errors' do
    subject(:resolved_errors) { comparer.resolved_errors }

    context 'when base report has errors and head has more errors' do
      before do
        base_report.add_url(url, single_error)
        head_report.add_url(url, single_error + different_error)
      end

      it 'returns an empty array' do
        expect(resolved_errors).to be_empty
      end
    end

    context 'when base reports has errors and head has a different error' do
      before do
        base_report.add_url(url, single_error)
        head_report.add_url(url, different_error)
      end

      it 'returns the resolved errors' do
        expect(resolved_errors.size).to eq(1)
        expect(resolved_errors.first["code"]).to eq("WCAG2AA.Principle4.Guideline4_1.4_1_2.H91.A.NoContent")
      end
    end

    context 'when base reports does not have errors and head has errors' do
      before do
        head_report.add_url(url, single_error)
      end

      it 'returns an empty array' do
        expect(resolved_errors).to be_empty
      end
    end
  end
end
