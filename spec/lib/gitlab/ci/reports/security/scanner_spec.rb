# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::Security::Scanner do
  describe '#initialize' do
    subject { described_class.new(**params) }

    let(:params) do
      {
        external_id: 'brakeman',
        name: 'Brakeman',
        vendor: 'GitLab',
        version: '1.0.1'
      }
    end

    context 'when all params are given' do
      it 'initializes an instance' do
        expect { subject }.not_to raise_error

        expect(subject).to have_attributes(
          external_id: 'brakeman',
          name: 'Brakeman',
          vendor: 'GitLab'
        )
      end
    end

    %i[external_id name].each do |attribute|
      context "when attribute #{attribute} is missing" do
        before do
          params.delete(attribute)
        end

        it 'raises an error' do
          expect { subject }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe '#key' do
    let(:scanner) { create(:ci_reports_security_scanner) }

    subject { scanner.key }

    it 'returns external_id' do
      is_expected.to eq(scanner.external_id)
    end
  end

  describe '#to_hash' do
    let(:scanner) { create(:ci_reports_security_scanner) }

    subject { scanner.to_hash }

    it 'returns expected hash' do
      is_expected.to eq({
        external_id: scanner.external_id,
        name: scanner.name,
        vendor: scanner.vendor
      })
    end

    context 'when vendor is not defined' do
      let(:scanner) { create(:ci_reports_security_scanner, vendor: nil) }

      it 'returns expected hash' do
        is_expected.to eq({
          external_id: scanner.external_id,
          name: scanner.name
        })
      end
    end
  end

  describe '#==' do
    using RSpec::Parameterized::TableSyntax

    where(:id_1, :id_2, :equal, :case_name) do
      'brakeman' | 'brakeman' | true  | 'when external_id is equal'
      'brakeman' | 'bandit'   | false | 'when external_id is different'
    end

    with_them do
      let(:scanner_1) { create(:ci_reports_security_scanner, external_id: id_1) }
      let(:scanner_2) { create(:ci_reports_security_scanner, external_id: id_2) }

      it "returns #{params[:equal]}" do
        expect(scanner_1 == scanner_2).to eq(equal)
      end
    end
  end

  describe '#<=>' do
    using RSpec::Parameterized::TableSyntax

    let(:scanner_1) { create(:ci_reports_security_scanner, **scanner_1_attributes) }
    let(:scanner_2) { create(:ci_reports_security_scanner, **scanner_2_attributes) }

    subject { scanner_1 <=> scanner_2 }

    context 'when the `external_id` of the scanners are different' do
      where(:scanner_1_attributes, :scanner_2_attributes, :expected_comparison_result) do
        { external_id: 'gemnasium', name: 'foo', vendor: 'bar' }        | { external_id: 'gemnasium-maven', name: 'foo', vendor: 'bar' }  | -1
        { external_id: 'gemnasium-maven', name: 'foo', vendor: 'bar' }  | { external_id: 'gemnasium-python', name: 'foo', vendor: 'bar' } | -1
        { external_id: 'gemnasium-python', name: 'foo', vendor: 'bar' } | { external_id: 'bandit', name: 'foo', vendor: 'bar' }           | 1
        { external_id: 'bandit', name: 'foo', vendor: 'bar' }           | { external_id: 'semgrep', name: 'foo', vendor: 'bar' }          | -1
        { external_id: 'spotbugs', name: 'foo', vendor: 'bar' }         | { external_id: 'semgrep', name: 'foo', vendor: 'bar' }          | -1
        { external_id: 'semgrep', name: 'foo', vendor: 'bar' }          | { external_id: 'unknown', name: 'foo', vendor: 'bar' }          | -1
        { external_id: 'gemnasium', name: 'foo', vendor: 'bar' }        | { external_id: 'gemnasium', name: 'foo', vendor: nil }          | 1
      end

      with_them do
        it { is_expected.to eq(expected_comparison_result) }
      end
    end

    context 'when the `external_id` of the scanners are equal' do
      context 'when the `name` of the scanners are different' do
        where(:scanner_1_attributes, :scanner_2_attributes, :expected_comparison_result) do
          { external_id: 'gemnasium', name: 'a', vendor: 'bar' } | { external_id: 'gemnasium', name: 'b', vendor: 'bar' } | -1
          { external_id: 'gemnasium', name: 'd', vendor: 'bar' } | { external_id: 'gemnasium', name: 'c', vendor: 'bar' } | 1
        end

        with_them do
          it { is_expected.to eq(expected_comparison_result) }
        end
      end

      context 'when the `name` of the scanners are equal' do
        where(:scanner_1_attributes, :scanner_2_attributes, :expected_comparison_result) do
          { external_id: 'gemnasium', name: 'foo', vendor: 'a' } | { external_id: 'gemnasium', name: 'foo', vendor: 'a' } | 0
          { external_id: 'gemnasium', name: 'foo', vendor: 'a' } | { external_id: 'gemnasium', name: 'foo', vendor: 'b' } | -1
          { external_id: 'gemnasium', name: 'foo', vendor: 'b' } | { external_id: 'gemnasium', name: 'foo', vendor: 'a' } | 1
        end

        with_them do
          it { is_expected.to eq(expected_comparison_result) }
        end
      end
    end
  end
end
