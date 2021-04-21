# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::StopEnvironmentsService do
  include CreateEnvironmentsHelpers

  let(:project) { create(:project, :private, :repository) }
  let(:user) { create(:user) }

  let(:service) { described_class.new(project, user) }

  describe '#execute' do
    context 'when environment with review app exists' do
      before do
        create(:environment, :with_review_app, project: project,
                                               ref: 'feature')
      end

      context 'when user has permission to stop environment' do
        before do
          project.add_developer(user)
        end

        context 'when environment is associated with removed branch' do
          it 'stops environment' do
            expect_environment_stopped_on('feature')
          end
        end

        context 'when environment is associated with different branch' do
          it 'does not stop environment' do
            expect_environment_not_stopped_on('master')
          end
        end

        context 'when specified branch does not exist' do
          it 'does not stop environment' do
            expect_environment_not_stopped_on('non/existent/branch')
          end
        end

        context 'when no branch not specified' do
          it 'does not stop environment' do
            expect_environment_not_stopped_on(nil)
          end
        end

        context 'when environment is not stopped' do
          before do
            allow_any_instance_of(Environment)
              .to receive(:state).and_return(:stopped)
          end

          it 'does not stop environment' do
            expect_environment_not_stopped_on('feature')
          end
        end
      end

      context 'when user does not have permission to stop environment' do
        context 'when user has no access to manage deployments' do
          before do
            project.add_guest(user)
          end

          it 'does not stop environment' do
            expect_environment_not_stopped_on('master')
          end
        end
      end

      context 'when branch for stop action is protected' do
        before do
          project.add_developer(user)
          create(:protected_branch, :no_one_can_push,
                 name: 'master', project: project)
        end

        it 'does not stop environment' do
          expect_environment_not_stopped_on('master')
        end
      end
    end

    context 'when there is no environment associated with review app' do
      before do
        create(:environment, project: project)
      end

      context 'when user has permission to stop environments' do
        before do
          project.add_maintainer(user)
        end

        it 'does not stop environment' do
          expect_environment_not_stopped_on('master')
        end
      end
    end

    context 'when environment does not exist' do
      it 'does not raise error' do
        expect { service.execute('master') }
          .not_to raise_error
      end
    end
  end

  describe '#execute_for_merge_request' do
    subject { service.execute_for_merge_request(merge_request) }

    let(:merge_request) { create(:merge_request, source_branch: 'feature', target_branch: 'master') }
    let(:project) { merge_request.project }
    let(:user) { create(:user) }

    let(:pipeline) do
      create(:ci_pipeline,
        source: :merge_request_event,
        merge_request: merge_request,
        project: project,
        sha: merge_request.diff_head_sha,
        merge_requests_as_head_pipeline: [merge_request])
    end

    let!(:review_job) { create(:ci_build, :with_deployment, :start_review_app, pipeline: pipeline, project: project) }
    let!(:stop_review_job) { create(:ci_build, :with_deployment, :stop_review_app, :manual, pipeline: pipeline, project: project) }

    before do
      review_job.deployment.success!
    end

    it 'has active environment at first' do
      expect(pipeline.environments.first).to be_available
    end

    context 'when user is a developer' do
      before do
        project.add_developer(user)
      end

      it 'stops the active environment' do
        subject

        expect(pipeline.environments.first).to be_stopped
      end
    end

    context 'when user is a reporter' do
      before do
        project.add_reporter(user)
      end

      it 'does not stop the active environment' do
        subject

        expect(pipeline.environments.first).to be_available
      end
    end

    context 'when pipeline is not associated with environments' do
      let!(:job) { create(:ci_build, pipeline: pipeline, project: project) }

      it 'does not raise exception' do
        expect { subject }.not_to raise_exception
      end
    end

    context 'when pipeline is not a pipeline for merge request' do
      let(:pipeline) do
        create(:ci_pipeline,
          project: project,
          ref: 'feature',
          sha: merge_request.diff_head_sha,
          merge_requests_as_head_pipeline: [merge_request])
      end

      it 'does not stop the active environment' do
        subject

        expect(pipeline.environments.first).to be_available
      end
    end
  end

  describe '.execute_in_batch' do
    subject { described_class.execute_in_batch(environments) }

    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) { create(:user) }

    let(:environments) { Environment.available }

    before_all do
      project.add_developer(user)
      project.repository.add_branch(user, 'review/feature-1', 'master')
      project.repository.add_branch(user, 'review/feature-2', 'master')
    end

    before do
      create_review_app(user, project, 'review/feature-1')
      create_review_app(user, project, 'review/feature-2')
    end

    it 'stops environments' do
      expect { subject }
        .to change { project.environments.all.map(&:state).uniq }
        .from(['available']).to(['stopped'])

      expect(project.environments.all.map(&:auto_stop_at).uniq).to eq([nil])
    end

    it 'plays stop actions' do
      expect { subject }
        .to change { Ci::Build.where(name: 'stop_review_app').map(&:status).uniq }
        .from(['manual']).to(['pending'])
    end

    context 'when user does not have a permission to play the stop action' do
      before do
        project.team.truncate
      end

      it 'tracks the exception' do
        expect(Gitlab::ErrorTracking)
          .to receive(:track_exception)
          .with(Gitlab::Access::AccessDeniedError, anything)
          .twice
          .and_call_original

        subject
      end

      after do
        project.add_developer(user)
      end
    end
  end

  def expect_environment_stopped_on(branch)
    expect_any_instance_of(Environment)
      .to receive(:stop!)

    service.execute(branch)
  end

  def expect_environment_not_stopped_on(branch)
    expect_any_instance_of(Environment)
      .not_to receive(:stop!)

    service.execute(branch)
  end
end
