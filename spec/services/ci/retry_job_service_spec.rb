# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RetryJobService, feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax
  let_it_be(:reporter) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:project) { create(:project, :repository, developers: developer, reporters: reporter) }
  let_it_be(:pipeline) do
    create(:ci_pipeline, project: project, sha: 'b83d6e391c22777fca1ed3012fce84f633d7fed0')
  end

  let_it_be(:stage) do
    create(:ci_stage, pipeline: pipeline, name: 'test')
  end

  let_it_be(:deploy_stage) { create(:ci_stage, pipeline: pipeline, name: 'deploy', position: stage.position + 1) }

  let(:job_variables_attributes) { [{ key: 'MANUAL_VAR', value: 'manual test var' }] }
  let(:user) { developer }

  let(:service) { described_class.new(project, user) }

  shared_context 'retryable bridge' do
    let_it_be(:downstream_project) { create(:project, :repository) }

    let_it_be_with_refind(:job) do
      create(:ci_bridge, :success,
        pipeline: pipeline, downstream: downstream_project, description: 'a trigger job', ci_stage: stage
      )
    end

    let_it_be(:job_to_clone) { job }

    before do
      job.update!(retried: false)
    end
  end

  shared_context 'retryable build' do
    let_it_be_with_reload(:job) do
      create(:ci_build, :success, pipeline: pipeline, ci_stage: stage)
    end

    let_it_be(:another_pipeline) { create(:ci_empty_pipeline, project: project) }

    let_it_be(:job_to_clone) do
      create(
        :ci_build, :failed, :picked, :expired, :erased, :queued, :coverage, :tags,
        :allowed_to_fail, :on_tag, :triggered, :teardown_environment, :resource_group,
        description: 'my-job', ci_stage: stage,
        pipeline: pipeline, auto_canceled_by: another_pipeline,
        scheduled_at: 10.seconds.since
      )
    end

    before do
      job.update!(retried: false, status: :success)
      job_to_clone.update!(retried: false, status: :success)
    end
  end

  shared_examples_for 'clones the job' do
    let(:job) { job_to_clone }

    before_all do
      job_to_clone.update!(ci_stage: stage)

      create(:ci_build_need, build: job_to_clone)
    end

    context 'when the user has ability to execute job' do
      before do
        stub_not_protect_default_branch
      end

      context 'when there is a failed job ToDo for the MR' do
        let!(:merge_request) { create(:merge_request, source_project: project, author: user, head_pipeline: pipeline) }
        let!(:todo) { create(:todo, :build_failed, user: user, project: project, author: user, target: merge_request) }

        it 'resolves the ToDo for the failed job' do
          expect do
            service.execute(job)
          end.to change { todo.reload.state }.from('pending').to('done')
        end
      end

      context 'when the job has needs' do
        before do
          create_list(:ci_build_need, 2, build: job)
        end

        it 'bulk inserts all the needs' do
          expect(Ci::BuildNeed).to receive(:bulk_insert!).and_call_original

          new_job
        end
      end

      it 'marks the old job as retried' do
        expect(new_job).to be_latest
        expect(job).to be_retried
        expect(job).to be_processed
      end
    end

    context 'when the user does not have permission to execute the job' do
      let(:user) { reporter }

      it 'raises an error' do
        expect { service.execute(job) }
          .to raise_error Gitlab::Access::AccessDeniedError
      end
    end
  end

  shared_examples_for 'does not retry the job' do
    it 'returns :not_retryable and :unprocessable_entity' do
      expect(subject.message).to be('Job cannot be retried')
      expect(subject.payload[:reason]).to eq(:not_retryable)
      expect(subject.payload[:job]).to eq(job)
    end
  end

  shared_examples_for 'retries the job' do
    it_behaves_like 'clones the job'

    it 'enqueues the new job' do
      expect(new_job).to be_pending
    end

    context 'when there are subsequent processables that are skipped' do
      let!(:subsequent_build) do
        create(:ci_build, :skipped, pipeline: pipeline, ci_stage: deploy_stage)
      end

      let!(:subsequent_bridge) do
        create(:ci_bridge, :skipped, pipeline: pipeline, ci_stage: deploy_stage)
      end

      it 'resumes pipeline processing in the subsequent stage' do
        service.execute(job)

        expect(subsequent_build.reload).to be_created
        expect(subsequent_bridge.reload).to be_created
      end

      it 'updates ownership for subsequent builds' do
        expect { service.execute(job) }.to change { subsequent_build.reload.user }.to(user)
      end

      it 'updates ownership for subsequent bridges' do
        expect { service.execute(job) }.to change { subsequent_bridge.reload.user }.to(user)
      end
    end

    context 'when the pipeline has other jobs' do
      let!(:other_test_build) { create(:ci_build, pipeline: pipeline, ci_stage: stage) }
      let!(:deploy) { create(:ci_build, pipeline: pipeline, ci_stage: deploy_stage) }
      let!(:deploy_needs_build2) { create(:ci_build_need, build: deploy, name: other_test_build.name) }

      context 'when job has a nil scheduling_type' do
        before do
          job.pipeline.processables.update_all(scheduling_type: nil)
          job.reload
        end

        it 'populates scheduling_type of processables' do
          expect(new_job.scheduling_type).to eq('stage')
          expect(job.reload.scheduling_type).to eq('stage')
          expect(other_test_build.reload.scheduling_type).to eq('stage')
          expect(deploy.reload.scheduling_type).to eq('dag')
        end
      end

      context 'when job has scheduling_type' do
        it 'does not call populate_scheduling_type!' do
          expect(job.pipeline).not_to receive(:ensure_scheduling_type!)

          expect(new_job.scheduling_type).to eq('stage')
        end
      end
    end

    context 'when the pipeline is a child pipeline and the bridge uses strategy:depend' do
      let!(:parent_pipeline) { create(:ci_pipeline, project: project) }
      let!(:bridge) { create(:ci_bridge, :strategy_depend, pipeline: parent_pipeline, status: 'success') }
      let!(:source_pipeline) { create(:ci_sources_pipeline, pipeline: pipeline, source_job: bridge) }

      it 'marks the source bridge as pending' do
        service.execute(job)

        expect(bridge.reload).to be_pending
      end
    end
  end

  shared_examples_for 'checks enqueue_immediately?' do
    it "returns enqueue_immediately" do
      subject
      expect(new_job.enqueue_immediately?).to eq enqueue_immediately
    end
  end

  shared_examples_for 'creates associations for a deployable job' do |factory_type|
    context 'when a job with a deployment is retried' do
      let!(:job) do
        create(factory_type, :with_deployment, :deploy_to_production, pipeline: pipeline, ci_stage: stage)
      end

      it 'creates a new deployment' do
        expect { new_job }.to change { Deployment.count }.by(1)
      end

      it 'does not create a new environment' do
        expect { new_job }.not_to change { Environment.count }
      end
    end

    context 'when a job with a dynamic environment is retried' do
      let_it_be(:other_developer) { create(:user, developer_of: project) }

      let(:environment_name) { 'review/$CI_COMMIT_REF_SLUG-$GITLAB_USER_ID' }

      let!(:job) do
        create(factory_type, :with_deployment,
          environment: environment_name,
          options: { environment: { name: environment_name } },
          pipeline: pipeline,
          ci_stage: stage,
          user: other_developer)
      end

      it 'creates a new deployment' do
        expect { new_job }.to change { Deployment.count }.by(1)
      end

      it 'does not create a new environment' do
        expect { new_job }.not_to change { Environment.count }
      end
    end
  end

  describe '#clone!' do
    let(:start_pipeline_on_clone) { false }
    let(:new_job) { service.clone!(job, start_pipeline: start_pipeline_on_clone) }

    it 'raises an error when an unexpected class is passed' do
      expect { service.clone!(create(:ci_build).present) }.to raise_error(TypeError)
    end

    context 'when the job to be cloned is a bridge' do
      include_context 'retryable bridge'

      it_behaves_like 'clones the job'

      it 'does not create a new deployment' do
        expect { new_job }.not_to change { Deployment.count }
      end

      context 'when the pipeline is started automatically' do
        let(:start_pipeline_on_clone) { true }

        it_behaves_like 'creates associations for a deployable job', :ci_bridge
      end

      context 'when given variables' do
        let(:new_job) { service.clone!(job, variables: job_variables_attributes) }

        it 'does not give variables to the new bridge' do
          expect { new_job }.not_to raise_error
        end
      end
    end

    context 'when the job to be cloned is a build' do
      include_context 'retryable build'

      it_behaves_like 'clones the job'

      it 'does not create a new deployment' do
        expect { new_job }.not_to change { Deployment.count }
      end

      context 'when the pipeline is started automatically' do
        let(:start_pipeline_on_clone) { true }

        it_behaves_like 'creates associations for a deployable job', :ci_build
      end

      context 'when given variables' do
        let(:new_job) { service.clone!(job, variables: job_variables_attributes) }

        context 'when the build is actionable' do
          let_it_be_with_refind(:job) { create(:ci_build, :actionable, pipeline: pipeline) }

          it 'gives variables to the new build' do
            expect(new_job.job_variables.count).to be(1)
            expect(new_job.job_variables.first.key).to eq('MANUAL_VAR')
            expect(new_job.job_variables.first.value).to eq('manual test var')
          end
        end

        context 'when the build is not actionable' do
          let_it_be_with_refind(:job) { create(:ci_build, pipeline: pipeline) }

          it 'does not give variables to the new build' do
            expect(new_job.job_variables.count).to be_zero
          end
        end
      end
    end

    context 'when enqueue_if_actionable is provided' do
      let!(:job) do
        create(:ci_build, *[trait].compact, :failed, pipeline: pipeline, ci_stage: stage)
      end

      let(:new_job) { subject }

      subject { service.clone!(job, enqueue_if_actionable: enqueue_if_actionable) }

      where(:enqueue_if_actionable, :trait, :enqueue_immediately) do
        true  | nil                | false
        true  | :manual            | true
        true  | :expired_scheduled | true

        false | nil                | false
        false | :manual            | false
        false | :expired_scheduled | false
      end

      with_them do
        it_behaves_like 'checks enqueue_immediately?'
      end
    end
  end

  describe '#execute' do
    let(:new_job) { subject[:job] }

    subject { service.execute(job) }

    context 'when the job to be retried is a bridge' do
      context 'and it is not retryable' do
        let_it_be(:job) { create(:ci_bridge, :failed, :reached_max_descendant_pipelines_depth) }

        it_behaves_like 'does not retry the job'
      end

      include_context 'retryable bridge'

      it_behaves_like 'retries the job'

      context 'when given variables' do
        let(:new_job) { service.clone!(job, variables: job_variables_attributes) }

        it 'does not give variables to the new bridge' do
          expect { new_job }.not_to raise_error
        end
      end
    end

    context 'when the job to be retried is a build' do
      context 'and it is not retryable' do
        let_it_be(:job) { create(:ci_build, :deployment_rejected, pipeline: pipeline) }

        it_behaves_like 'does not retry the job'
      end

      include_context 'retryable build'

      it_behaves_like 'retries the job'

      context 'automatic retryable build' do
        let!(:auto_retryable_build) do
          create(:ci_build, pipeline: pipeline, ci_stage: stage, user: user, options: { retry: 1 })
        end

        def drop_build!
          auto_retryable_build.drop_with_exit_code!('test failure', 1)
        end

        it 'creates a new build and enqueues BuildQueueWorker' do
          expect { drop_build! }.to change { Ci::Build.count }.by(1)
                                .and change { BuildQueueWorker.jobs.count }.by(1)
        end
      end

      context 'when there are subsequent jobs that are skipped' do
        let!(:subsequent_build) do
          create(:ci_build, :skipped, pipeline: pipeline, ci_stage: deploy_stage)
        end

        let!(:subsequent_bridge) do
          create(:ci_bridge, :skipped, pipeline: pipeline, ci_stage: deploy_stage)
        end

        it 'does not cause an N+1 when updating the job ownership' do
          control = ActiveRecord::QueryRecorder.new(skip_cached: false) { service.execute(job) }

          create_list(:ci_build, 2, :skipped, pipeline: pipeline, ci_stage: deploy_stage)

          expect { service.execute(job) }.not_to exceed_all_query_limit(control)
        end
      end

      context 'when given variables' do
        let(:new_job) { service.clone!(job, variables: job_variables_attributes) }

        context 'when the build is actionable' do
          let_it_be_with_refind(:job) { create(:ci_build, :actionable, pipeline: pipeline) }

          it 'gives variables to the new build' do
            expect(new_job.job_variables.count).to be(1)
            expect(new_job.job_variables.first.key).to eq('MANUAL_VAR')
            expect(new_job.job_variables.first.value).to eq('manual test var')
            expect(new_job.job_variables.first.project_id).to eq(job.project_id)
          end
        end

        context 'when the build is not actionable' do
          let_it_be_with_refind(:job) { create(:ci_build, pipeline: pipeline) }

          it 'does not give variables to the new build' do
            expect(new_job.job_variables.count).to be_zero
          end
        end
      end
    end

    context 'when job being retried has jobs in previous stages' do
      let!(:job) do
        create(
          :ci_build,
          :failed,
          name: 'deploy_a',
          pipeline: pipeline,
          ci_stage: deploy_stage
        )
      end

      before do
        create(
          :ci_build,
          previous_stage_job_status,
          name: 'test_a',
          pipeline: pipeline,
          ci_stage: stage
        )
      end

      where(:previous_stage_job_status, :after_status) do
        :created   | 'created'
        :pending   | 'created'
        :running   | 'created'
        :manual    | 'created'
        :scheduled | 'created'
        :success   | 'pending'
        :failed    | 'skipped'
        :skipped   | 'pending'
      end

      with_them do
        it 'updates the new job status to after_status' do
          expect(subject).to be_success
          expect(new_job.status).to eq after_status
        end
      end
    end

    context 'when job being retried has DAG dependencies' do
      let!(:job) do
        create(
          :ci_build,
          :failed,
          :dependent,
          name: 'deploy_a',
          pipeline: pipeline,
          ci_stage: deploy_stage,
          needed: dependency
        )
      end

      let(:dependency) do
        create(
          :ci_build,
          dag_dependency_status,
          name: 'test_a',
          pipeline: pipeline,
          ci_stage: stage
        )
      end

      where(:dag_dependency_status, :after_status) do
        :created   | 'created'
        :pending   | 'created'
        :running   | 'created'
        :manual    | 'created'
        :scheduled | 'created'
        :success   | 'pending'
        :failed    | 'skipped'
        :skipped   | 'skipped'
      end

      with_them do
        it 'updates the new job status to after_status' do
          expect(subject).to be_success
          expect(new_job.status).to eq after_status
        end
      end
    end

    context 'when there are other manual/scheduled jobs' do
      let_it_be(:test_manual_build) do
        create(:ci_build, :manual, pipeline: pipeline, ci_stage: stage)
      end

      let_it_be(:subsequent_manual_build) do
        create(:ci_build, :manual, pipeline: pipeline, ci_stage: deploy_stage)
      end

      let_it_be(:test_scheduled_build) do
        create(:ci_build, :scheduled, pipeline: pipeline, ci_stage: stage)
      end

      let_it_be(:subsequent_scheduled_build) do
        create(:ci_build, :scheduled, pipeline: pipeline, ci_stage: deploy_stage)
      end

      let!(:job) do
        create(:ci_build, *[trait].compact, :failed, pipeline: pipeline, ci_stage: stage)
      end

      where(:trait, :enqueue_immediately) do
        nil                | false
        :manual            | true
        :expired_scheduled | true
      end

      with_them do
        it 'retries the given job but not the other manual/scheduled jobs' do
          expect { subject }
            .to change { Ci::Build.count }.by(1)
            .and not_change { test_manual_build.reload.status }
            .and not_change { subsequent_manual_build.reload.status }
            .and not_change { test_scheduled_build.reload.status }
            .and not_change { subsequent_scheduled_build.reload.status }

          expect(new_job).to be_pending
        end

        it_behaves_like 'checks enqueue_immediately?'
      end
    end
  end
end
