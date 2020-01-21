# frozen_string_literal: true

require 'spec_helper'

describe Ci::ResourceGroups::AssignResourceFromResourceGroupWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform(resource_group_id) }

    context 'when resource group exists' do
      let(:resource_group) { create(:ci_resource_group) }
      let(:resource_group_id) { resource_group.id }

      it 'executes AssignResourceFromResourceGroupService' do
        expect_next_instance_of(Ci::ResourceGroups::AssignResourceFromResourceGroupService, resource_group.project, nil) do |service|
          expect(service).to receive(:execute).with(resource_group)
        end

        subject
      end
    end

    context 'when build does not exist' do
      let(:resource_group_id) { 123 }

      it 'does not execute AssignResourceFromResourceGroupService' do
        expect(Ci::ResourceGroups::AssignResourceFromResourceGroupService).not_to receive(:new)

        subject
      end
    end
  end
end
