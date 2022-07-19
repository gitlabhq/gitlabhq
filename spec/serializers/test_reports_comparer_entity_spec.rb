# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TestReportsComparerEntity do
  include TestReportsHelper

  let(:entity) { described_class.new(comparer) }
  let(:comparer) { Gitlab::Ci::Reports::TestReportsComparer.new(base_reports, head_reports) }
  let(:base_reports) { Gitlab::Ci::Reports::TestReport.new }
  let(:head_reports) { Gitlab::Ci::Reports::TestReport.new }

  describe '#as_json' do
    subject { entity.as_json }

    context 'when head and base reports include two test suites' do
      context 'when the status of head report is success' do
        before do
          base_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
          base_reports.get_suite('junit').add_test_case(create_test_case_java_success)
          head_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
          head_reports.get_suite('junit').add_test_case(create_test_case_java_success)
        end

        it 'contains correct compared test reports details' do
          expect(subject[:status]).to eq('success')
          expect(subject[:summary]).to include(total: 2, resolved: 0, failed: 0, errored: 0)
          expect(subject[:suites].first[:name]).to eq('rspec')
          expect(subject[:suites].first[:status]).to eq('success')
          expect(subject[:suites].second[:name]).to eq('junit')
          expect(subject[:suites].second[:status]).to eq('success')
        end
      end

      context 'when the status of head report is failed' do
        before do
          base_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
          base_reports.get_suite('junit').add_test_case(create_test_case_java_success)
          head_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
          head_reports.get_suite('junit').add_test_case(create_test_case_java_failed)
        end

        it 'contains correct compared test reports details' do
          expect(subject[:status]).to eq('failed')
          expect(subject[:summary]).to include(total: 2, resolved: 0, failed: 1, errored: 0)
          expect(subject[:suites].first[:name]).to eq('rspec')
          expect(subject[:suites].first[:status]).to eq('success')
          expect(subject[:suites].second[:name]).to eq('junit')
          expect(subject[:suites].second[:status]).to eq('failed')
        end
      end

      context 'when the status of head report is resolved' do
        before do
          base_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
          base_reports.get_suite('junit').add_test_case(create_test_case_java_failed)
          head_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
          head_reports.get_suite('junit').add_test_case(create_test_case_java_success)
        end

        it 'contains correct compared test reports details' do
          expect(subject[:status]).to eq('success')
          expect(subject[:summary]).to include(total: 2, resolved: 1, failed: 0, errored: 0)
          expect(subject[:suites].first[:name]).to eq('rspec')
          expect(subject[:suites].first[:status]).to eq('success')
          expect(subject[:suites].second[:name]).to eq('junit')
          expect(subject[:suites].second[:status]).to eq('success')
        end
      end
    end
  end
end
