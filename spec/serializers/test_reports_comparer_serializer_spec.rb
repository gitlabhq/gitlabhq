# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TestReportsComparerSerializer do
  include TestReportsHelper

  let(:project) { double(:project) }
  let(:serializer) { described_class.new(project: project).represent(comparer) }
  let(:comparer) { Gitlab::Ci::Reports::TestReportsComparer.new(base_reports, head_reports) }
  let(:base_reports) { Gitlab::Ci::Reports::TestReport.new }
  let(:head_reports) { Gitlab::Ci::Reports::TestReport.new }

  describe '#to_json' do
    subject { serializer.to_json }

    context 'when head and base reports include two test suites' do
      context 'when the status of head report is success' do
        before do
          base_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
          base_reports.get_suite('junit').add_test_case(create_test_case_java_success)
          head_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
          head_reports.get_suite('junit').add_test_case(create_test_case_java_success)
        end

        it 'matches the schema' do
          expect(subject).to match_schema('entities/test_reports_comparer')
        end
      end

      context 'when the status of head report is failed' do
        before do
          base_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
          base_reports.get_suite('junit').add_test_case(create_test_case_java_success)
          head_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
          head_reports.get_suite('junit').add_test_case(create_test_case_java_failed)
        end

        it 'matches the schema' do
          expect(subject).to match_schema('entities/test_reports_comparer')
        end
      end

      context 'when the status of head report is resolved' do
        before do
          base_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
          base_reports.get_suite('junit').add_test_case(create_test_case_java_failed)
          head_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
          head_reports.get_suite('junit').add_test_case(create_test_case_java_success)
        end

        it 'matches the schema' do
          expect(subject).to match_schema('entities/test_reports_comparer')
        end
      end
    end
  end
end
