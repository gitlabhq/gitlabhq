# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildDependencies do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, :repository) }

  let_it_be(:pipeline, reload: true) do
    create(:ci_pipeline, project: project,
                         sha: project.commit.id,
                         ref: project.default_branch,
                         status: 'success')
  end

  let!(:build) { create(:ci_build, pipeline: pipeline, name: 'build', stage_idx: 0, stage: 'build') }
  let!(:rspec_test) { create(:ci_build, pipeline: pipeline, name: 'rspec', stage_idx: 1, stage: 'test') }
  let!(:rubocop_test) { create(:ci_build, pipeline: pipeline, name: 'rubocop', stage_idx: 1, stage: 'test') }
  let!(:staging) { create(:ci_build, pipeline: pipeline, name: 'staging', stage_idx: 2, stage: 'deploy') }

  describe '#local' do
    subject { described_class.new(job).local }

    describe 'jobs from previous stages' do
      context 'when job is in the first stage' do
        let(:job) { build }

        it { is_expected.to be_empty }
      end

      context 'when job is in the second stage' do
        let(:job) { rspec_test }

        it 'contains all jobs from the first stage' do
          is_expected.to contain_exactly(build)
        end
      end

      context 'when job is in the last stage' do
        let(:job) { staging }

        it 'contains all jobs from all previous stages' do
          is_expected.to contain_exactly(build, rspec_test, rubocop_test)
        end

        context 'when a job is retried' do
          before do
            project.add_developer(user)
          end

          let(:retried_job) { Ci::Build.retry(rspec_test, user) }

          it 'contains the retried job instead of the original one' do
            is_expected.to contain_exactly(build, retried_job, rubocop_test)
          end
        end
      end
    end

    describe 'jobs from specified dependencies' do
      let(:dependencies) { }
      let(:needs) { }

      let!(:job) do
        scheduling_type = needs.present? ? :dag : :stage

        create(:ci_build,
          pipeline: pipeline,
          name: 'final',
          scheduling_type: scheduling_type,
          stage_idx: 3,
          stage: 'deploy',
          options: { dependencies: dependencies }
        )
      end

      before do
        needs.to_a.each do |need|
          create(:ci_build_need, build: job, **need)
        end
      end

      context 'when dependencies are defined' do
        let(:dependencies) { %w(rspec staging) }

        it { is_expected.to contain_exactly(rspec_test, staging) }
      end

      context 'when needs are defined' do
        let(:needs) do
          [
            { name: 'build',   artifacts: true },
            { name: 'rspec',   artifacts: true },
            { name: 'staging', artifacts: true }
          ]
        end

        it { is_expected.to contain_exactly(build, rspec_test, staging) }
      end

      context 'when need artifacts are defined' do
        let(:needs) do
          [
            { name: 'build',   artifacts: true },
            { name: 'rspec',   artifacts: false },
            { name: 'staging', artifacts: true }
          ]
        end

        it { is_expected.to contain_exactly(build, staging) }
      end

      context 'when needs and dependencies are defined' do
        let(:dependencies) { %w(rspec staging) }
        let(:needs) do
          [
            { name: 'build',   artifacts: true },
            { name: 'rspec',   artifacts: true },
            { name: 'staging', artifacts: true }
          ]
        end

        it { is_expected.to contain_exactly(rspec_test, staging) }
      end

      context 'when needs and dependencies contradict' do
        let(:dependencies) { %w(rspec staging) }
        let(:needs) do
          [
            { name: 'build',   artifacts: true },
            { name: 'rspec',   artifacts: false },
            { name: 'staging', artifacts: true }
          ]
        end

        it 'returns only the intersection' do
          is_expected.to contain_exactly(staging)
        end
      end

      context 'when nor dependencies or needs are defined' do
        it 'returns the jobs from previous stages' do
          is_expected.to contain_exactly(build, rspec_test, rubocop_test, staging)
        end
      end
    end
  end

  describe '#all' do
    let!(:job) do
      create(:ci_build, pipeline: pipeline, name: 'deploy', stage_idx: 3, stage: 'deploy')
    end

    let(:dependencies) { described_class.new(job) }

    subject { dependencies.all }

    it 'returns the union of all local dependencies and any cross project dependencies' do
      expect(dependencies).to receive(:local).and_return([1, 2, 3])
      expect(dependencies).to receive(:cross_project).and_return([3, 4])

      expect(subject).to contain_exactly(1, 2, 3, 4)
    end
  end
end
