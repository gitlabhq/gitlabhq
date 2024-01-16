# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::Security::Report, feature_category: :vulnerability_management do
  let_it_be(:pipeline) { create(:ci_pipeline) }

  let(:created_at) { 2.weeks.ago }

  subject(:report) { described_class.new('sast', pipeline, created_at) }

  it { expect(report.type).to eq('sast') }
  it { is_expected.to delegate_method(:project_id).to(:pipeline) }

  describe '#add_scanner' do
    let(:scanner) { create(:ci_reports_security_scanner, external_id: 'find_sec_bugs') }

    subject { report.add_scanner(scanner) }

    it 'stores given scanner params in the map' do
      subject

      expect(report.scanners).to eq({ 'find_sec_bugs' => scanner })
    end

    it 'returns the added scanner' do
      expect(subject).to eq(scanner)
    end
  end

  describe '#add_identifier' do
    let(:identifier) { create(:ci_reports_security_identifier) }

    subject { report.add_identifier(identifier) }

    it 'stores given identifier params in the map' do
      subject

      expect(report.identifiers).to eq({ identifier.fingerprint => identifier })
    end

    it 'returns the added identifier' do
      expect(subject).to eq(identifier)
    end
  end

  describe '#add_finding' do
    let(:finding) { create(:ci_reports_security_finding) }

    it 'enriches given finding and stores it in the collection' do
      report.add_finding(finding)

      expect(report.findings).to eq([finding])
    end
  end

  describe '#clone_as_blank' do
    let(:report) do
      create(
        :ci_reports_security_report,
        findings: [create(:ci_reports_security_finding)],
        scanners: [create(:ci_reports_security_scanner)],
        identifiers: [create(:ci_reports_security_identifier)]
      )
    end

    it 'creates a blank report with copied type and pipeline' do
      clone = report.clone_as_blank

      expect(clone.type).to eq(report.type)
      expect(clone.pipeline).to eq(report.pipeline)
      expect(clone.created_at).to eq(report.created_at)
      expect(clone.findings).to eq([])
      expect(clone.scanners).to eq({})
      expect(clone.identifiers).to eq({})
    end
  end

  describe '#replace_with!' do
    let(:report) do
      create(
        :ci_reports_security_report,
        findings: [create(:ci_reports_security_finding)],
        scanners: [create(:ci_reports_security_scanner)],
        identifiers: [create(:ci_reports_security_identifier)]
      )
    end

    let(:other_report) do
      create(
        :ci_reports_security_report,
        findings: [create(:ci_reports_security_finding)],
        scanners: [create(:ci_reports_security_scanner, external_id: 'other_scanner', name: 'Other Scanner')],
        identifiers: [create(:ci_reports_security_identifier, external_id: 'other_id', name: 'other_scanner')]
      )
    end

    before do
      report.replace_with!(other_report)
    end

    it 'replaces report contents with other reports contents' do
      expect(report.findings).to eq(other_report.findings)
      expect(report.scanners).to eq(other_report.scanners)
      expect(report.identifiers).to eq(other_report.identifiers)
    end
  end

  describe '#merge!' do
    let(:merged_report) { double('Report') }

    before do
      merge_reports_service = double('MergeReportsService')

      allow(::Security::MergeReportsService).to receive(:new).and_return(merge_reports_service)
      allow(merge_reports_service).to receive(:execute).and_return(merged_report)
      allow(report).to receive(:replace_with!)
    end

    subject { report.merge!(described_class.new('sast', pipeline, created_at)) }

    it 'invokes the merge with other report and then replaces this report contents by merge result' do
      subject

      expect(report).to have_received(:replace_with!).with(merged_report)
    end
  end

  describe '#primary_scanner' do
    let(:scanner_1) { create(:ci_reports_security_scanner, external_id: 'external_id_1') }
    let(:scanner_2) { create(:ci_reports_security_scanner, external_id: 'external_id_2') }

    subject { report.primary_scanner }

    before do
      report.add_scanner(scanner_1)
      report.add_scanner(scanner_2)
    end

    it { is_expected.to eq(scanner_1) }
  end

  describe '#primary_identifiers' do
    it 'returns matching identifiers' do
      scanner_with_identifiers = create(
        :ci_reports_security_scanner,
        external_id: 'external_id_1',
        primary_identifiers: [create(:ci_reports_security_identifier, external_id: 'other_id', name: 'other_scanner')]
      )
      scanner_without_identifiers = create(
        :ci_reports_security_scanner,
        external_id: 'external_id_2')

      report.add_scanner(scanner_with_identifiers)
      report.add_scanner(scanner_without_identifiers)

      expect(report.primary_identifiers).to eq(scanner_with_identifiers.primary_identifiers)
    end
  end

  describe '#add_error' do
    context 'when the message is not given' do
      it 'adds a new error to report with the generic error message' do
        expect { report.add_error('foo') }.to change { report.errors }
                                          .from([])
                                          .to([{ type: 'foo', message: 'An unexpected error happened!' }])
      end
    end

    context 'when the message is given' do
      it 'adds a new error to report' do
        expect { report.add_error('foo', 'bar') }.to change { report.errors }
                                                 .from([])
                                                 .to([{ type: 'foo', message: 'bar' }])
      end
    end
  end

  describe '#add_warning' do
    context 'when the message is given' do
      it 'adds a new warning to report' do
        expect { report.add_warning('foo', 'bar') }.to change { report.warnings }
                                                 .from([])
                                                 .to([{ type: 'foo', message: 'bar' }])
      end
    end
  end

  describe 'errored?' do
    subject { report.errored? }

    context 'when the report does not have any errors' do
      it { is_expected.to be_falsey }
    end

    context 'when the report has errors' do
      before do
        report.add_error('foo', 'bar')
      end

      it { is_expected.to be_truthy }
    end
  end

  describe 'warnings?' do
    subject { report.warnings? }

    context 'when the report does not have any errors' do
      it { is_expected.to be_falsey }
    end

    context 'when the report has warnings' do
      before do
        report.add_warning('foo', 'bar')
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '#primary_scanner_order_to' do
    let(:scanner_1) { build(:ci_reports_security_scanner) }
    let(:scanner_2) { build(:ci_reports_security_scanner) }
    let(:report_1) { described_class.new('sast', pipeline, created_at) }
    let(:report_2) { described_class.new('sast', pipeline, created_at) }

    subject(:compare_based_on_primary_scanners) { report_1.primary_scanner_order_to(report_2) }

    context 'when the primary scanner of the receiver is nil' do
      context 'when the primary scanner of the other is nil' do
        it { is_expected.to be(1) }
      end

      context 'when the primary scanner of the other is not nil' do
        before do
          report_2.add_scanner(scanner_2)
        end

        it { is_expected.to be(1) }
      end
    end

    context 'when the primary scanner of the receiver is not nil' do
      before do
        report_1.add_scanner(scanner_1)
      end

      context 'when the primary scanner of the other is nil' do
        let(:scanner_2) { nil }

        it { is_expected.to be(-1) }
      end

      context 'when the primary scanner of the other is not nil' do
        before do
          report_2.add_scanner(scanner_2)

          allow(scanner_1).to receive(:<=>).and_return(0)
        end

        it 'compares two scanners' do
          expect(compare_based_on_primary_scanners).to be(0)
          expect(scanner_1).to have_received(:<=>).with(scanner_2)
        end
      end
    end
  end

  describe '#has_signatures?' do
    let(:finding) { create(:ci_reports_security_finding, signatures: signatures) }

    subject { report.has_signatures? }

    before do
      report.add_finding(finding)
    end

    context 'when the findings of the report does not have signatures' do
      let(:signatures) { [] }

      it { is_expected.to be_falsey }
    end

    context 'when the findings of the report have signatures' do
      let(:signatures) { [instance_double(Gitlab::Ci::Reports::Security::FindingSignature)] }

      it { is_expected.to be_truthy }
    end
  end
end
