# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildReportResultService do
  describe '#execute', :clean_gitlab_redis_shared_state do
    subject(:build_report_result) { described_class.new.execute(build) }

    context 'when build is finished' do
      let(:build) { create(:ci_build, :success, :test_reports) }

      it 'creates a build report result entry', :aggregate_failures do
        expect(build_report_result.tests_name).to eq("test")
        expect(build_report_result.tests_success).to eq(2)
        expect(build_report_result.tests_failed).to eq(2)
        expect(build_report_result.tests_errored).to eq(0)
        expect(build_report_result.tests_skipped).to eq(0)
        expect(build_report_result.tests_duration).to eq(0.010284)
        expect(Ci::BuildReportResult.count).to eq(1)

        unique_test_cases_parsed = Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(
          event_names: described_class::EVENT_NAME,
          start_date: 2.weeks.ago,
          end_date: 2.weeks.from_now
        )
        expect(unique_test_cases_parsed).to eq(4)
      end

      context 'when data has already been persisted' do
        it 'raises an error and do not persist the same data twice' do
          expect { 2.times { described_class.new.execute(build) } }.to raise_error(ActiveRecord::RecordNotUnique)

          expect(Ci::BuildReportResult.count).to eq(1)
        end
      end
    end

    context 'when build is running and test report does not exist' do
      let(:build) { create(:ci_build, :running) }

      it 'does not persist data' do
        subject

        expect(Ci::BuildReportResult.count).to eq(0)
      end
    end
  end
end
