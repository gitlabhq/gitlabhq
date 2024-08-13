# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Coverage::Documents::JacocoDocument,
  feature_category: :code_testing do
  subject(:parse_report) do
    Nokogiri::XML::SAX::Parser.new(described_class.new(coverage_report,
      modified_files)).parse(xml)
  end

  describe '#parse!' do
    let(:coverage_report) { Gitlab::Ci::Reports::CoverageReport.new }
    let(:modified_files) { %w[src/main/org/acme/AnotherResource.java src/main/org/acme/ExampleResource.java] }
    let(:project_path) { 'root/someproject' }
    let(:xml) { fixture_file_upload(Rails.root.join('spec/fixtures/jacoco/coverage.xml'), 'text/xml') }

    it 'parses the file' do
      parse_report

      expect(coverage_report.files).to match({
        "src/main/org/acme/AnotherResource.java" => { 9 => 0, 14 => 0 },
        "src/main/org/acme/ExampleResource.java" => { 9 => 3, 14 => 2 }
      })
    end

    context 'when the report format is invalid' do
      context 'when the xml syntax is invalid' do
        let(:xml) do
          fixture_file_upload(Rails.root.join('spec/fixtures/jacoco/coverage-invalid-format.xml'), 'text/xml')
        end

        it 'returns an error' do
          expect { parse_report }.to raise_error(Gitlab::Ci::Parsers::Coverage::Jacoco::InvalidXMLError)
        end
      end

      context 'when the line does not contain the required info' do
        let(:xml) { fixture_file_upload(Rails.root.join('spec/fixtures/jacoco/coverage-no-line-info.xml'), 'text/xml') }

        it 'returns an error' do
          expect { parse_report }.to raise_error(Gitlab::Ci::Parsers::Coverage::Jacoco::InvalidLineInformationError)
        end
      end
    end

    context 'when the merge request paths do not exist' do
      let(:modified_files) { %w[src/test/org/acme/ExampleResource.java] }

      it 'returns an error' do
        expect(Gitlab::AppLogger).to receive(:info).twice

        parse_report
      end
    end
  end
end
