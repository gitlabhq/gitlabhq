# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RetryJobService do
  let_it_be(:reporter) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) do
    create(:ci_pipeline, project: project,
           sha: 'b83d6e391c22777fca1ed3012fce84f633d7fed0')
  end

  let_it_be(:stage) do
    create(:ci_stage, project: project,
                             pipeline: pipeline,
                             name: 'test')
  end

  let(:user) { developer }

  let(:service) { described_class.new(project, user) }

  before_all do
    project.add_developer(developer)
    project.add_reporter(reporter)
  end

  shared_context 'retryable bridge' do
    let_it_be(:downstream_project) { create(:project, :repository) }

    let_it_be_with_refind(:job) do
      create(
        :ci_bridge, :success, pipeline: pipeline, downstream: downstream_project,
        description: 'a trigger job', stage_id: stage.id
      )
    end

    let_it_be(:job_to_clone) { job }

    before do
      job.update!(retried: false)
    end
  end

  shared_context 'retryable build' do
    let_it_be_with_refind(:job) { create(:ci_build, :success, pipeline: pipeline, stage_id: stage.id) }
    let_it_be(:another_pipeline) { create(:ci_empty_pipeline, project: project) }

    let_it_be(:job_to_clone) do
      create(:ci_build, :failed, :picked, :expired, :erased, :queued, :coverage, :tags,
            :allowed_to_fail, :on_tag, :triggered, :teardown_environment, :resource_group,
            description: 'my-job', stage: 'test', stage_id: stage.id,
            pipeline: pipeline, auto_canceled_by: another_pipeline,
            scheduled_at: 10.seconds.since)
    end

    before do
      job.update!(retried: false, status: :success)
      job_to_clone.update!(retried: false, status: :success)
    end
  end

  shared_examples_for 'clones the job' do
    let(:job) { job_to_clone }

    before_all do
      # Make sure that job has both `stage_id` and `stage`
      job_to_clone.update!(stage: 'test', stage_id: stage.id)

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
          create(:ci_build_need, build: job, name: 'build1')
          create(:ci_build_need, build: job, name: 'build2')
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

  shared_examples_for 'retries the job' do
    it_behaves_like 'clones the job'

    it 'enqueues the new job' do
      expect(new_job).to be_pending
    end

    context 'when there are subsequent processables that are skipped' do
      let!(:subsequent_build) do
        create(:ci_build, :skipped, stage_idx: 2,
                                    pipeline: pipeline,
                                    stage: 'deploy')
      end

      let!(:subsequent_bridge) do
        create(:ci_bridge, :skipped, stage_idx: 2,
                                      pipeline: pipeline,
                                      stage: 'deploy')
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
      let!(:stage2) { create(:ci_stage, project: project, pipeline: pipeline, name: 'deploy') }
      let!(:build2) { create(:ci_build, pipeline: pipeline, stage_id: stage.id ) }
      let!(:deploy) { create(:ci_build, pipeline: pipeline, stage_id: stage2.id) }
      let!(:deploy_needs_build2) { create(:ci_build_need, build: deploy, name: build2.name) }

      context 'when job has a nil scheduling_type' do
        before do
          job.pipeline.processables.update_all(scheduling_type: nil)
          job.reload
        end

        it 'populates scheduling_type of processables' do
          expect(new_job.scheduling_type).to eq('stage')
          expect(job.reload.scheduling_type).to eq('stage')
          expect(build2.reload.scheduling_type).to eq('stage')
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

  describe '#clone!' do
    let(:new_job) { service.clone!(job) }

    it 'raises an error when an unexpected class is passed' do
      expect { service.clone!(create(:ci_build).present) }.to raise_error(TypeError)
    end

    context 'when the job to be cloned is a bridge' do
      include_context 'retryable bridge'

      it_behaves_like 'clones the job'
    end

    context 'when the job to be cloned is a build' do
      include_context 'retryable build'

      let(:job) { job_to_clone }

      it_behaves_like 'clones the job'

      context 'when a build with a deployment is retried' do
        let!(:job) do
          create(:ci_build, :with_deployment, :deploy_to_production,
                  pipeline: pipeline, stage_id: stage.id, project: project)
        end

        it 'creates a new deployment' do
          expect { new_job }.to change { Deployment.count }.by(1)
        end

        it 'does not create a new environment' do
          expect { new_job }.not_to change { Environment.count }
        end
      end

      context 'when a build with a dynamic environment is retried' do
        let_it_be(:other_developer) { create(:user).tap { |u| project.add_developer(u) } }

        let(:environment_name) { 'review/$CI_COMMIT_REF_SLUG-$GITLAB_USER_ID' }

        let!(:job) do
          create(:ci_build, :with_deployment, environment: environment_name,
                options: { environment: { name: environment_name } },
                pipeline: pipeline, stage_id: stage.id, project: project,
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
  end

  describe '#execute' do
    let(:new_job) { service.execute(job)[:job] }

    context 'when the job to be retried is a bridge' do
      include_context 'retryable bridge'

      it_behaves_like 'retries the job'
    end

    context 'when the job to be retried is a build' do
      include_context 'retryable build'

      it_behaves_like 'retries the job'

      context 'when there are subsequent jobs that are skipped' do
        let!(:subsequent_build) do
          create(:ci_build, :skipped, stage_idx: 2,
                                      pipeline: pipeline,
                                      stage: 'deploy')
        end

        let!(:subsequent_bridge) do
          create(:ci_bridge, :skipped, stage_idx: 2,
                                       pipeline: pipeline,
                                       stage: 'deploy')
        end

        it 'does not cause an N+1 when updating the job ownership' do
          control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) { service.execute(job) }.count

          create_list(:ci_build, 2, :skipped, stage_idx: job.stage_idx + 1, pipeline: pipeline, stage: 'deploy')

          expect { service.execute(job) }.not_to exceed_all_query_limit(control_count)
        end
      end
    end
  end
end
