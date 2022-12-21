# frozen_string_literal: true

require 'spec_helper'

NULL_LOGGER = Gitlab::JsonLogger.new('/dev/null')

RSpec.describe ::Gitlab::Seeders::Ci::Runner::RunnerFleetPipelineSeeder, feature_category: :runner_fleet do
  subject(:seeder) do
    described_class.new(NULL_LOGGER, projects_to_runners: projects_to_runners, job_count: job_count)
  end

  def runner_ids_for_project(runner_count, project)
    create_list(:ci_runner, runner_count, :project, projects: [project]).map(&:id)
  end

  let_it_be(:projects) { create_list(:project, 4) }
  let_it_be(:projects_to_runners) do
    [
      { project_id: projects[0].id, runner_ids: runner_ids_for_project(2, projects[0]) },
      { project_id: projects[1].id, runner_ids: runner_ids_for_project(1, projects[1]) },
      { project_id: projects[2].id, runner_ids: runner_ids_for_project(2, projects[2]) },
      { project_id: projects[3].id, runner_ids: runner_ids_for_project(1, projects[3]) }
    ]
  end

  describe '#seed' do
    context 'with job_count specified' do
      let(:job_count) { 20 }

      it 'creates expected jobs', :aggregate_failures do
        expect { seeder.seed }.to change { Ci::Build.count }.by(job_count)
          .and change { Ci::Pipeline.count }.by(4)

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
      end
    end
  end
end
