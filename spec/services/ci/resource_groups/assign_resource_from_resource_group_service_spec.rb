# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ResourceGroups::AssignResourceFromResourceGroupService, feature_category: :continuous_integration do
  include ConcurrentHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:service) { described_class.new(project, user) }

  before do
    allow(Ci::ResourceGroups::AssignResourceFromResourceGroupWorker).to receive(:perform_in)
  end

  describe '#execute' do
    subject { service.execute(resource_group) }

    let(:resource_group) { create(:ci_resource_group, project: project) }
    let!(:ci_build) { create(:ci_build, :waiting_for_resource, project: project, user: user, resource_group: resource_group) }

    context 'when there is an available resource' do
      it 'requests resource' do
        subject

        expect(ci_build.reload).to be_pending
        expect(ci_build.resource).to be_present
      end

      context 'when failed to request resource' do
        before do
          allow_next_instance_of(Ci::Build) do |job|
            allow(job).to receive(:enqueue_waiting_for_resource) { false }
          end
        end

        it 'has a build waiting for resource' do
          subject

          expect(ci_build).to be_waiting_for_resource
        end
      end

      context 'when the build has already retained a resource' do
        before do
          resource_group.assign_resource_to(ci_build)
          ci_build.update_column(:status, :pending)
        end

        it 'has a pending build' do
          subject

          expect(ci_build).to be_pending
        end
      end

      context 'when process mode is oldest_first' do
        let(:resource_group) { create(:ci_resource_group, process_mode: :oldest_first, project: project) }

        it 'requests resource' do
          subject

          expect(ci_build.reload).to be_pending
          expect(ci_build.resource).to be_present
        end

        context 'when the other job exists in the newer pipeline' do
          let!(:ci_build_2) { create(:ci_build, :waiting_for_resource, project: project, user: user, resource_group: resource_group) }

          it 'requests resource for the job in the oldest pipeline' do
            subject

            expect(ci_build.reload).to be_pending
            expect(ci_build.resource).to be_present
            expect(ci_build_2.reload).to be_waiting_for_resource
            expect(ci_build_2.resource).to be_nil
          end
        end

        context 'when build is not `waiting_for_resource` state' do
          let!(:ci_build) { create(:ci_build, :created, project: project, user: user, resource_group: resource_group) }

          it 'attempts to request a resource' do
            expect_next_found_instance_of(Ci::Build) do |job|
              expect(job).to receive(:enqueue_waiting_for_resource).and_call_original
            end

            subject
          end

          it 'does not change the job status' do
            subject

            expect(ci_build.reload).to be_created
            expect(ci_build.resource).to be_nil
          end
        end
      end

      context 'when process mode is newest_first' do
        let(:resource_group) { create(:ci_resource_group, process_mode: :newest_first, project: project) }

        it 'requests resource' do
          subject

          expect(ci_build.reload).to be_pending
          expect(ci_build.resource).to be_present
        end

        context 'when the other job exists in the newer pipeline' do
          let!(:ci_build_2) { create(:ci_build, :waiting_for_resource, project: project, user: user, resource_group: resource_group) }

          it 'requests resource for the job in the newest pipeline' do
            subject

            expect(ci_build.reload).to be_waiting_for_resource
            expect(ci_build.resource).to be_nil
            expect(ci_build_2.reload).to be_pending
            expect(ci_build_2.resource).to be_present
          end
        end

        context 'when build is not `waiting_for_resource` state' do
          let!(:ci_build) { create(:ci_build, :created, project: project, user: user, resource_group: resource_group) }

          it 'attempts to request a resource' do
            expect_next_found_instance_of(Ci::Build) do |job|
              expect(job).to receive(:enqueue_waiting_for_resource).and_call_original
            end

            subject
          end

          it 'does not change the job status' do
            subject

            expect(ci_build.reload).to be_created
            expect(ci_build.resource).to be_nil
          end
        end
      end

      context 'when parallel services are running' do
        it 'can run the same command in parallel' do
          parallel_num = 4

          blocks = Array.new(parallel_num).map do
            -> { subject }
          end

          run_parallel(blocks)
          expect(ci_build.reload).to be_pending
        end
      end

      context "when project is configured to 'prevent outdated deployments'" do
        before do
          allow(project).to receive(:ci_forward_deployment_enabled?).and_return(true)
        end

        context 'when build is not a deployable' do
          it 'enqueues the build' do
            subject

            expect(ci_build.reload).to be_pending
          end
        end

        context 'when build is a deployable' do
          let!(:environment) { create(:environment, name: 'prod', project: project) }
          let!(:ci_build) { create_deploy_job_with_persisted_deployment(user, project, resource_group, environment.name, 'waiting_for_resource') }

          it 'enqueues the build' do
            subject

            expect(ci_build.reload).to be_pending
          end

          context 'when build has an outdated deployment' do
            before do
              create_deploy_job_with_persisted_deployment(user, project, resource_group, environment.name, 'success')
            end

            it 'drops the build with a reason of `failed_outdated_deployment_job`' do
              subject

              ci_build.reload

              expect(ci_build).to be_failed
              expect(ci_build.failure_reason).to eq 'failed_outdated_deployment_job'
            end
          end
        end
      end
    end

    context 'when there are no available resources' do
      let!(:other_build) { create(:ci_build) }

      before do
        resource_group.assign_resource_to(other_build)
      end

      it 'does not request resource' do
        expect_any_instance_of(Ci::Build).not_to receive(:enqueue_waiting_for_resource)

        subject

        expect(ci_build.reload).to be_waiting_for_resource
      end

      it 'does not re-spawn the new worker for assigning a resource' do
        expect(Ci::ResourceGroups::AssignResourceFromResourceGroupWorker).not_to receive(:perform_in)

        subject
      end

      context 'when there is a stale build assigned to a resource' do
        before do
          other_build.doom!
          other_build.update_column(:updated_at, 10.minutes.ago)
        end

        it 'releases the resource from the stale build and assignes to the waiting build' do
          subject

          expect(ci_build.reload).to be_pending
          expect(ci_build.resource).to be_present
        end
      end
    end
  end

  def create_deploy_job_with_persisted_deployment(user, project, resource_group, environment_name, status)
    pipeline = create(:ci_empty_pipeline, sha: OpenSSL::Digest::SHA256.hexdigest(SecureRandom.hex))

    deploy_job = create(
      :ci_build,
      :deploy_job,
      project: project,
      user: user,
      resource_group: resource_group,
      status: status,
      environment: environment_name,
      pipeline: pipeline,
      ref: pipeline.ref
    )

    deployment_status = status == 'success' ? 'success' : 'created'
    deployment = create_persisted_deployment(deploy_job, deployment_status)

    deploy_job.association(:deployment).target = deployment
    deploy_job.save!

    deploy_job
  end

  def create_persisted_deployment(deploy_job, status)
    deployment = build(
      :deployment,
      user: user,
      project: project,
      environment: deploy_job.actual_persisted_environment,
      deployable: deploy_job,
      ref: deploy_job.ref,
      sha: deploy_job.sha,
      tag: deploy_job.tag,
      status: status
    )

    # Deployment validates the existence of project.commit records for sha and ref
    #   but the Commit factory does not allow commit records to be persisted.
    #   To avoid validation errors for unpersisted project.commits, we set validate=false
    deployment.save!(validate: false)

    deployment
  end
end
