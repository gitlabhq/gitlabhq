# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Security::Sast do
  using RSpec::Parameterized::TableSyntax

  describe '#parse!' do
    let_it_be(:pipeline) { create(:ci_pipeline) }

    let(:created_at) { 2.weeks.ago }

    context "when parsing valid reports" do
      where(:report_format, :report_version, :scanner_length, :finding_length, :identifier_length, :file_path, :line) do
        :sast               | '14.0.0' | 1 | 5  | 6  | 'groovy/src/main/java/com/gitlab/security_products/tests/App.groovy' | 47
        :sast_deprecated    | '1.2'    | 3 | 33 | 17 | 'python/hardcoded/hardcoded-tmp.py'                                  | 1
      end

      with_them do
        let(:report) { Gitlab::Ci::Reports::Security::Report.new(artifact.file_type, pipeline, created_at) }
        let(:artifact) { create(:ci_job_artifact, report_format) }

        before do
          artifact.each_blob { |blob| described_class.parse!(blob, report) }
        end

        it "parses all identifiers and findings" do
          expect(report.findings.length).to eq(finding_length)
          expect(report.identifiers.length).to eq(identifier_length)
          expect(report.scanners.length).to eq(scanner_length)
        end

        it 'generates expected location' do
          location = report.findings.first.location

          expect(location).to be_a(::Gitlab::Ci::Reports::Security::Locations::Sast)
          expect(location).to have_attributes(
            file_path: file_path,
            end_line: line,
            start_line: line
          )
        end

        it "generates expected metadata_version" do
          expect(report.findings.first.metadata_version).to eq(report_version)
        end
      end
    end

    context "when parsing an empty report" do
      let(:report) { Gitlab::Ci::Reports::Security::Report.new('sast', pipeline, created_at) }
      let(:blob) { Gitlab::Json.generate({}) }

      it { expect(described_class.parse!(blob, report)).to be_empty }
    end
  end
end
