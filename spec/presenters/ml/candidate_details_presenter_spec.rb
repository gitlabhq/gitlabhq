# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ml::CandidateDetailsPresenter, feature_category: :mlops do
  let_it_be(:project) { create(:project, :private) } # rubocop:disable RSpec/FactoryBot/AvoidCreate
  let_it_be(:user) { project.creator }
  let_it_be(:experiment) { create(:ml_experiments, user: user, project: project) } # rubocop:disable RSpec/FactoryBot/AvoidCreate
  let_it_be(:candidate) do
    create(:ml_candidates, :with_artifact, experiment: experiment, user: user, project: project) # rubocop:disable RSpec/FactoryBot/AvoidCreate
  end

  let_it_be(:metrics) do
    [
      build_stubbed(:ml_candidate_metrics, name: 'metric1', value: 0.1, candidate: candidate),
      build_stubbed(:ml_candidate_metrics, name: 'metric2', value: 0.2, candidate: candidate),
      build_stubbed(:ml_candidate_metrics, name: 'metric3', value: 0.3, candidate: candidate)
    ]
  end

  let_it_be(:params) do
    [
      build_stubbed(:ml_candidate_params, name: 'param1', value: 'p1', candidate: candidate),
      build_stubbed(:ml_candidate_params, name: 'param2', value: 'p2', candidate: candidate)
    ]
  end

  subject { Gitlab::Json.parse(described_class.new(candidate).present)['candidate'] }

  before do
    allow(candidate).to receive(:latest_metrics).and_return(metrics)
    allow(candidate).to receive(:params).and_return(params)
  end

  describe '#execute' do
    context 'when candidate has metrics, params and artifacts' do
      it 'generates the correct params' do
        expect(subject['params']).to include(
          hash_including('name' => 'param1', 'value' => 'p1'),
          hash_including('name' => 'param2', 'value' => 'p2')
        )
      end

      it 'generates the correct metrics' do
        expect(subject['metrics']).to include(
          hash_including('name' => 'metric1', 'value' => 0.1),
          hash_including('name' => 'metric2', 'value' => 0.2),
          hash_including('name' => 'metric3', 'value' => 0.3)
        )
      end

      it 'generates the correct info' do
        expected_info = {
          'iid' => candidate.iid,
          'eid' => candidate.eid,
          'path_to_artifact' => "/#{project.full_path}/-/packages/#{candidate.artifact.id}",
          'experiment_name' => candidate.experiment.name,
          'path_to_experiment' => "/#{project.full_path}/-/ml/experiments/#{experiment.iid}",
          'status' => 'running',
          'path' => "/#{project.full_path}/-/ml/candidates/#{candidate.iid}"
        }

        expect(subject['info']).to include(expected_info)
      end
    end

    context 'when candidate has job' do
      let_it_be(:pipeline) { build_stubbed(:ci_pipeline, project: project, user: user) }
      let_it_be(:build) { candidate.ci_build = build_stubbed(:ci_build, pipeline: pipeline, user: user) }

      it 'generates the correct ci' do
        expected_info = {
          'path' => "/#{project.full_path}/-/jobs/#{build.id}",
          'name' => 'test',
          'user' => {
            'path' => "/#{pipeline.user.username}",
            'username' => pipeline.user.username
          }
        }

        expect(subject.dig('info', 'ci_job')).to include(expected_info)
      end

      context 'when build user is nil' do
        it 'does not include build user info' do
          expected_info = {
            'path' => "/#{project.full_path}/-/jobs/#{build.id}",
            'name' => 'test'
          }

          allow(build).to receive(:user).and_return(nil)

          expect(subject.dig('info', 'ci_job')).to eq(expected_info)
        end
      end

      context 'and job is from MR' do
        let_it_be(:mr) { pipeline.merge_request = build_stubbed(:merge_request, source_project: project) }

        it 'generates the correct ci' do
          expected_info = {
            'path' => "/#{project.full_path}/-/merge_requests/#{mr.iid}",
            'title' => mr.title
          }

          expect(subject.dig('info', 'ci_job', 'merge_request')).to include(expected_info)
        end
      end
    end
  end
end
