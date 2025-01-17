# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::SecurityScanSlis, feature_category: :vulnerability_management do
  let(:security_parser_class) do
    stub_const 'Gitlab::Ci::Parsers::Security::Sast', Class.new
  end

  let(:other_parser_class) do
    stub_const 'Gitlab::Ci::Parsers::Foo::Bar', Class.new
  end

  describe '.initialize_slis!' do
    before do
      allow(Gitlab::Ci::Parsers).to receive(:parsers).and_return(
        {
          sast: security_parser_class,
          bar: other_parser_class
        }
      )
    end

    it "initializes the error rate SLI" do
      labels = Enums::Vulnerability.report_type_feature_categories.map do |scan_type, feature_category|
        { scan_type: scan_type, feature_category: feature_category }
      end

      expect(Gitlab::Metrics::Sli::ErrorRate).to receive(:initialize_sli).with(:security_scan, labels)

      described_class.initialize_slis!
    end
  end

  describe '.error_rate' do
    it 'calls increment on security_scan metric' do
      expect(Gitlab::Metrics::Sli::ErrorRate[:security_scan]).to receive(:increment).once

      described_class.error_rate.increment(error: true, labels: {})
    end
  end
end
