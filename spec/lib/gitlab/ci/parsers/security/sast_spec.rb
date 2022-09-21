# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Security::Sast do
  using RSpec::Parameterized::TableSyntax

  describe '#parse!' do
    let_it_be(:pipeline) { create(:ci_pipeline) }

    let(:created_at) { 2.weeks.ago }

    context "when passing valid report" do
      where(:report_format, :report_version, :scanner_length, :finding_length, :identifier_length, :file_path, :line) do
        :sast | '14.0.0' | 1 | 5 | 6 | 'groovy/src/main/java/com/gitlab/security_products/tests/App.groovy' | 47
      end

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

    # This spec is KIND OF MAGIC
    # sast_deprecated trait uses spec/fixtures/security_reports/deprecated/gl-sast-report.json
    # if you take a look at it then it does not conform to the schema at all, yet it somehow passes.
    # The reason for this is because lib/gitlab/ci/parsers/security/sast.rb
    # includes lib/gitlab/ci/parsers/security/concerns/deprecated_syntax.rb
    # which modifies the report data in place and puts the version there
    #
    # TODO: Do not allow modifying input to the parser https://gitlab.com/gitlab-org/gitlab/-/issues/373177
    context "when parsing unsupported report" do
      where(:report_format, :report_version) do
        :sast_deprecated | '1.2'
      end

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
          artifact.each_blob { |blob| described_class.parse!(blob, report, validate: validate) }
        end

        context 'when validation is disabled' do
          let(:validate) { false }

          it "generates no errors" do
            expect(report.errors.size).to eq(0)
          end
        end

        context 'when validation is enabled' do
          let(:validate) { true }

          it "generates errors" do
            messages = report.errors.map { |e| e[:message] }.sort
            first_error = /^Version #{report_version} for report type sast is unsupported.*/
            second_error = %r{^property '/version' does not match.*}

            # One for missing version, one for missing required keys
            expect(report.errors.size).to eq(2)
            expect(messages.first).to match(first_error)
            expect(messages.last).to match(second_error)
          end
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
