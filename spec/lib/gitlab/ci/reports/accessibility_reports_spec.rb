# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Reports::AccessibilityReports do
  let(:accessibility_report) { described_class.new }
  let(:url) { 'https://gitlab.com' }
  let(:data) do
    [
      {
        code: "WCAG2AA.Principle4.Guideline4_1.4_1_2.H91.A.NoContent",
        type: "error",
        typeCode: 1,
        message: "Anchor element found with a valid href attribute, but no link content has been supplied.",
        context: %(<a href="/customers/worldline"><svg viewBox="0 0 509 89" xmln...</a>),
        selector: "html > body > div:nth-child(9) > div:nth-child(2) > a:nth-child(17)",
        runner: "htmlcs",
        runnerExtras: {}
      },
      {
        code: "WCAG2AA.Principle4.Guideline4_1.4_1_2.H91.A.NoContent",
        type: "error",
        typeCode: 1,
        message: "Anchor element found with a valid href attribute, but no link content has been supplied.",
        context: %(<a href="/customers/equinix"><svg xmlns="http://www.w3.org/...</a>),
        selector: "html > body > div:nth-child(9) > div:nth-child(2) > a:nth-child(18)",
        runner: "htmlcs",
        runnerExtras: {}
      }
    ]
  end

  describe '#scans_count' do
    subject { accessibility_report.scans_count }

    context 'when data has errors' do
      let(:different_url) { 'https://about.gitlab.com' }

      before do
        accessibility_report.add_url(url, data)
        accessibility_report.add_url(different_url, data)
      end

      it 'returns the scans_count' do
        expect(subject).to eq(2)
      end
    end

    context 'when data has no errors' do
      before do
        accessibility_report.add_url(url, [])
      end

      it 'returns the scans_count' do
        expect(subject).to eq(1)
      end
    end

    context 'when data has no url' do
      before do
        accessibility_report.add_url("", [])
      end

      it 'returns the scans_count' do
        expect(subject).to eq(0)
      end
    end
  end

  describe '#passes_count' do
    subject { accessibility_report.passes_count }

    context 'when data has errors' do
      before do
        accessibility_report.add_url(url, data)
      end

      it 'returns the passes_count' do
        expect(subject).to eq(0)
      end
    end

    context 'when data has no errors' do
      before do
        accessibility_report.add_url(url, [])
      end

      it 'returns the passes_count' do
        expect(subject).to eq(1)
      end
    end

    context 'when data has no url' do
      before do
        accessibility_report.add_url("", [])
      end

      it 'returns the scans_count' do
        expect(subject).to eq(0)
      end
    end
  end

  describe '#errors_count' do
    subject { accessibility_report.errors_count }

    context 'when data has errors' do
      let(:different_url) { 'https://about.gitlab.com' }

      before do
        accessibility_report.add_url(url, data)
        accessibility_report.add_url(different_url, data)
      end

      it 'returns the errors_count' do
        expect(subject).to eq(4)
      end
    end

    context 'when data has no errors' do
      before do
        accessibility_report.add_url(url, [])
      end

      it 'returns the errors_count' do
        expect(subject).to eq(0)
      end
    end

    context 'when data has no url' do
      before do
        accessibility_report.add_url("", [])
      end

      it 'returns the errors_count' do
        expect(subject).to eq(0)
      end
    end
  end

  describe '#add_url' do
    subject { accessibility_report.add_url(url, data) }

    context 'when data has errors' do
      it 'adds urls and data to accessibility report' do
        expect { subject }.not_to raise_error

        expect(accessibility_report.urls.keys).to eq([url])
        expect(accessibility_report.urls.values.flatten.size).to eq(2)
      end
    end

    context 'when data does not have errors' do
      let(:data) { [] }

      it 'adds data to accessibility report' do
        expect { subject }.not_to raise_error

        expect(accessibility_report.urls.keys).to eq([url])
        expect(accessibility_report.urls.values.flatten.size).to eq(0)
      end
    end

    context 'when url does not exist' do
      let(:url) { '' }
      let(:data) { [{ message: "Protocol error (Page.navigate): Cannot navigate to invalid URL" }] }

      it 'sets error_message and decreases total' do
        expect { subject }.not_to raise_error

        expect(accessibility_report.scans_count).to eq(0)
        expect(accessibility_report.error_message).to eq('Empty URL detected in gl-accessibility.json')
      end
    end
  end

  describe '#set_error_message' do
    let(:set_accessibility_error) { accessibility_report.set_error_message('error') }

    context 'when error is nil' do
      it 'returns the error' do
        expect(set_accessibility_error).to eq('error')
      end

      it 'sets the error' do
        set_accessibility_error

        expect(accessibility_report.error_message).to eq('error')
      end
    end

    context 'when a error has already been set' do
      before do
        accessibility_report.set_error_message('old error')
      end

      it 'overwrites the existing message' do
        expect { set_accessibility_error }.to change(accessibility_report, :error_message).from('old error').to('error')
      end
    end
  end

  describe '#all_errors' do
    subject { accessibility_report.all_errors }

    context 'when data has errors' do
      before do
        accessibility_report.add_url(url, data)
      end

      it 'returns all errors' do
        expect(subject.size).to eq(2)
      end
    end

    context 'when data has no errors' do
      before do
        accessibility_report.add_url(url, [])
      end

      it 'returns an empty array' do
        expect(subject).to eq([])
      end
    end

    context 'when accessibility report has no data' do
      it 'returns an empty array' do
        expect(subject).to eq([])
      end
    end
  end
end
