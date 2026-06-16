# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TrackFailedBuildService, feature_category: :continuous_integration do
  let_it_be(:user, freeze: false) { create(:user) }
  let_it_be(:project, freeze: false) { create(:project, :public) }
  let_it_be(:pipeline, freeze: false) { create(:ci_pipeline, project: project, user: user) }

  let_it_be(:exit_code, freeze: false) { 42 }
  let_it_be(:failure_reason, freeze: false) { "script_failure" }

  describe '#execute' do
    context 'when a build has failed' do
      let_it_be(:build, freeze: false) { create(:ci_build, :failed, :sast_report, pipeline: pipeline, user: user) }

      subject { described_class.new(build: build, exit_code: exit_code, failure_reason: failure_reason) }

      it 'tracks the build failed event', :snowplow do
        response = subject.execute

        expect(response.success?).to be true

        context = {
          schema: described_class::SCHEMA_URL,
          data: {
            build_id: build.id,
            build_name: build.name,
            build_artifact_types: ["sast"],
            exit_code: exit_code,
            failure_reason: failure_reason,
            project: project.id
          }
        }

        expect_snowplow_event(
          category: 'ci::build',
          action: 'failed',
          context: [context],
          user: user,
          project: project.id)
      end
    end

    context 'when a build has not failed' do
      let_it_be(:build, freeze: false) { create(:ci_build, :success, :sast_report, pipeline: pipeline, user: user) }

      subject { described_class.new(build: build, exit_code: nil, failure_reason: nil) }

      it 'does not track the build failed event', :snowplow do
        response = subject.execute

        expect(response.error?).to be true

        expect_no_snowplow_event
      end
    end
  end
end
