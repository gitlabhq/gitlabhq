# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobArtifacts::TrackArtifactReportService do
  describe '#execute', :clean_gitlab_redis_shared_state do
    let_it_be(:group) { create(:group, :private) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:user) { create(:user) }

    let(:test_event_name) { 'i_testing_test_report_uploaded' }
    let(:values_delimiter) { '_' }
    let(:counter) { Gitlab::UsageDataCounters::HLLRedisCounter }
    let(:start_time) { 1.week.ago }
    let(:end_time) { 1.week.from_now }

    subject(:track_artifact_report) { described_class.new.execute(pipeline) }

    context 'when pipeline has test reports' do
      let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user) }

      before do
        2.times do
          pipeline.builds << build(:ci_build, :test_reports, pipeline: pipeline, project: pipeline.project)
        end
      end

      it 'tracks the event using HLLRedisCounter' do
        allow(Gitlab::UsageDataCounters::HLLRedisCounter)
          .to receive(:track_event)
          .with(test_event_name, values: [pipeline.id, user.id].join(values_delimiter))
          .and_call_original

        expect { track_artifact_report }
          .to change {
                counter.unique_events(event_names: test_event_name,
                                      start_date: start_time,
                                      end_date: end_time)
              }
          .by 1
      end
    end

    context 'when pipeline does not have test reports' do
      let_it_be(:pipeline) { create(:ci_empty_pipeline) }

      it 'does not track the event' do
        track_artifact_report

        expect(Gitlab::UsageDataCounters::HLLRedisCounter)
          .not_to receive(:track_event)
          .with(anything, test_event_name)
      end
    end

    context 'when multiple pipelines have test reports' do
      let_it_be(:pipeline1) { create(:ci_pipeline, :with_test_reports, project: project, user: user) }
      let_it_be(:pipeline2) { create(:ci_pipeline, :with_test_reports, project: project, user: user) }

      it 'tracks all pipelines using HLLRedisCounter' do
        allow(Gitlab::UsageDataCounters::HLLRedisCounter)
          .to receive(:track_event)
          .with(test_event_name, values: [pipeline1.id, user.id].join(values_delimiter))
          .and_call_original

        allow(Gitlab::UsageDataCounters::HLLRedisCounter)
          .to receive(:track_event)
          .with(test_event_name, values: [pipeline2.id, user.id].join(values_delimiter))
          .and_call_original

        expect do
          described_class.new.execute(pipeline1)
          described_class.new.execute(pipeline2)
        end
          .to change {
                counter.unique_events(event_names: test_event_name,
                                      start_date: start_time,
                                      end_date: end_time)
              }
          .by 2
      end
    end
  end
end
