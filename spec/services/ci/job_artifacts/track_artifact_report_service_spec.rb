# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobArtifacts::TrackArtifactReportService, feature_category: :pipeline_reports do
  describe '#execute', :clean_gitlab_redis_shared_state do
    let_it_be(:group) { create(:group, :private) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:user1) { create(:user) }
    let_it_be(:user2) { create(:user) }

    let(:test_event_name_1) { 'i_testing_test_report_uploaded' }
    let(:test_event_name_2) { 'i_testing_coverage_report_uploaded' }

    let(:counter) { Gitlab::UsageDataCounters::HLLRedisCounter }
    let(:start_time) { 1.week.ago }
    let(:end_time) { 1.week.from_now }

    subject(:track_artifact_report) { described_class.new.execute(pipeline) }

    context 'when pipeline has test reports' do
      let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user1) }

      before do
        2.times do
          pipeline.builds << build(:ci_build, :test_reports, pipeline: pipeline, project: pipeline.project)
        end
      end

      it 'tracks the test event using HLLRedisCounter' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter)
          .to receive(:track_event)
          .with(test_event_name_1, values: user1.id)
          .and_call_original

        expect { track_artifact_report }.to change {
          counter.unique_events(event_names: test_event_name_1, start_date: start_time, end_date: end_time)
        }.by 1
      end
    end

    context 'when pipeline does not have test reports' do
      let_it_be(:pipeline) { create(:ci_empty_pipeline) }

      it 'does not track the test event' do
        track_artifact_report

        expect(Gitlab::UsageDataCounters::HLLRedisCounter)
          .not_to receive(:track_event)
          .with(anything, test_event_name_1)
      end

      it 'does not track the coverage test event' do
        track_artifact_report

        expect(Gitlab::UsageDataCounters::HLLRedisCounter)
          .not_to receive(:track_event)
          .with(anything, test_event_name_2)
      end
    end

    context 'when a single user started multiple pipelines with test reports' do
      let_it_be(:pipeline1) { create(:ci_pipeline, :with_test_reports, project: project, user: user1) }
      let_it_be(:pipeline2) { create(:ci_pipeline, :with_test_reports, project: project, user: user1) }

      it 'tracks all pipelines using HLLRedisCounter by one user_id for the test event' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter)
          .to receive(:track_event)
          .with(test_event_name_1, values: user1.id)
          .and_call_original

        expect(Gitlab::UsageDataCounters::HLLRedisCounter)
          .to receive(:track_event)
          .with(test_event_name_1, values: user1.id)
          .and_call_original

        expect do
          described_class.new.execute(pipeline1)
          described_class.new.execute(pipeline2)
        end.to change {
          counter.unique_events(event_names: test_event_name_1, start_date: start_time, end_date: end_time)
        }.by 1
      end
    end

    context 'when multiple users started multiple pipelines with test reports' do
      let_it_be(:pipeline1) { create(:ci_pipeline, :with_test_reports, project: project, user: user1) }
      let_it_be(:pipeline2) { create(:ci_pipeline, :with_test_reports, project: project, user: user2) }

      it 'tracks all pipelines using HLLRedisCounter by multiple users for test reports' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter)
          .to receive(:track_event)
          .with(test_event_name_1, values: user1.id)
          .and_call_original

        expect(Gitlab::UsageDataCounters::HLLRedisCounter)
          .to receive(:track_event)
          .with(test_event_name_1, values: user2.id)
          .and_call_original

        expect do
          described_class.new.execute(pipeline1)
          described_class.new.execute(pipeline2)
        end.to change {
          counter.unique_events(event_names: test_event_name_1, start_date: start_time, end_date: end_time)
        }.by 2
      end
    end

    context 'when pipeline has coverage test reports' do
      let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user1) }

      before do
        2.times do
          pipeline.builds << build(:ci_build, :coverage_reports, pipeline: pipeline, project: pipeline.project)
        end
      end

      it 'tracks the coverage test event using HLLRedisCounter' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter)
          .to receive(:track_event)
          .with(test_event_name_2, values: user1.id)
          .and_call_original

        expect { track_artifact_report }.to change {
          counter.unique_events(event_names: test_event_name_2, start_date: start_time, end_date: end_time)
        }.by 1
      end
    end

    context 'when a single user started multiple pipelines with coverage reports' do
      let_it_be(:pipeline1) { create(:ci_pipeline, :with_coverage_reports, project: project, user: user1) }
      let_it_be(:pipeline2) { create(:ci_pipeline, :with_coverage_reports, project: project, user: user1) }

      it 'tracks all pipelines using HLLRedisCounter by one user_id for the coverage test event' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter)
          .to receive(:track_event)
          .with(test_event_name_2, values: user1.id)
          .twice
          .and_call_original

        expect do
          described_class.new.execute(pipeline1)
          described_class.new.execute(pipeline2)
        end.to change {
          counter.unique_events(event_names: test_event_name_2, start_date: start_time, end_date: end_time)
        }.by 1
      end
    end

    context 'when multiple users started multiple pipelines with coverage test reports' do
      let_it_be(:pipeline1) { create(:ci_pipeline, :with_coverage_reports, project: project, user: user1) }
      let_it_be(:pipeline2) { create(:ci_pipeline, :with_coverage_reports, project: project, user: user2) }

      it 'tracks all pipelines using HLLRedisCounter by multiple users for coverage test reports' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter)
          .to receive(:track_event)
          .with(test_event_name_2, values: user1.id)
          .and_call_original

        expect(Gitlab::UsageDataCounters::HLLRedisCounter)
          .to receive(:track_event)
          .with(test_event_name_2, values: user2.id)
          .and_call_original

        expect do
          described_class.new.execute(pipeline1)
          described_class.new.execute(pipeline2)
        end.to change {
          counter.unique_events(event_names: test_event_name_2, start_date: start_time, end_date: end_time)
        }.by 2
      end
    end
  end
end
