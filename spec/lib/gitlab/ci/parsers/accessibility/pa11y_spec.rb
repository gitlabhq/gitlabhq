# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Accessibility::Pa11y do
  describe '#parse!' do
    subject { described_class.new.parse!(pa11y, accessibility_report) }

    let(:accessibility_report) { Gitlab::Ci::Reports::AccessibilityReports.new }

    context "when data is pa11y style JSON" do
      context "when there are no URLs provided" do
        let(:pa11y) do
          {
            total: 1,
            passes: 0,
            errors: 0,
            results: {
              "": [
                {
                  message: "Protocol error (Page.navigate): Cannot navigate to invalid URL"
                }
              ]
            }
          }.to_json
        end

        it "returns an accessibility report" do
          expect { subject }.not_to raise_error

          expect(accessibility_report.errors_count).to eq(0)
          expect(accessibility_report.passes_count).to eq(0)
          expect(accessibility_report.scans_count).to eq(0)
          expect(accessibility_report.urls).to be_empty
          expect(accessibility_report.error_message).to eq("Empty URL detected in gl-accessibility.json")
        end
      end

      context "when there are no errors" do
        let(:pa11y) do
          {
            total: 1,
            passes: 1,
            errors: 0,
            results: {
              "http://pa11y.org/": []
            }
          }.to_json
        end

        it "returns an accessibility report" do
          expect { subject }.not_to raise_error

          expect(accessibility_report.urls['http://pa11y.org/']).to be_empty
          expect(accessibility_report.errors_count).to eq(0)
          expect(accessibility_report.passes_count).to eq(1)
          expect(accessibility_report.scans_count).to eq(1)
        end
      end

      context "when there are errors" do
        let(:pa11y) do
          {
            total: 1,
            passes: 0,
            errors: 1,
            results: {
              "https://about.gitlab.com/": [
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
            }
          }.to_json
        end

        it "returns an accessibility report" do
          expect { subject }.not_to raise_error

          expect(accessibility_report.errors_count).to eq(1)
          expect(accessibility_report.passes_count).to eq(0)
          expect(accessibility_report.scans_count).to eq(1)
          expect(accessibility_report.urls['https://about.gitlab.com/']).to be_present
          expect(accessibility_report.urls['https://about.gitlab.com/'].first[:code]).to be_present
        end
      end
    end

    context "when data is not a valid JSON string" do
      let(:pa11y) do
        {
          total: 1,
          passes: 1,
          errors: 0,
          results: {
            "http://pa11y.org/": []
          }
        }
      end

      it "sets error_message" do
        expect { subject }.not_to raise_error

        expect(accessibility_report.error_message).to include('JSON parsing failed')
        expect(accessibility_report.errors_count).to eq(0)
        expect(accessibility_report.passes_count).to eq(0)
        expect(accessibility_report.scans_count).to eq(0)
      end
    end
  end
end
