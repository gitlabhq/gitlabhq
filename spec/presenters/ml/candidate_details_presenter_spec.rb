# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ml::CandidateDetailsPresenter, feature_category: :mlops do
  let_it_be(:user) { build_stubbed(:user, :with_avatar) }
  let_it_be(:project) { build_stubbed(:project, :private, creator: user) }
  let_it_be(:experiment) { build_stubbed(:ml_experiments, user: user, project: project, iid: 100) }
  let_it_be(:candidate) do
    build_stubbed(:ml_candidates, :with_artifact, experiment: experiment, user: user, project: project,
      internal_id: 100)
  end

  let_it_be(:pipeline) { build_stubbed(:ci_pipeline, project: project, user: user) }
  let_it_be(:build) { candidate.ci_build = build_stubbed(:ci_build, pipeline: pipeline, user: user) }
  let_it_be(:mr) { pipeline.merge_request = build_stubbed(:merge_request, source_project: project) }

  let_it_be(:metrics) do
    [
      build_stubbed(:ml_candidate_metrics, name: 'metric1', value: 0.1, candidate: candidate),
      build_stubbed(:ml_candidate_metrics, name: 'metric1', value: 0.2, step: 1, candidate: candidate),
      build_stubbed(:ml_candidate_metrics, name: 'metric1', value: 0.3, step: 2, candidate: candidate),
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

  let(:can_user_read_build) { true }

  before do
    allow(candidate).to receive(:metrics).and_return(metrics)
    allow(candidate).to receive(:params).and_return(params)

    allow(Ability).to receive(:allowed?).and_call_original
    allow(Ability).to receive(:allowed?)
                        .with(user, :read_build, candidate.ci_build)
                        .and_return(can_user_read_build)
  end

  describe '#present' do
    subject { described_class.new(candidate, user).present }

    it 'presents the candidate correctly' do
      is_expected.to eq(
        {
          candidate: {
            info: {
              iid: candidate.iid,
              eid: candidate.eid,
              path_to_artifact: "/#{project.full_path}/-/packages/#{candidate.artifact.id}",
              experiment_name: candidate.experiment.name,
              path_to_experiment: "/#{project.full_path}/-/ml/experiments/#{experiment.iid}",
              path: "/#{project.full_path}/-/ml/candidates/#{candidate.iid}",
              status: candidate.status,
              ci_job: {
                merge_request: {
                  iid: mr.iid,
                  path: "/#{project.full_path}/-/merge_requests/#{mr.iid}",
                  title: mr.title
                },
                name: "test",
                path: "/#{project.full_path}/-/jobs/#{build.id}",
                user: {
                  avatar: user.avatar_url,
                  name: pipeline.user.name,
                  path: "/#{pipeline.user.username}",
                  username: pipeline.user.username
                }
              }
            },
            params: params,
            metrics: metrics,
            metadata: []
          }
        }
      )
    end
  end

  describe '#present_as_json' do
    subject { Gitlab::Json.parse(described_class.new(candidate, user).present_as_json)['candidate'] }

    context 'when candidate has metrics, params and artifacts' do
      it 'generates the correct params' do
        expect(subject['params']).to include(
          hash_including('name' => 'param1', 'value' => 'p1'),
          hash_including('name' => 'param2', 'value' => 'p2')
        )
      end

      it 'generates the correct metrics' do
        expect(subject['metrics']).to include(
          hash_including('name' => 'metric1', 'value' => 0.1, 'step' => 0),
          hash_including('name' => 'metric1', 'value' => 0.2, 'step' => 1),
          hash_including('name' => 'metric1', 'value' => 0.3, 'step' => 2),
          hash_including('name' => 'metric2', 'value' => 0.2, 'step' => 0),
          hash_including('name' => 'metric3', 'value' => 0.3, 'step' => 0)
        )
      end

      it 'generates the correct info' do
        expected_info = {
          'iid' => candidate.iid,
          'eid' => candidate.eid,
          'pathToArtifact' => "/#{project.full_path}/-/packages/#{candidate.artifact.id}",
          'experimentName' => candidate.experiment.name,
          'pathToExperiment' => "/#{project.full_path}/-/ml/experiments/#{experiment.iid}",
          'status' => 'running',
          'path' => "/#{project.full_path}/-/ml/candidates/#{candidate.iid}"
        }

        expect(subject['info']).to include(expected_info)
      end
    end

    context 'when candidate has job' do
      it 'generates the correct ci' do
        expected_info = {
          'path' => "/#{project.full_path}/-/jobs/#{build.id}",
          'name' => 'test',
          'user' => {
            'path' => "/#{pipeline.user.username}",
            'name' => pipeline.user.name,
            'username' => pipeline.user.username,
            'avatar' => user.avatar_url
          }
        }

        expect(subject.dig('info', 'ciJob')).to include(expected_info)
      end

      context 'when build user is nil' do
        it 'does not include build user info' do
          allow(build).to receive(:user).and_return(nil)

          expect(subject.dig('info', 'ciJob')).not_to include(:user)
        end
      end

      context 'and job is from MR' do
        it 'generates the correct ci' do
          expected_info = {
            'path' => "/#{project.full_path}/-/merge_requests/#{mr.iid}",
            'iid' => mr.iid,
            'title' => mr.title
          }

          expect(subject.dig('info', 'ciJob', 'mergeRequest')).to include(expected_info)
        end
      end

      context 'when ci job is not to be added' do
        let(:can_user_read_build) { false }

        it 'ciJob is nil' do
          expect(subject.dig('info', 'ciJob')).to be_nil
        end
      end
    end
  end
end
