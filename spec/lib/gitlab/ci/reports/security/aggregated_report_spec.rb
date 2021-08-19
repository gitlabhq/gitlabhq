# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::Security::AggregatedReport do
  subject { described_class.new(reports, findings) }

  let(:reports) { build_list(:ci_reports_security_report, 1) }
  let(:findings) { build_list(:ci_reports_security_finding, 1) }

  describe '#created_at' do
    context 'no reports' do
      let(:reports) { [] }

      it 'has no created date' do
        expect(subject.created_at).to be_nil
      end
    end

    context 'report with no created date' do
      let(:reports) { build_list(:ci_reports_security_report, 1, created_at: nil) }

      it 'has no created date' do
        expect(subject.created_at).to be_nil
      end
    end

    context 'has reports' do
      let(:a_long_time_ago) { 2.months.ago }
      let(:a_while_ago) { 2.weeks.ago }
      let(:yesterday) { 1.day.ago }

      let(:reports) do
        [build(:ci_reports_security_report, created_at: a_while_ago),
         build(:ci_reports_security_report, created_at: a_long_time_ago),
         build(:ci_reports_security_report, created_at: nil),
         build(:ci_reports_security_report, created_at: yesterday)]
      end

      it 'has oldest created date' do
        expect(subject.created_at).to eq(a_long_time_ago)
      end
    end
  end
end
