# frozen_string_literal: true

require 'spec_helper'

# rubocop: disable RSpec/MultipleMemoizedHelpers
RSpec.describe Security::MergeReportsService, '#execute', feature_category: :code_review_workflow do
  let(:scanner_1) { build(:ci_reports_security_scanner, external_id: 'scanner-1', name: 'Scanner 1') }
  let(:scanner_2) { build(:ci_reports_security_scanner, external_id: 'scanner-2', name: 'Scanner 2') }
  let(:scanner_3) { build(:ci_reports_security_scanner, external_id: 'scanner-3', name: 'Scanner 3') }

  let(:identifier_1_primary) { build(:ci_reports_security_identifier, external_id: 'VULN-1', external_type: 'scanner-1') }
  let(:identifier_1_cve) { build(:ci_reports_security_identifier, external_id: 'CVE-2019-123', external_type: 'cve') }
  let(:identifier_2_primary) { build(:ci_reports_security_identifier, external_id: 'VULN-2', external_type: 'scanner-2') }
  let(:identifier_2_cve) { build(:ci_reports_security_identifier, external_id: 'CVE-2019-456', external_type: 'cve') }
  let(:identifier_cwe) { build(:ci_reports_security_identifier, external_id: '789', external_type: 'cwe') }
  let(:identifier_wasc) { build(:ci_reports_security_identifier, external_id: '13', external_type: 'wasc') }

  let(:finding_id_1) do
    build(
      :ci_reports_security_finding,
      identifiers: [identifier_1_primary, identifier_1_cve],
      scanner: scanner_1,
      severity: :low,
      uuid: '61eb8e3e-3be1-4d6c-ba26-4e0dd4f94610'
    )
  end

  let(:finding_id_1_extra) do
    build(
      :ci_reports_security_finding,
      identifiers: [identifier_1_primary, identifier_1_cve],
      scanner: scanner_1,
      severity: :low,
      uuid: '61eb8e3e-3be1-4d6c-ba26-4e0dd4f94611'
    )
  end

  let(:finding_id_2_loc_1) do
    build(
      :ci_reports_security_finding,
      identifiers: [identifier_2_primary, identifier_2_cve],
      location: build(:ci_reports_security_locations_sast, start_line: 32, end_line: 34),
      scanner: scanner_2,
      severity: :medium,
      uuid: '61eb8e3e-3be1-4d6c-ba26-4e0dd4f94614'
    )
  end

  let(:finding_id_2_loc_1_extra) do
    build(
      :ci_reports_security_finding,
      identifiers: [identifier_2_primary, identifier_2_cve],
      location: build(:ci_reports_security_locations_sast, start_line: 32, end_line: 34),
      scanner: scanner_2,
      severity: :medium,
      uuid: '61eb8e3e-3be1-4d6c-ba26-4e0dd4f94613'
    )
  end

  let(:finding_id_2_loc_2) do
    build(
      :ci_reports_security_finding,
      identifiers: [identifier_2_primary, identifier_2_cve],
      location: build(:ci_reports_security_locations_sast, start_line: 42, end_line: 44),
      scanner: scanner_2,
      severity: :medium,
      uuid: '61eb8e3e-3be1-4d6c-ba26-4e0dd4f94612'
    )
  end

  let(:finding_cwe_1) do
    build(
      :ci_reports_security_finding,
      identifiers: [identifier_cwe],
      scanner: scanner_3,
      severity: :high,
      uuid: '61eb8e3e-3be1-4d6c-ba26-4e0dd4f94615'
    )
  end

  let(:finding_cwe_2) do
    build(
      :ci_reports_security_finding,
      identifiers: [identifier_cwe],
      scanner: scanner_1,
      severity: :critical,
      uuid: '61eb8e3e-3be1-4d6c-ba26-4e0dd4f94616'
    )
  end

  let(:finding_wasc_1) do
    build(
      :ci_reports_security_finding,
      identifiers: [identifier_wasc],
      scanner: scanner_1,
      severity: :medium,
      uuid: '61eb8e3e-3be1-4d6c-ba26-4e0dd4f94617'
    )
  end

  let(:finding_wasc_2) do
    build(
      :ci_reports_security_finding,
      identifiers: [identifier_wasc],
      scanner: scanner_2,
      severity: :critical,
      uuid: '61eb8e3e-3be1-4d6c-ba26-4e0dd4f94618'
    )
  end

  let(:report_1_findings) { [finding_id_1, finding_id_2_loc_1, finding_id_2_loc_1_extra, finding_cwe_2, finding_wasc_1] }

  let(:scanned_resource) do
    ::Gitlab::Ci::Reports::Security::ScannedResource.new(URI.parse('example.com'), 'GET')
  end

  let(:scanned_resource_1) do
    ::Gitlab::Ci::Reports::Security::ScannedResource.new(URI.parse('example.com'), 'POST')
  end

  let(:scanned_resource_2) do
    ::Gitlab::Ci::Reports::Security::ScannedResource.new(URI.parse('example.com/2'), 'GET')
  end

  let(:scanned_resource_3) do
    ::Gitlab::Ci::Reports::Security::ScannedResource.new(URI.parse('example.com/3'), 'GET')
  end

  let(:report_1) do
    build(
      :ci_reports_security_report,
      scanners: [scanner_1, scanner_2],
      findings: report_1_findings,
      identifiers: report_1_findings.flat_map(&:identifiers),
      scanned_resources: [scanned_resource, scanned_resource_1, scanned_resource_2]
    )
  end

  let(:report_2_findings) { [finding_id_2_loc_2, finding_wasc_2] }

  let(:report_2) do
    build(
      :ci_reports_security_report,
      scanners: [scanner_2],
      findings: report_2_findings,
      identifiers: finding_id_2_loc_2.identifiers,
      scanned_resources: [scanned_resource, scanned_resource_1, scanned_resource_3]
    )
  end

  let(:report_3_findings) { [finding_id_1_extra, finding_cwe_1] }

  let(:report_3) do
    build(
      :ci_reports_security_report,
      scanners: [scanner_1, scanner_3],
      findings: report_3_findings,
      identifiers: report_3_findings.flat_map(&:identifiers)
    )
  end

  let(:merge_service) { described_class.new(report_1, report_2, report_3) }

  subject(:merged_report) { merge_service.execute }

  describe 'errors on target report' do
    subject { merged_report.errors }

    before do
      report_1.add_error('foo', 'bar')
      report_2.add_error('zoo', 'baz')
    end

    it { is_expected.to match_array([{ type: 'foo', message: 'bar' }, { type: 'zoo', message: 'baz' }]) }
  end

  describe 'warnings on target report' do
    subject { merged_report.warnings }

    before do
      report_1.add_warning('foo', 'bar')
      report_2.add_warning('zoo', 'baz')
    end

    it { is_expected.to match_array([{ type: 'foo', message: 'bar' }, { type: 'zoo', message: 'baz' }]) }
  end

  it 'copies scanners into target report and eliminates duplicates' do
    expect(merged_report.scanners.values).to contain_exactly(scanner_1, scanner_2, scanner_3)
  end

  it 'copies identifiers into target report and eliminates duplicates' do
    expect(merged_report.identifiers.values).to(
      contain_exactly(
        identifier_1_primary,
        identifier_1_cve,
        identifier_2_primary,
        identifier_2_cve,
        identifier_cwe,
        identifier_wasc
      )
    )
  end

  it 'deduplicates (except cwe and wasc) and sorts the vulnerabilities by severity (desc) then by compare key' do
    expect(merged_report.findings).to(
      eq([
        finding_cwe_2,
        finding_wasc_2,
        finding_cwe_1,
        finding_id_2_loc_2,
        finding_id_2_loc_1,
        finding_wasc_1,
        finding_id_1
      ])
    )
  end

  it 'deduplicates scanned resources' do
    expect(merged_report.scanned_resources).to(
      eq([
        scanned_resource,
        scanned_resource_1,
        scanned_resource_2,
        scanned_resource_3
      ])
    )
  end

  context 'ordering reports for sast analyzers' do
    let(:bandit_scanner) { build(:ci_reports_security_scanner, external_id: 'bandit', name: 'Bandit') }
    let(:semgrep_scanner) { build(:ci_reports_security_scanner, external_id: 'semgrep', name: 'Semgrep') }

    let(:identifier_bandit) { build(:ci_reports_security_identifier, external_id: 'B403', external_type: 'bandit_test_id') }
    let(:identifier_cve) { build(:ci_reports_security_identifier, external_id: 'CVE-2019-123', external_type: 'cve') }
    let(:identifier_semgrep) { build(:ci_reports_security_identifier, external_id: 'rules.bandit.B105', external_type: 'semgrep_id') }

    let(:finding_id_1) do
      build(
        :ci_reports_security_finding,
        identifiers: [identifier_bandit, identifier_cve],
        scanner: bandit_scanner,
        report_type: :sast,
        uuid: '21ab978a-7052-5428-af0b-c7a4b3fe5020')
    end

    let(:finding_id_2) do
      build(
        :ci_reports_security_finding,
        identifiers: [identifier_cve],
        scanner: semgrep_scanner,
        report_type: :sast,
        uuid: '21ab978a-7052-5428-af0b-c7a4b3fe5021')
    end

    let(:finding_id_3) do
      build(
        :ci_reports_security_finding,
        identifiers: [identifier_semgrep],
        scanner: semgrep_scanner,
        report_type: :sast,
        uuid: '21ab978a-7052-5428-af0b-c7a4b3fe5022')
    end

    let(:bandit_report) do
      build(:ci_reports_security_report,
        type: :sast,
        scanners: [bandit_scanner],
        findings: [finding_id_1],
        identifiers: finding_id_1.identifiers
      )
    end

    let(:semgrep_report) do
      build(
        :ci_reports_security_report,
        type: :sast,
        scanners: [semgrep_scanner],
        findings: [finding_id_2, finding_id_3],
        identifiers: finding_id_2.identifiers + finding_id_3.identifiers
      )
    end

    let(:custom_analyzer_report) do
      build(
        :ci_reports_security_report,
        type: :sast,
        scanners: [scanner_2],
        findings: [finding_id_2_loc_1],
        identifiers: finding_id_2_loc_1.identifiers
      )
    end

    context 'when reports are gathered in an unprioritized order' do
      subject(:sast_merged_report) { described_class.new(semgrep_report, bandit_report).execute }

      specify { expect(sast_merged_report.scanners.values).to eql([bandit_scanner, semgrep_scanner]) }
      specify { expect(sast_merged_report.findings.count).to eq(2) }
      specify { expect(sast_merged_report.findings.first.identifiers).to eql([identifier_bandit, identifier_cve]) }
      specify { expect(sast_merged_report.findings.last.identifiers).to contain_exactly(identifier_semgrep) }
    end

    context 'when a custom analyzer is completed before the known analyzers' do
      subject(:sast_merged_report) { described_class.new(custom_analyzer_report, semgrep_report, bandit_report).execute }

      specify { expect(sast_merged_report.scanners.values).to eql([bandit_scanner, semgrep_scanner, scanner_2]) }
      specify { expect(sast_merged_report.findings.count).to eq(3) }
      specify { expect(sast_merged_report.findings.last.identifiers).to match_array(finding_id_2_loc_1.identifiers) }
    end
  end
end
# rubocop: enable RSpec/MultipleMemoizedHelpers
