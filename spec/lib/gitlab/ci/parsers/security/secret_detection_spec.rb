# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Security::SecretDetection do
  describe '#parse!' do
    let_it_be(:pipeline) { create(:ci_pipeline) }

    let(:created_at) { 2.weeks.ago }

    context "when parsing valid reports" do
      where(report_format: %i[secret_detection])

      with_them do
        let(:report) { Gitlab::Ci::Reports::Security::Report.new(artifact.file_type, pipeline, created_at) }
        let(:artifact) { create(:ci_job_artifact, report_format) }

        before do
          artifact.each_blob { |blob| described_class.parse!(blob, report) }
        end

        it "parses all identifiers and findings" do
          expect(report.findings.length).to eq(1)
          expect(report.identifiers.length).to eq(1)
          expect(report.scanners.length).to eq(1)
        end

        it 'generates expected location' do
          location = report.findings.first.location

          expect(location).to be_a(::Gitlab::Ci::Reports::Security::Locations::SecretDetection)
          expect(location).to have_attributes(
            file_path: 'aws-key.py',
            start_line: nil,
            end_line: nil,
            class_name: nil,
            method_name: nil
          )
        end

        it "generates expected metadata_version" do
          expect(report.findings.first.metadata_version).to eq('15.0.0')
        end
      end
    end

    context "when parsing an empty report" do
      let(:report) { Gitlab::Ci::Reports::Security::Report.new('secret_detection', pipeline, created_at) }
      let(:blob) { Gitlab::Json.generate({}) }

      it { expect(described_class.parse!(blob, report)).to be_empty }
    end
  end
end
