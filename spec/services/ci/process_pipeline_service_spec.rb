# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ProcessPipelineService do
  let_it_be(:project) { create(:project) }

  let(:pipeline) do
    create(:ci_empty_pipeline, ref: 'master', project: project)
  end

  let(:pipeline_processing_events_counter) { double(increment: true) }
  let(:legacy_update_jobs_counter) { double(increment: true) }

  let(:metrics) do
    double(pipeline_processing_events_counter: pipeline_processing_events_counter,
           legacy_update_jobs_counter: legacy_update_jobs_counter)
  end

  subject { described_class.new(pipeline) }

  before do
    stub_ci_pipeline_to_return_yaml_file
    stub_not_protect_default_branch

    allow(subject).to receive(:metrics).and_return(metrics)
  end

  describe 'processing events counter' do
    it 'increments processing events counter' do
      expect(pipeline_processing_events_counter).to receive(:increment)

      subject.execute
    end
  end

  describe 'updating a list of retried builds' do
    let!(:build_retried) { create_build('build') }
    let!(:build) { create_build('build') }
    let!(:test) { create_build('test') }

    context 'when FF ci_remove_update_retried_from_process_pipeline is enabled' do
      it 'does not update older builds as retried' do
        subject.execute

        expect(all_builds.latest).to contain_exactly(build, build_retried, test)
        expect(all_builds.retried).to be_empty
      end
    end

    context 'when FF ci_remove_update_retried_from_process_pipeline is disabled' do
      before do
        stub_feature_flags(ci_remove_update_retried_from_process_pipeline: false)
      end

      it 'returns unique statuses' do
        subject.execute

        expect(all_builds.latest).to contain_exactly(build, test)
        expect(all_builds.retried).to contain_exactly(build_retried)
      end

      it 'increments the counter' do
        expect(legacy_update_jobs_counter).to receive(:increment)

        subject.execute
      end

      it 'logs the project and pipeline id' do
        expect(Gitlab::AppJsonLogger).to receive(:info).with(event: 'update_retried_is_used',
                                                             project_id: project.id,
                                                             pipeline_id: pipeline.id)

        subject.execute
      end

      context 'when the previous build has already retried column true' do
        before do
          build_retried.update_columns(retried: true)
        end

        it 'does not increment the counter' do
          expect(legacy_update_jobs_counter).not_to receive(:increment)

          subject.execute
        end
      end
    end

    private

    def create_build(name, **opts)
      create(:ci_build, :created, pipeline: pipeline, name: name, **opts)
    end

    def all_builds
      pipeline.builds.order(:stage_idx, :id)
    end
  end
end
