# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Reports::AccessibilityReports do
  let(:accessibility_report) { described_class.new }

  describe '#add_url' do
    subject { accessibility_report.add_url(url, data) }

    context 'when data has errors' do
      let(:url) { 'https://gitlab.com' }
      let(:data) do
        [
          {
            "code": "WCAG2AA.Principle4.Guideline4_1.4_1_2.H91.A.NoContent",
            "type": "error",
            "typeCode": 1,
            "message": "Anchor element found with a valid href attribute, but no link content has been supplied.",
            "context": "<a href=\"/customers/worldline\">\n<svg viewBox=\"0 0 509 89\" xmln...</a>",
            "selector": "html > body > div:nth-child(9) > div:nth-child(2) > a:nth-child(17)",
            "runner": "htmlcs",
            "runnerExtras": {}
          },
          {
            "code": "WCAG2AA.Principle4.Guideline4_1.4_1_2.H91.A.NoContent",
            "type": "error",
            "typeCode": 1,
            "message": "Anchor element found with a valid href attribute, but no link content has been supplied.",
            "context": "<a href=\"/customers/equinix\">\n<svg xmlns=\"http://www.w3.org/...</a>",
            "selector": "html > body > div:nth-child(9) > div:nth-child(2) > a:nth-child(18)",
            "runner": "htmlcs",
            "runnerExtras": {}
          }
        ]
      end

      it 'adds urls and data to accessibility report' do
        expect { subject }.not_to raise_error

        expect(accessibility_report.urls.keys).to eq([url])
        expect(accessibility_report.urls.values.flatten.size).to eq(2)
      end
    end

    context 'when data does not have errors' do
      let(:url) { 'https://gitlab.com' }
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

      it 'do not add data to accessibility report' do
        expect { subject }.not_to raise_error

        expect(accessibility_report.urls).to be_empty
      end
    end
  end
end
