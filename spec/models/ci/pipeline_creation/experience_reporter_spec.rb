# frozen_string_literal: true

require 'spec_helper'
require 'labkit/rspec/matchers'

RSpec.describe Ci::PipelineCreation::ExperienceReporter, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project) }

  let(:started_at) { 5.seconds.ago.to_f }
  let(:source) { :push }

  describe '.report' do
    subject(:report) { described_class.report(pipeline: pipeline, source: source, started_at: started_at) }

    context 'when the pipeline was persisted' do
      let(:pipeline) { create(:ci_pipeline, project: project, status: :created) }

      it 'observes a successful experience' do
        expect { report }.to complete_user_experience(:create_pipeline_from_commit)
      end

      it 'anchors the experience on the request start time and tags the creation context' do
        expect(Labkit::UserExperienceSli).to receive(:observed).with(
          :create_pipeline_from_commit,
          hash_including(
            start_time: Time.zone.at(started_at),
            error: false,
            pipeline_source: 'push',
            creation_result: 'created',
            gl_project_id: project.id,
            gl_pipeline_id: pipeline.id
          )
        ).and_call_original

        report
      end
    end

    context 'when the pipeline was persisted as a failed config error' do
      let(:pipeline) { create(:ci_pipeline, project: project, status: :failed, failure_reason: :config_error) }

      it 'observes a successful experience (a pipeline row exists)' do
        expect { report }.to complete_user_experience(:create_pipeline_from_commit)
      end
    end

    context 'when the pipeline was skipped ([skip ci])' do
      let(:pipeline) { create(:ci_pipeline, project: project, status: :skipped) }

      it 'does not emit' do
        expect { report }.not_to complete_user_experience(:create_pipeline_from_commit)
      end
    end

    context 'when no pipeline was created for an expected reason' do
      %i[filtered_by_rules filtered_by_workflow_rules filtered_by_no_pipeline].each do |reason|
        context "with failure_reason #{reason}" do
          let(:pipeline) { build(:ci_pipeline, project: project, failure_reason: reason) }

          it 'does not emit' do
            expect { report }.not_to complete_user_experience(:create_pipeline_from_commit)
          end
        end
      end
    end

    context 'when no pipeline object is available (MR no-commits / duplicate guard)' do
      let(:pipeline) { nil }

      it 'does not emit' do
        expect { report }.not_to complete_user_experience(:create_pipeline_from_commit)
      end
    end

    context 'when creation failed unexpectedly and was not persisted' do
      let(:pipeline) { build(:ci_pipeline, project: project, failure_reason: :gitaly_unavailable) }

      it 'observes an errored experience' do
        expect { report }.to complete_user_experience(:create_pipeline_from_commit, error: true)
      end
    end

    context 'when the source is out of scope' do
      let(:pipeline) { create(:ci_pipeline, project: project) }
      let(:source) { :schedule }

      it 'does not emit' do
        expect { report }.not_to complete_user_experience(:create_pipeline_from_commit)
      end
    end

    context 'when started_at is missing' do
      let(:pipeline) { create(:ci_pipeline, project: project) }
      let(:started_at) { nil }

      it 'does not emit' do
        expect { report }.not_to complete_user_experience(:create_pipeline_from_commit)
      end
    end

    context 'for the merge_request_event source' do
      let(:source) { :merge_request_event }
      let(:pipeline) { create(:ci_pipeline, project: project, status: :created) }

      it 'observes a successful experience tagged with the source' do
        expect(Labkit::UserExperienceSli).to receive(:observed)
          .with(:create_pipeline_from_commit, hash_including(pipeline_source: 'merge_request_event'))
          .and_call_original

        expect { report }.to complete_user_experience(:create_pipeline_from_commit)
      end
    end

    context 'when Labkit raises' do
      let(:pipeline) { create(:ci_pipeline, project: project) }

      it 'tracks the exception instead of raising into the worker' do
        allow(Labkit::UserExperienceSli).to receive(:observed).and_raise(StandardError, 'boom')

        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(an_instance_of(StandardError))
        expect { report }.not_to raise_error
      end
    end
  end

  describe '.report_error' do
    subject(:report_error) do
      described_class.report_error(source: source, started_at: started_at, project_id: project.id)
    end

    it 'observes an errored experience with no pipeline context' do
      expect(Labkit::UserExperienceSli).to receive(:observed).with(
        :create_pipeline_from_commit,
        hash_including(
          error: true, pipeline_source: 'push', creation_result: nil, gl_project_id: project.id, gl_pipeline_id: nil
        )
      ).and_call_original

      expect { report_error }.to complete_user_experience(:create_pipeline_from_commit, error: true)
    end

    context 'when the source is out of scope' do
      let(:source) { :api }

      it 'does not emit' do
        expect { report_error }.not_to complete_user_experience(:create_pipeline_from_commit)
      end
    end

    context 'when started_at is missing' do
      let(:started_at) { nil }

      it 'does not emit' do
        expect { report_error }.not_to complete_user_experience(:create_pipeline_from_commit)
      end
    end
  end
end
