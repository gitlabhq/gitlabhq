# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobArtifacts::TrackArtifactReportWorker do
  describe '#perform', :clean_gitlab_redis_shared_state do
    let_it_be(:group) { create(:group, :private) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:user) { create(:user) }

    let_it_be(:pipeline) { create(:ci_pipeline, :with_test_reports, project: project, user: user) }

    subject(:perform) { described_class.new.perform(pipeline_id) }

    context 'when pipeline is found' do
      let(:pipeline_id) { pipeline.id }

      it 'executed service' do
        expect_next_instance_of(Ci::JobArtifacts::TrackArtifactReportService) do |instance|
          expect(instance).to receive(:execute).with(pipeline)
        end

        perform
      end

      it_behaves_like 'an idempotent worker' do
        let(:job_args) { pipeline_id }
        let(:test_event_name) { 'i_testing_test_report_uploaded' }
        let(:start_time) { 1.week.ago }
        let(:end_time) { 1.week.from_now }

        subject(:idempotent_perform) { perform_multiple(pipeline_id, exec_times: 2) }

        it 'does not try to increment again' do
          idempotent_perform

          unique_pipeline_pass = Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(
            event_names: test_event_name,
            start_date: start_time,
            end_date: end_time
          )
          expect(unique_pipeline_pass).to eq(1)
        end
      end
    end

    context 'when pipeline is not found' do
      let(:pipeline_id) { non_existing_record_id }

      it 'does not execute service' do
        allow_next_instance_of(Ci::JobArtifacts::TrackArtifactReportService) do |instance|
          expect(instance).not_to receive(:execute)
        end

        expect { perform }
          .not_to raise_error
      end
    end
  end
end
