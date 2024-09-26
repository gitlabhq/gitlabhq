# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environments::StopService, feature_category: :continuous_delivery do
  include CreateEnvironmentsHelpers

  let(:service) { described_class.new(project, user) }

  shared_examples_for 'stopping environment' do
    let_it_be(:project) { create(:project, :private, :repository) }
    let_it_be(:developer) { create(:user, developer_of: project) }
    let_it_be(:reporter) { create(:user, reporter_of: project) }

    let(:user) { developer }

    context 'with a deployment' do
      let!(:environment) { review_job.persisted_environment }
      let!(:pipeline) { create(:ci_pipeline, project: project) }
      let!(:review_job) { create(:ci_build, :with_deployment, :start_review_app, pipeline: pipeline, project: project) }
      let!(:stop_review_job) { create(:ci_build, :with_deployment, :stop_review_app, :manual, pipeline: pipeline, project: project, user: user) }

      before do
        review_job.success!
      end

      context 'without stop action' do
        let!(:environment) { create(:environment, :available, project: project) }

        it 'stops the environment' do
          expect { subject }.to change { environment.reload.state }.from('available').to('stopped')
        end
      end

      it 'plays the stop action' do
        expect { subject }.to change { stop_review_job.reload.status }.from('manual').to('pending')
      end

      context 'force option' do
        let(:service) { described_class.new(project, user, { force: true }) }

        it 'does not play the stop action when forced' do
          expect { subject }.to change { environment.reload.state }.from('available').to('stopped')
          expect(stop_review_job.reload.status).to eq('manual')
        end
      end

      context 'when an environment has already been stopped' do
        let!(:environment) { create(:environment, :stopped, project: project) }

        it 'does not play the stop action' do
          expect { subject }.not_to change { stop_review_job.reload.status }
        end
      end
    end

    context 'without a deployment' do
      let!(:environment) { create(:environment, project: project) }

      it 'stops the environment' do
        expect { subject }.to change { environment.reload.state }.from('available').to('stopped')
      end
    end
  end

  describe '#execute' do
    subject { service.execute(environment) }

    include_examples 'stopping environment'

    context 'when the actor does not have permission to stop the environment' do
      let!(:environment) { create(:environment, project: project) }
      let(:user) { reporter }

      it 'does not stop the environment' do
        expect { subject }.not_to change { environment.reload.state }
      end
    end
  end

  describe '#unsafe_execute!' do
    let(:user) { nil }

    subject { service.unsafe_execute!(environment) }

    include_examples 'stopping environment'
  end

  describe '#execute_for_branch' do
    let_it_be(:project) { create(:project, :private, :repository) }
    let_it_be(:user) { create(:user) }

    context 'when environment with review app exists' do
      context 'when user has permission to stop environment' do
        before_all do
          project.add_developer(user)
        end

        context 'when environment is associated with removed branch' do
          it 'stops environment' do
            expect_environment_stopping_on('feature', feature_environment)
          end
        end

        context 'when environment is associated with different branch' do
          it 'does not stop environment' do
            expect_environment_not_stopped_on('master', feature_environment)
          end
        end

        context 'when specified branch does not exist' do
          it 'does not stop environment' do
            expect_environment_not_stopped_on('non/existent/branch', feature_environment)
          end
        end

        context 'when no branch not specified' do
          it 'does not stop environment' do
            expect_environment_not_stopped_on(nil, feature_environment)
          end
        end

        context 'when environment is not stopped' do
          before do
            allow_next_found_instance_of(Environment) do |environment|
              allow(environment).to receive(:state).and_return(:stopped)
            end
          end

          it 'does not stop environment' do
            expect_environment_not_stopped_on('feature', feature_environment)
          end
        end
      end

      context 'when user does not have permission to stop environment' do
        context 'when user has no access to manage deployments' do
          before_all do
            project.add_guest(user)
          end

          it 'does not stop environment' do
            expect_environment_not_stopped_on('master', feature_environment)
          end
        end
      end

      context 'when branch for stop action is protected' do
        before_all do
          project.add_developer(user)
          create(:protected_branch, :no_one_can_push, name: 'master', project: project)
        end

        it 'does not stop environment' do
          expect_environment_not_stopped_on('master', feature_environment)
        end
      end
    end

    context 'when there is no environment associated with review app' do
      before do
        create(:environment, project: project)
      end

      context 'when user has permission to stop environments' do
        before_all do
          project.add_maintainer(user)
        end

        it 'does not stop environment' do
          expect_environment_not_stopped_on('master', feature_environment)
        end
      end
    end

    context 'when environment does not exist' do
      it 'does not raise error' do
        expect { service.execute_for_branch('master') }
          .not_to raise_error
      end
    end
  end

  describe '#execute_for_merge_request_pipeline' do
    subject { service.execute_for_merge_request_pipeline(merge_request) }

    let_it_be_with_reload(:merge_request) { create(:merge_request, source_branch: 'feature', target_branch: 'master') }
    let_it_be(:project) { merge_request.project }
    let_it_be(:user) { create(:user) }

    let(:pipeline) do
      create(:ci_pipeline,
        source: :merge_request_event,
        merge_request: merge_request,
        project: project,
        sha: merge_request.diff_head_sha,
        merge_requests_as_head_pipeline: [merge_request])
    end

    let!(:review_job) { create(:ci_build, :with_deployment, :start_review_app, :success, pipeline: pipeline, project: project, user: user) }
    let!(:stop_review_job) { create(:ci_build, :with_deployment, :stop_review_app, :manual, pipeline: pipeline, project: project, user: user) }

    before do
      review_job.deployment.success!
    end

    it 'has active environment at first' do
      expect(pipeline.environments_in_self_and_project_descendants.first).to be_available
    end

    context 'when user is a developer' do
      before_all do
        project.add_developer(user)
      end

      context 'and merge request has associated created_environments' do
        let!(:environment1) { create(:environment, project: project, merge_request: merge_request) }
        let!(:environment2) { create(:environment, project: project, merge_request: merge_request) }
        let!(:environment3) { create(:environment, project: project) }
        let!(:environment3_deployment) { create(:deployment, environment: environment3, sha: pipeline.sha) }

        before do
          subject
        end

        it 'stops the associated created_environments' do
          expect(environment1.reload).to be_stopped
          expect(environment2.reload).to be_stopped
        end

        it 'does not affect environments that are not associated to the merge request' do
          expect(environment3.reload).to be_available
        end
      end

      it 'stops the active environment' do
        subject
        expect(pipeline.environments_in_self_and_project_descendants.first).to be_stopping
      end

      context 'when pipeline is a branch pipeline for merge request' do
        let(:pipeline) do
          create(:ci_pipeline,
            source: :push,
            project: project,
            sha: merge_request.diff_head_sha,
            merge_requests_as_head_pipeline: [merge_request])
        end

        it 'does not stop the active environment' do
          subject

          expect(pipeline.environments_in_self_and_project_descendants.first).to be_available
        end
      end

      context 'with environment related jobs ' do
        let!(:environment) { create(:environment, :available, name: 'staging', project: project) }
        let!(:prepare_staging_job) { create(:ci_build, :prepare_staging, pipeline: pipeline, project: project) }
        let!(:start_staging_job) { create(:ci_build, :start_staging, :with_deployment, :manual, pipeline: pipeline, project: project, user: user) }
        let!(:stop_staging_job) { create(:ci_build, :stop_staging, :manual, pipeline: pipeline, project: project, user: user) }

        it 'does not stop environments that was not started by the merge request' do
          subject

          expect(prepare_staging_job.persisted_environment.state).to eq('available')
        end
      end
    end

    context 'when user is a reporter' do
      before_all do
        project.add_reporter(user)
      end

      it 'does not stop the active environment' do
        subject

        expect(pipeline.environments_in_self_and_project_descendants.first).to be_available
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

        expect(pipeline.environments_in_self_and_project_descendants.first).to be_available
      end
    end
  end

  def expect_environment_stopped_on(branch, environment)
    expect { service.execute_for_branch(branch) }
      .to change { environment.reload.state }.from('available').to('stopped')
  end

  def expect_environment_stopping_on(branch, environment)
    expect { service.execute_for_branch(branch) }
      .to change { environment.reload.state }.from('available').to('stopping')
  end

  def expect_environment_not_stopped_on(branch, environment)
    expect { service.execute_for_branch(branch) }
      .not_to change { environment.reload.state }.from('available')
  end

  def feature_environment
    create(:environment, :with_review_app, project: project, ref: 'feature', user: user)
  end
end
