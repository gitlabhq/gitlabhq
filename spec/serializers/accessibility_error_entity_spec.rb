# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AccessibilityErrorEntity do
  let(:entity) { described_class.new(accessibility_error) }

  describe '#as_json' do
    subject { entity.as_json }

    context 'when accessibility contains an error' do
      let(:accessibility_error) do
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
      end

      it 'contains correct accessibility error details', :aggregate_failures do
        expect(subject[:code]).to eq("WCAG2AA.Principle4.Guideline4_1.4_1_2.H91.A.NoContent")
        expect(subject[:type]).to eq("error")
        expect(subject[:type_code]).to eq(1)
        expect(subject[:message]).to eq("Anchor element found with a valid href attribute, but no link content has been supplied.")
        expect(subject[:context]).to eq("<a href=\"/\" class=\"navbar-brand animated\"><svg height=\"36\" viewBox=\"0 0 1...</a>")
        expect(subject[:selector]).to eq("#main-nav > div:nth-child(1) > a")
        expect(subject[:runner]).to eq("htmlcs")
        expect(subject[:runner_extras]).to be_empty
      end
    end
  end
end
