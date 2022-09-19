# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DagPipelineEntity do
  let_it_be(:request) { double(:request) }

  let_it_be(:pipeline) { create(:ci_pipeline) }

  let(:entity) { described_class.new(pipeline, request: request) }

  describe '#as_json' do
    subject { entity.as_json }

    RSpec.shared_examples "matches schema" do
      it 'matches schema' do
        expect(subject.to_json).to match_schema('entities/dag_pipeline')
      end
    end

    context 'when pipeline is empty' do
      it 'contains stages' do
        expect(subject).to include(:stages)

        expect(subject[:stages]).to be_empty
      end

      it_behaves_like "matches schema"
    end

    context 'when pipeline has jobs' do
      let_it_be(:build_stage) { create(:ci_stage, name: 'build', pipeline: pipeline) }
      let_it_be(:test_stage) { create(:ci_stage, name: 'test', pipeline: pipeline) }
      let_it_be(:deploy_stage) { create(:ci_stage, name: 'deploy', pipeline: pipeline) }

      let!(:build_job)  { create(:ci_build, ci_stage: build_stage,  pipeline: pipeline) }
      let!(:test_job)   { create(:ci_build, ci_stage: test_stage,   pipeline: pipeline) }
      let!(:deploy_job) { create(:ci_build, ci_stage: deploy_stage, pipeline: pipeline) }

      it 'contains 3 stages' do
        stages = subject[:stages]

        expect(stages.size).to eq 3
        expect(stages.map { |s| s[:name] }).to contain_exactly('build', 'test', 'deploy')
      end

      it_behaves_like "matches schema"
    end

    context 'when pipeline has parallel jobs, DAG needs and GenericCommitStatus' do
      let!(:stage_build)  { create(:ci_stage, name: 'build',  position: 1, pipeline: pipeline) }
      let!(:stage_test)   { create(:ci_stage, name: 'test',   position: 2, pipeline: pipeline) }
      let!(:stage_deploy) { create(:ci_stage, name: 'deploy', position: 3, pipeline: pipeline) }

      let!(:job_build_1)   { create(:ci_build, name: 'build 1', ci_stage: stage_build, pipeline: pipeline) }
      let!(:job_build_2)   { create(:ci_build, name: 'build 2', ci_stage: stage_build, pipeline: pipeline) }
      let!(:commit_status) { create(:generic_commit_status, ci_stage: stage_build, pipeline: pipeline) }

      let!(:job_rspec_1) { create(:ci_build, name: 'rspec 1/2', ci_stage: stage_test, pipeline: pipeline) }
      let!(:job_rspec_2) { create(:ci_build, name: 'rspec 2/2', ci_stage: stage_test, pipeline: pipeline) }

      let!(:job_jest) do
        create(:ci_build, name: 'jest', ci_stage: stage_test, scheduling_type: 'dag', pipeline: pipeline)
          .tap do |job|
          create(:ci_build_need, name: 'build 1', build: job)
        end
      end

      let!(:job_deploy_ruby) do
        create(:ci_build, name: 'deploy_ruby', ci_stage: stage_deploy, scheduling_type: 'dag', pipeline: pipeline)
          .tap do |job|
          create(:ci_build_need, name: 'rspec 1/2', build: job)
          create(:ci_build_need, name: 'rspec 2/2', build: job)
        end
      end

      let!(:job_deploy_js) do
        create(:ci_build, name: 'deploy_js', ci_stage: stage_deploy, scheduling_type: 'dag', pipeline: pipeline)
          .tap do |job|
          create(:ci_build_need, name: 'jest', build: job)
        end
      end

      it 'performs the smallest number of queries', :request_store do
        log = ActiveRecord::QueryRecorder.new { subject }

        # stages, project, builds, build_needs
        expect(log.count).to eq 4
      end

      it 'contains all the data' do
        expected_result = {
          stages: [
            {
              name: 'build',
              groups: [
                {
                  name: 'build 1', size: 1, jobs: [
                    { name: 'build 1', scheduling_type: 'stage' }
                  ]
                },
                {
                  name: 'build 2', size: 1, jobs: [
                    { name: 'build 2', scheduling_type: 'stage' }
                  ]
                },
                {
                  name: 'generic', size: 1, jobs: [
                    { name: 'generic', scheduling_type: nil }
                  ]
                }
              ]
            },
            {
              name: 'test',
              groups: [
                {
                  name: 'jest', size: 1, jobs: [
                    { name: 'jest', scheduling_type: 'dag', needs: ['build 1'] }
                  ]
                },
                {
                  name: 'rspec', size: 2, jobs: [
                    { name: 'rspec 1/2', scheduling_type: 'stage' },
                    { name: 'rspec 2/2', scheduling_type: 'stage' }
                  ]
                }
              ]
            },
            {
              name: 'deploy',
              groups: [
                {
                  name: 'deploy_js', size: 1, jobs: [
                    { name: 'deploy_js', scheduling_type: 'dag', needs: ['jest'] }
                  ]
                },
                {
                  name: 'deploy_ruby', size: 1, jobs: [
                    { name: 'deploy_ruby', scheduling_type: 'dag', needs: ['rspec 1/2', 'rspec 2/2'] }
                  ]
                }
              ]
            }
          ]
        }

        expect(subject.fetch(:stages)).not_to be_empty

        expect(subject.fetch(:stages)[0].fetch(:name)).to eq 'build'
        expect(subject.fetch(:stages)[0]).to eq expected_result.fetch(:stages)[0]

        expect(subject.fetch(:stages)[1].fetch(:name)).to eq 'test'
        expect(subject.fetch(:stages)[1]).to eq expected_result.fetch(:stages)[1]

        expect(subject.fetch(:stages)[2].fetch(:name)).to eq 'deploy'
        expect(subject.fetch(:stages)[2]).to eq expected_result.fetch(:stages)[2]
      end

      it_behaves_like "matches schema"
    end
  end
end
