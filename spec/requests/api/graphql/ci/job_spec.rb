# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).pipelines.job(id)' do
  include GraphqlHelpers

  around do |example|
    travel_to(Time.current) { example.run }
  end

  let_it_be(:user) { create_default(:user) }
  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  let_it_be(:prepare_stage) { create(:ci_stage_entity, pipeline: pipeline, project: project, name: 'prepare') }
  let_it_be(:test_stage) { create(:ci_stage_entity, pipeline: pipeline, project: project, name: 'test') }

  let_it_be(:job_1) { create(:ci_build, pipeline: pipeline, stage: 'prepare', name: 'Job 1') }
  let_it_be(:job_2) { create(:ci_build, pipeline: pipeline, stage: 'test', name: 'Job 2') }
  let_it_be(:job_3) { create(:ci_build, pipeline: pipeline, stage: 'test', name: 'Job 3') }

  let(:path_to_job) do
    [
      [:project,   { full_path: project.full_path }],
      [:pipelines, { first: 1 }],
      [:nodes,     nil],
      [:job,       { id: global_id_of(job_2) }]
    ]
  end

  let(:query) do
    wrap_fields(query_graphql_path(query_path, all_graphql_fields_for(terminal_type)))
  end

  describe 'scalar fields' do
    let(:path) { [:project, :pipelines, :nodes, 0, :job] }
    let(:query_path) { path_to_job }
    let(:terminal_type) { 'CiJob' }

    it 'retrieves scalar fields' do
      job_2.update!(
        created_at: 40.seconds.ago,
        queued_at: 32.seconds.ago,
        started_at: 30.seconds.ago,
        finished_at: 5.seconds.ago
      )
      post_graphql(query, current_user: user)

      expect(graphql_data_at(*path)).to match a_hash_including(
        'id' => global_id_of(job_2),
        'name' => job_2.name,
        'allowFailure' => job_2.allow_failure,
        'duration' => 25,
        'queuedDuration' => 2.0,
        'status' => job_2.status.upcase
      )
    end

    context 'when fetching by name' do
      before do
        query_path.last[1] = { name: job_2.name }
      end

      it 'retrieves scalar fields' do
        post_graphql(query, current_user: user)

        expect(graphql_data_at(*path)).to match a_hash_including(
          'id' => global_id_of(job_2),
          'name' => job_2.name
        )
      end
    end
  end

  describe '.detailedStatus' do
    let(:path) { [:project, :pipelines, :nodes, 0, :job, :detailed_status] }
    let(:query_path) { path_to_job + [:detailed_status] }
    let(:terminal_type) { 'DetailedStatus' }

    it 'retrieves detailed status' do
      post_graphql(query, current_user: user)

      expect(graphql_data_at(*path)).to match a_hash_including(
        'text' => 'pending',
        'label' => 'pending',
        'action' => a_hash_including('buttonTitle' => 'Cancel this job', 'icon' => 'cancel')
      )
    end
  end

  describe '.stage' do
    let(:path) { [:project, :pipelines, :nodes, 0, :job, :stage] }
    let(:query_path) { path_to_job + [:stage] }
    let(:terminal_type) { 'CiStage' }

    it 'returns appropriate data' do
      post_graphql(query, current_user: user)

      expect(graphql_data_at(*path)).to match a_hash_including(
        'name' => test_stage.name,
        'jobs' => a_hash_including(
          'nodes' => contain_exactly(
            a_hash_including('id' => global_id_of(job_2)),
            a_hash_including('id' => global_id_of(job_3))
          )
        )
      )
    end
  end
end
