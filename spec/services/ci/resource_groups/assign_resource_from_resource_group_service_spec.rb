# frozen_string_literal: true

require 'spec_helper'

describe Ci::ResourceGroups::AssignResourceFromResourceGroupService do
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
    end

    context 'when there are no available resources' do
      before do
        resource_group.assign_resource_to(create(:ci_build))
      end

      it 'does not request resource' do
        expect_any_instance_of(Ci::Build).not_to receive(:enqueue_waiting_for_resource)

        subject
      end
    end
  end
end
