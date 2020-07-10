# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DagJobGroupEntity do
  let_it_be(:request) { double(:request) }
  let_it_be(:pipeline) { create(:ci_pipeline) }
  let_it_be(:stage) { create(:ci_stage, pipeline: pipeline) }

  let(:group) { Ci::Group.new(pipeline.project, stage, name: 'test', jobs: jobs) }
  let(:entity) { described_class.new(group, request: request) }

  describe '#as_json' do
    subject { entity.as_json }

    context 'when group contains 1 job' do
      let(:job) { create(:ci_build, stage: stage, pipeline: pipeline, name: 'test') }
      let(:jobs) { [job] }

      it 'exposes a name' do
        expect(subject.fetch(:name)).to eq 'test'
      end

      it 'exposes the size' do
        expect(subject.fetch(:size)).to eq 1
      end

      it 'exposes the jobs' do
        exposed_jobs = subject.fetch(:jobs)

        expect(exposed_jobs.size).to eq 1
        expect(exposed_jobs.first.fetch(:name)).to eq 'test'
      end

      it 'matches schema' do
        expect(subject.to_json).to match_schema('entities/dag_job_group')
      end
    end

    context 'when group contains multiple parallel jobs' do
      let(:job_1) { create(:ci_build, stage: stage, pipeline: pipeline, name: 'test 1/2') }
      let(:job_2) { create(:ci_build, stage: stage, pipeline: pipeline, name: 'test 2/2') }
      let(:jobs) { [job_1, job_2] }

      it 'exposes a name' do
        expect(subject.fetch(:name)).to eq 'test'
      end

      it 'exposes the size' do
        expect(subject.fetch(:size)).to eq 2
      end

      it 'exposes the jobs' do
        exposed_jobs = subject.fetch(:jobs)

        expect(exposed_jobs.size).to eq 2
        expect(exposed_jobs.first.fetch(:name)).to eq 'test 1/2'
        expect(exposed_jobs.last.fetch(:name)).to eq 'test 2/2'
      end

      it 'matches schema' do
        expect(subject.to_json).to match_schema('entities/dag_job_group')
      end
    end
  end
end
