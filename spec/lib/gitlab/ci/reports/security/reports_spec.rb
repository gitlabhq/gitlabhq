# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::Security::Reports do
  let_it_be(:pipeline) { create(:ci_pipeline) }
  let_it_be(:artifact) { create(:ci_job_artifact, :sast) }

  let(:security_reports) { described_class.new(pipeline) }

  describe '#get_report' do
    subject { security_reports.get_report(report_type, artifact) }

    context 'when report type is sast' do
      let(:report_type) { 'sast' }

      it { expect(subject.type).to eq('sast') }
      it { expect(subject.created_at).to eq(artifact.created_at) }

      it 'initializes a new report and returns it' do
        expect(Gitlab::Ci::Reports::Security::Report).to receive(:new)
          .with('sast', pipeline, artifact.created_at).and_call_original

        is_expected.to be_a(Gitlab::Ci::Reports::Security::Report)
      end

      context 'when report type is already allocated' do
        before do
          subject
        end

        it 'does not initialize a new report' do
          expect(Gitlab::Ci::Reports::Security::Report).not_to receive(:new)

          is_expected.to be_a(Gitlab::Ci::Reports::Security::Report)
        end
      end
    end
  end

  describe '#findings' do
    let(:finding_1) { build(:ci_reports_security_finding, severity: 'low') }
    let(:finding_2) { build(:ci_reports_security_finding, severity: 'high') }
    let!(:expected_findings) { [finding_1, finding_2] }

    subject { security_reports.findings }

    before do
      security_reports.get_report('sast', artifact).add_finding(finding_1)
      security_reports.get_report('dependency_scanning', artifact).add_finding(finding_2)
    end

    it { is_expected.to match_array(expected_findings) }
  end

  describe "#violates_default_policy_against?" do
    let(:high_severity_dast) { build(:ci_reports_security_finding, severity: 'high', report_type: :dast) }
    let(:vulnerabilities_allowed) { 0 }
    let(:severity_levels) { %w(critical high) }

    subject { security_reports.violates_default_policy_against?(target_reports, vulnerabilities_allowed, severity_levels) }

    before do
      security_reports.get_report('sast', artifact).add_finding(high_severity_dast)
    end

    context 'when the target_reports is `nil`' do
      let(:target_reports) { nil }

      context 'with severity levels matching the existing vulnerabilities' do
        it { is_expected.to be(true) }
      end

      context "without any severity levels matching the existing vulnerabilities" do
        let(:severity_levels) { %w(critical) }

        it { is_expected.to be(false) }
      end
    end

    context 'when the target_reports is not `nil`' do
      let(:target_reports) { described_class.new(pipeline) }

      context "when a report has a new unsafe vulnerability" do
        context 'with severity levels matching the existing vulnerabilities' do
          it { is_expected.to be(true) }
        end

        it { is_expected.to be(true) }

        context 'with vulnerabilities_allowed higher than the number of new vulnerabilities' do
          let(:vulnerabilities_allowed) { 10000 }

          it { is_expected.to be(false) }
        end

        context "without any severity levels matching the existing vulnerabilities" do
          let(:severity_levels) { %w(critical) }

          it { is_expected.to be(false) }
        end
      end

      context "when none of the reports have a new unsafe vulnerability" do
        before do
          target_reports.get_report('sast', artifact).add_finding(high_severity_dast)
        end

        it { is_expected.to be(false) }
      end
    end
  end
end
