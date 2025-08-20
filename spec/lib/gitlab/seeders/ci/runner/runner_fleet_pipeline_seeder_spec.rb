# frozen_string_literal: true

require 'spec_helper'

NULL_LOGGER = Gitlab::JsonLogger.new('/dev/null')
TAG_LIST = Gitlab::Seeders::Ci::Runner::RunnerFleetSeeder::TAG_LIST.to_set

RSpec.describe ::Gitlab::Seeders::Ci::Runner::RunnerFleetPipelineSeeder, feature_category: :fleet_visibility do
  let_it_be(:projects) { create_list(:project, 4) }
  let_it_be(:admin) { create(:admin, owner_of: projects) }
  let_it_be(:projects_to_runners) do
    [
      { project_id: projects[0].id, runner_ids: runner_ids_for_project(2, projects[0]) },
      { project_id: projects[1].id, runner_ids: runner_ids_for_project(1, projects[1]) },
      { project_id: projects[2].id, runner_ids: runner_ids_for_project(2, projects[2]) },
      { project_id: projects[3].id, runner_ids: runner_ids_for_project(1, projects[3]) }
    ]
  end

  subject(:seeder) do
    described_class.new(NULL_LOGGER, projects_to_runners: projects_to_runners, job_count: job_count,
      username: admin.username)
  end

  def runner_ids_for_project(runner_count, project)
    create_list(:ci_runner, runner_count, :project, projects: [project], tag_list: TAG_LIST.to_a.sample(5)).map(&:id)
  end

  describe '#seed' do
    before do
      stub_feature_flags(ci_validate_config_options: false)
    end

    context 'with job_count specified' do
      let(:job_count) { 20 }

      it 'creates expected jobs', :aggregate_failures do
        expect { seeder.seed }.to change { Ci::Build.count }.by(job_count)
          .and change { Ci::Pipeline.count }.by(4)

        expect(Ci::Pipeline.where.not(started_at: nil).map(&:queued_duration)).to all(be <= 5.minutes)
        expect(Ci::Build.where.not(started_at: nil).map(&:queued_duration)).to all(be <= 5.minutes)

        expect(Ci::Build.last(job_count).map(&:trace).map(&:raw)).to all(be_an(String))

        projects_to_runners.first(3).each do |project|
          expect(Ci::Build.where(runner_id: project[:runner_ids])).not_to be_empty
        end
      end
    end

    context 'with nil job_count' do
      let(:job_count) { nil }

      before do
        stub_const('Gitlab::Seeders::Ci::Runner::RunnerFleetPipelineSeeder::DEFAULT_JOB_COUNT', 2)
      end

      it 'creates expected jobs', :aggregate_failures do
        expect { seeder.seed }.to change { Ci::Build.count }.by(2)
          .and change { Ci::Pipeline.count }.by(2)
        expect(Ci::Build.last(2).map(&:tag_list).map(&:to_set)).to all satisfy { |r| r.subset?(TAG_LIST) }
      end

      it 'creates pipeline meta with each pipeline it creates' do
        expect { seeder.seed }.to change { ::Ci::PipelineMetadata.count }.by(2)

        expect(Ci::PipelineMetadata.last(2).map(&:name)).to all(start_with('Mock pipeline'))
      end

      context 'when the seeded pipelines have completed statuses' do
        before do
          allow(seeder).to receive(:random_pipeline_status).and_return(Ci::Pipeline::COMPLETED_STATUSES.sample)
        end

        it 'asynchronously triggers PipelineFinishedWorker for each pipeline' do
          expect(Ci::PipelineFinishedWorker).to receive(:perform_async).twice
          seeder.seed
        end

        it 'asynchronously triggers BuildFinishedWorker for each build' do
          expect(Ci::BuildFinishedWorker).to receive(:perform_async).twice
          seeder.seed
        end
      end
    end

    context 'when an invalid username is provided' do
      it 'raises a record not found error' do
        expect do
          described_class.new(NULL_LOGGER, projects_to_runners: projects_to_runners, job_count: 2,
            username: 'nonexistentuser')
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
