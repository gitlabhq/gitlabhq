# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Reports::AccessibilityReportsComparer do
  let(:comparer) { described_class.new(base_reports, head_reports) }
  let(:base_reports) { Gitlab::Ci::Reports::AccessibilityReports.new }
  let(:head_reports) { Gitlab::Ci::Reports::AccessibilityReports.new }
  let(:url) { "https://gitlab.com" }
  let(:single_error) do
    [
      {
        "code" => "WCAG2AA.Principle4.Guideline4_1.4_1_2.H91.A.NoContent",
        "type" => "error",
        "typeCode" => 1,
        "message" => "Anchor element found with a valid href attribute, but no link content has been supplied.",
        "context" => %{<a href="/" class="navbar-brand animated"><svg height="36" viewBox="0 0 1...</a>},
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
        "context" => %{<a href="/stages-devops-lifecycle/" class="main-nav-link">Product</a>},
        "selector" => "#main-nav > div:nth-child(2) > ul > li:nth-child(1) > a",
        "runner" => "htmlcs",
        "runnerExtras" => {}
      }
    ]
  end

  describe '#status' do
    subject { comparer.status }

    context 'when head report has an error' do
      before do
        head_reports.add_url(url, single_error)
      end

      it 'returns status failed' do
        expect(subject).to eq(described_class::STATUS_FAILED)
      end
    end

    context 'when head reports does not have errors' do
      before do
        head_reports.add_url(url, [])
      end

      it 'returns status success' do
        expect(subject).to eq(described_class::STATUS_SUCCESS)
      end
    end
  end

  describe '#errors_count' do
    subject { comparer.errors_count }

    context 'when head report has an error' do
      before do
        head_reports.add_url(url, single_error)
      end

      it 'returns the number of new errors' do
        expect(subject).to eq(1)
      end
    end

    context 'when head reports does not have an error' do
      before do
        head_reports.add_url(url, [])
      end

      it 'returns the number new errors' do
        expect(subject).to eq(0)
      end
    end
  end

  describe '#resolved_count' do
    subject { comparer.resolved_count }

    context 'when base reports has an error and head has a different error' do
      before do
        base_reports.add_url(url, single_error)
        head_reports.add_url(url, different_error)
      end

      it 'returns the resolved count' do
        expect(subject).to eq(1)
      end
    end

    context 'when base reports has errors head has no errors' do
      before do
        base_reports.add_url(url, single_error)
        head_reports.add_url(url, [])
      end

      it 'returns the resolved count' do
        expect(subject).to eq(1)
      end
    end

    context 'when base reports has errors and head has the same error' do
      before do
        base_reports.add_url(url, single_error)
        head_reports.add_url(url, single_error)
      end

      it 'returns zero' do
        expect(subject).to eq(0)
      end
    end

    context 'when base reports does not have errors and head has errors' do
      before do
        head_reports.add_url(url, single_error)
      end

      it 'returns the number of resolved errors' do
        expect(subject).to eq(0)
      end
    end
  end

  describe '#total_count' do
    subject { comparer.total_count }

    context 'when base reports has an error' do
      before do
        base_reports.add_url(url, single_error)
      end

      it 'returns the error count' do
        expect(subject).to eq(1)
      end
    end

    context 'when head report has an error' do
      before do
        head_reports.add_url(url, single_error)
      end

      it 'returns the error count' do
        expect(subject).to eq(1)
      end
    end

    context 'when base report has errors and head report has errors' do
      before do
        base_reports.add_url(url, single_error)
        head_reports.add_url(url, different_error)
      end

      it 'returns the error count' do
        expect(subject).to eq(2)
      end
    end
  end

  describe '#existing_errors' do
    subject { comparer.existing_errors }

    context 'when base report has errors and head has a different error' do
      before do
        base_reports.add_url(url, single_error)
        head_reports.add_url(url, different_error)
      end

      it 'returns the existing errors' do
        expect(subject.size).to eq(1)
        expect(subject.first["code"]).to eq("WCAG2AA.Principle4.Guideline4_1.4_1_2.H91.A.NoContent")
      end
    end

    context 'when base report does not have errors and head has errors' do
      before do
        base_reports.add_url(url, [])
        head_reports.add_url(url, single_error)
      end

      it 'returns an empty array' do
        expect(subject).to be_empty
      end
    end
  end

  describe '#new_errors' do
    subject { comparer.new_errors }

    context 'when base reports has errors and head has more errors' do
      before do
        base_reports.add_url(url, single_error)
        head_reports.add_url(url, single_error + different_error)
      end

      it 'returns new errors between base and head reports' do
        expect(subject.size).to eq(1)
        expect(subject.first["code"]).to eq("WCAG2AA.Principle1.Guideline1_4.1_4_3.G18.Fail")
      end
    end

    context 'when base reports has an error and head has no errors' do
      before do
        base_reports.add_url(url, single_error)
        head_reports.add_url(url, [])
      end

      it 'returns an empty array' do
        expect(subject).to be_empty
      end
    end

    context 'when base reports does not have errors and head has errors' do
      before do
        head_reports.add_url(url, single_error)
      end

      it 'returns the new error' do
        expect(subject.size).to eq(1)
        expect(subject.first["code"]).to eq("WCAG2AA.Principle4.Guideline4_1.4_1_2.H91.A.NoContent")
      end
    end
  end

  describe '#resolved_errors' do
    subject { comparer.resolved_errors }

    context 'when base report has errors and head has more errors' do
      before do
        base_reports.add_url(url, single_error)
        head_reports.add_url(url, single_error + different_error)
      end

      it 'returns an empty array' do
        expect(subject).to be_empty
      end
    end

    context 'when base reports has errors and head has a different error' do
      before do
        base_reports.add_url(url, single_error)
        head_reports.add_url(url, different_error)
      end

      it 'returns the resolved errors' do
        expect(subject.size).to eq(1)
        expect(subject.first["code"]).to eq("WCAG2AA.Principle4.Guideline4_1.4_1_2.H91.A.NoContent")
      end
    end

    context 'when base reports does not have errors and head has errors' do
      before do
        head_reports.add_url(url, single_error)
      end

      it 'returns an empty array' do
        expect(subject).to be_empty
      end
    end
  end
end
