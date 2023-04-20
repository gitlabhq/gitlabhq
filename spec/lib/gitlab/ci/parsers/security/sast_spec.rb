# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Security::Sast do
  using RSpec::Parameterized::TableSyntax

  describe '#parse!' do
    let_it_be(:pipeline) { create(:ci_pipeline) }

    let(:created_at) { 2.weeks.ago }

    context "when passing valid report" do
      # rubocop: disable Layout/LineLength
      where(:report_format, :report_version, :scanner_length, :finding_length, :identifier_length, :file_path, :start_line, :end_line, :primary_identifiers_length) do
        :sast                               | '15.0.0' | 1 | 5  | 6  | 'groovy/src/main/java/com/gitlab/security_products/tests/App.groovy' | 47 | 47  | nil
        :sast_semgrep_for_multiple_findings | '15.0.4' | 1 | 2  | 6  | 'app/app.py'                                                         | 39 | nil | 2
      end
      # rubocop: enable Layout/LineLength

      with_them do
        let(:report) do
          Gitlab::Ci::Reports::Security::Report.new(
            artifact.file_type,
            pipeline,
            created_at
          )
        end

        let(:artifact) { create(:ci_job_artifact, report_format) }

        before do
          artifact.each_blob { |blob| described_class.parse!(blob, report, validate: true) }
        end

        it "parses all identifiers and findings" do
          expect(report.findings.length).to eq(finding_length)
          expect(report.identifiers.length).to eq(identifier_length)
          expect(report.scanners.length).to eq(scanner_length)

          if primary_identifiers_length
            expect(
              report.scanners.each_value.first.primary_identifiers.length
            ).to eq(primary_identifiers_length)
          end
        end

        it 'generates expected location' do
          location = report.findings.first.location

          expect(location).to be_a(::Gitlab::Ci::Reports::Security::Locations::Sast)
          expect(location).to have_attributes(
            file_path: file_path,
            end_line: end_line,
            start_line: start_line
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
