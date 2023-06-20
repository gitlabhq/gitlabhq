# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineProcessing::AtomicProcessingService::StatusCollection,
  feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:pipeline) { create(:ci_pipeline) }
  let_it_be(:build_stage) { create(:ci_stage, name: 'build', pipeline: pipeline) }
  let_it_be(:test_stage) { create(:ci_stage, name: 'test', pipeline: pipeline) }
  let_it_be(:deploy_stage) { create(:ci_stage, name: 'deploy', pipeline: pipeline) }
  let_it_be(:build_a) do
    create(:ci_build, :success, name: 'build-a', ci_stage: build_stage, stage_idx: 0, pipeline: pipeline)
  end

  let_it_be(:build_b) do
    create(:ci_build, :failed, name: 'build-b', ci_stage: build_stage, stage_idx: 0, pipeline: pipeline)
  end

  let_it_be(:test_a) do
    create(:ci_build, :running, name: 'test-a', ci_stage: test_stage, stage_idx: 1, pipeline: pipeline)
  end

  let_it_be(:test_b) do
    create(:ci_build, :pending, name: 'test-b', ci_stage: test_stage, stage_idx: 1, pipeline: pipeline)
  end

  let_it_be(:deploy) do
    create(:ci_build, :created, name: 'deploy', ci_stage: deploy_stage, stage_idx: 2, pipeline: pipeline)
  end

  let(:collection) { described_class.new(pipeline) }

  describe '#set_job_status' do
    it 'does update existing status of job' do
      collection.set_job_status(test_a.id, 'success', 100)

      expect(collection.status_of_jobs(['test-a'])).to eq('success')
    end

    it 'ignores a missing job' do
      collection.set_job_status(-1, 'failed', 100)
    end
  end

  describe '#status_of_all' do
    it 'returns composite status of the collection' do
      expect(collection.status_of_all).to eq('running')
    end
  end

  describe '#status_of_jobs' do
    where(:names, :status) do
      %w[build-a]         | 'success'
      %w[build-a build-b] | 'failed'
      %w[build-a test-a]  | 'running'
    end

    with_them do
      it 'returns composite status of given names' do
        expect(collection.status_of_jobs(names)).to eq(status)
      end
    end
  end

  describe '#status_of_jobs_prior_to_stage' do
    where(:stage, :status) do
      0 | 'success'
      1 | 'failed'
      2 | 'running'
    end

    with_them do
      it 'returns composite status for jobs in prior stages' do
        expect(collection.status_of_jobs_prior_to_stage(stage)).to eq(status)
      end
    end
  end

  describe '#status_of_stage' do
    where(:stage, :status) do
      0 | 'failed'
      1 | 'running'
      2 | 'created'
    end

    with_them do
      it 'returns composite status for jobs at a given stages' do
        expect(collection.status_of_stage(stage)).to eq(status)
      end
    end
  end

  describe '#created_job_ids_in_stage' do
    it 'returns IDs of jobs at a given stage position' do
      expect(collection.created_job_ids_in_stage(0)).to be_empty
      expect(collection.created_job_ids_in_stage(1)).to be_empty
      expect(collection.created_job_ids_in_stage(2)).to contain_exactly(deploy.id)
    end
  end

  describe '#processing_jobs' do
    it 'returns jobs marked as processing' do
      expect(collection.processing_jobs.map { |job| job[:id] })
        .to contain_exactly(build_a.id, build_b.id, test_a.id, test_b.id, deploy.id)
    end
  end

  describe '#stopped_job_names' do
    it 'returns names of jobs that have a stopped status' do
      expect(collection.stopped_job_names)
        .to contain_exactly(build_a.name, build_b.name)
    end
  end
end
