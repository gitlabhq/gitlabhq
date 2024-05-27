# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::CodequalityReports do
  let(:codequality_report) { described_class.new }
  let(:degradation_major) { build(:codequality_degradation, :major) }
  let(:degradation_minor) { build(:codequality_degradation, :minor) }
  let(:degradation_blocker) { build(:codequality_degradation, :blocker) }
  let(:degradation_info) { build(:codequality_degradation, :info) }
  let(:degradation_major_2) { build(:codequality_degradation, :major) }
  let(:degradation_critical) { build(:codequality_degradation, :critical) }
  let(:degradation_uppercase_major) { build(:codequality_degradation, severity: 'MAJOR') }
  let(:degradation_unknown) { build(:codequality_degradation, severity: 'unknown') }

  it { expect(codequality_report.degradations).to eq({}) }

  describe '#add_degradation' do
    context 'when there is a degradation' do
      before do
        codequality_report.add_degradation(degradation_major)
      end

      it 'adds degradation to codequality report' do
        expect(codequality_report.degradations.keys).to match_array([degradation_major[:fingerprint]])
        expect(codequality_report.degradations.values.size).to eq(1)
      end
    end

    context 'when a required property is missing in the degradation' do
      let(:invalid_degradation) do
        {
          type: "Issue",
          check_name: "Rubocop/Metrics/ParameterLists",
          description: "Avoid parameter lists longer than 5 parameters. [12/5]",
          fingerprint: "ab5f8b935886b942d621399aefkaehfiaehf",
          severity: "minor"
        }.with_indifferent_access
      end

      it 'sets location as an error' do
        codequality_report.add_degradation(invalid_degradation)
      end
    end
  end

  describe '#set_error_message' do
    context 'when there is an error' do
      it 'sets errors' do
        codequality_report.set_error_message("error")

        expect(codequality_report.error_message).to eq("error")
      end
    end
  end

  describe '#degradations_count' do
    subject(:degradations_count) { codequality_report.degradations_count }

    context 'when there are many degradations' do
      before do
        codequality_report.add_degradation(degradation_major)
        codequality_report.add_degradation(degradation_minor)
      end

      it 'returns the number of degradations' do
        expect(degradations_count).to eq(2)
      end
    end
  end

  describe '#all_degradations' do
    subject(:all_degradations) { codequality_report.all_degradations }

    context 'when there are many degradations' do
      before do
        codequality_report.add_degradation(degradation_major)
        codequality_report.add_degradation(degradation_minor)
      end

      it 'returns all degradations' do
        expect(all_degradations).to contain_exactly(degradation_major, degradation_minor)
      end
    end
  end

  describe '#sort_degradations!' do
    before do
      codequality_report.add_degradation(degradation_major)
      codequality_report.add_degradation(degradation_minor)
      codequality_report.add_degradation(degradation_blocker)
      codequality_report.add_degradation(degradation_major_2)
      codequality_report.add_degradation(degradation_info)
      codequality_report.add_degradation(degradation_critical)
      codequality_report.add_degradation(degradation_unknown)

      codequality_report.sort_degradations!
    end

    it 'sorts degradations based on severity' do
      expect(codequality_report.degradations.values).to eq(
        [
          degradation_blocker,
          degradation_critical,
          degradation_major,
          degradation_major_2,
          degradation_minor,
          degradation_info,
          degradation_unknown
        ])
    end

    context 'with non-existence and uppercase severities' do
      let(:other_report) { described_class.new }
      let(:degradation_non_existent) { build(:codequality_degradation, severity: 'non-existent') }

      before do
        other_report.add_degradation(degradation_blocker)
        other_report.add_degradation(degradation_uppercase_major)
        other_report.add_degradation(degradation_minor)
        other_report.add_degradation(degradation_non_existent)
      end

      it 'sorts unknown last' do
        expect(other_report.degradations.values).to eq(
          [
            degradation_blocker,
            degradation_uppercase_major,
            degradation_minor,
            degradation_non_existent
          ])
      end
    end
  end

  describe '#code_quality_report_summary' do
    context "when there is no degradation" do
      it 'return nil' do
        expect(codequality_report.code_quality_report_summary).to eq(nil)
      end
    end

    context "when there are degradations" do
      before do
        codequality_report.add_degradation(degradation_major)
        codequality_report.add_degradation(degradation_major_2)
        codequality_report.add_degradation(degradation_minor)
        codequality_report.add_degradation(degradation_blocker)
        codequality_report.add_degradation(degradation_info)
        codequality_report.add_degradation(degradation_critical)
        codequality_report.add_degradation(degradation_unknown)
      end

      it 'returns the summary of the code quality report' do
        expect(codequality_report.code_quality_report_summary).to eq(
          {
            'major' => 2,
            'minor' => 1,
            'blocker' => 1,
            'info' => 1,
            'critical' => 1,
            'unknown' => 1,
            'count' => 7
          }
        )
      end
    end
  end
end
