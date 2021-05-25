# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineCreation::DropNotRunnableBuildsService do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  let_it_be_with_reload(:pipeline) do
    create(:ci_pipeline, project: project, status: :created)
  end

  let_it_be_with_reload(:job) do
    create(:ci_build, project: project, pipeline: pipeline)
  end

  describe '#execute' do
    subject(:execute) { described_class.new(pipeline).execute }

    shared_examples 'jobs allowed to run' do
      it 'does not drop the jobs' do
        expect { execute }.not_to change { job.reload.status }
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(ci_drop_new_builds_when_ci_quota_exceeded: false)
      end

      it_behaves_like 'jobs allowed to run'
    end

    context 'when the pipeline status is running' do
      before do
        pipeline.update!(status: :running)
      end

      it_behaves_like 'jobs allowed to run'
    end

    context 'when there are no runners available' do
      let_it_be(:offline_project_runner) do
        create(:ci_runner, runner_type: :project_type, projects: [project])
      end

      it 'drops the job' do
        execute
        job.reload

        expect(job).to be_failed
        expect(job.failure_reason).to eq('no_matching_runner')
      end
    end

    context 'with project runners' do
      let_it_be(:project_runner) do
        create(:ci_runner, :online, runner_type: :project_type, projects: [project])
      end

      it_behaves_like 'jobs allowed to run'
    end

    context 'with group runners' do
      let_it_be(:group_runner) do
        create(:ci_runner, :online, runner_type: :group_type, groups: [group])
      end

      it_behaves_like 'jobs allowed to run'
    end

    context 'with instance runners' do
      let_it_be(:instance_runner) do
        create(:ci_runner, :online, runner_type: :instance_type)
      end

      it_behaves_like 'jobs allowed to run'
    end
  end
end
