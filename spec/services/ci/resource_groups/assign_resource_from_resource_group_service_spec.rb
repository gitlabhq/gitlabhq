# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ResourceGroups::AssignResourceFromResourceGroupService, feature_category: :continuous_integration do
  include ConcurrentHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:service) { described_class.new(project, user) }

  describe '#execute' do
    subject { service.execute(resource_group) }

    let(:resource_group) { create(:ci_resource_group, project: project) }
    let!(:build) { create(:ci_build, :waiting_for_resource, project: project, user: user, resource_group: resource_group) }

    context 'when there is an available resource' do
      it 'requests resource' do
        subject

        expect(build.reload).to be_pending
        expect(build.resource).to be_present
      end

      context 'when failed to request resource' do
        before do
          allow_next_instance_of(Ci::Build) do |build|
            allow(build).to receive(:enqueue_waiting_for_resource) { false }
          end
        end

        it 'has a build waiting for resource' do
          subject

          expect(build).to be_waiting_for_resource
        end
      end

      context 'when the build has already retained a resource' do
        before do
          resource_group.assign_resource_to(build)
          build.update_column(:status, :pending)
        end

        it 'has a pending build' do
          subject

          expect(build).to be_pending
        end
      end

      context 'when process mode is oldest_first' do
        let(:resource_group) { create(:ci_resource_group, process_mode: :oldest_first, project: project) }

        it 'requests resource' do
          subject

          expect(build.reload).to be_pending
          expect(build.resource).to be_present
        end

        context 'when the other job exists in the newer pipeline' do
          let!(:build_2) { create(:ci_build, :waiting_for_resource, project: project, user: user, resource_group: resource_group) }

          it 'requests resource for the job in the oldest pipeline' do
            subject

            expect(build.reload).to be_pending
            expect(build.resource).to be_present
            expect(build_2.reload).to be_waiting_for_resource
            expect(build_2.resource).to be_nil
          end
        end

        context 'when build is not `waiting_for_resource` state' do
          let!(:build) { create(:ci_build, :created, project: project, user: user, resource_group: resource_group) }

          it 'attempts to request a resource' do
            expect_next_found_instance_of(Ci::Build) do |job|
              expect(job).to receive(:enqueue_waiting_for_resource).and_call_original
            end

            subject
          end

          it 'does not change the job status' do
            subject

            expect(build.reload).to be_created
            expect(build.resource).to be_nil
          end
        end
      end

      context 'when process mode is newest_first' do
        let(:resource_group) { create(:ci_resource_group, process_mode: :newest_first, project: project) }

        it 'requests resource' do
          subject

          expect(build.reload).to be_pending
          expect(build.resource).to be_present
        end

        context 'when the other job exists in the newer pipeline' do
          let!(:build_2) { create(:ci_build, :waiting_for_resource, project: project, user: user, resource_group: resource_group) }

          it 'requests resource for the job in the newest pipeline' do
            subject

            expect(build.reload).to be_waiting_for_resource
            expect(build.resource).to be_nil
            expect(build_2.reload).to be_pending
            expect(build_2.resource).to be_present
          end
        end

        context 'when build is not `waiting_for_resource` state' do
          let!(:build) { create(:ci_build, :created, project: project, user: user, resource_group: resource_group) }

          it 'attempts to request a resource' do
            expect_next_found_instance_of(Ci::Build) do |job|
              expect(job).to receive(:enqueue_waiting_for_resource).and_call_original
            end

            subject
          end

          it 'does not change the job status' do
            subject

            expect(build.reload).to be_created
            expect(build.resource).to be_nil
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
          expect(build.reload).to be_pending
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

        expect(build.reload).to be_waiting_for_resource
      end

      context 'when there is a stale build assigned to a resource' do
        before do
          other_build.doom!
          other_build.update_column(:updated_at, 10.minutes.ago)
        end

        it 'releases the resource from the stale build and assignes to the waiting build' do
          subject

          expect(build.reload).to be_pending
          expect(build.resource).to be_present
        end
      end
    end
  end
end
