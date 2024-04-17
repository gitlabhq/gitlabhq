# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ResourceGroups::AssignResourceFromResourceGroupWorker, feature_category: :continuous_delivery do
  let(:worker) { described_class.new }

  it 'has the `until_executed` deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
  end

  it 'has an option to reschedule once if deduplicated' do
    expect(described_class.get_deduplication_options).to include({ if_deduplicated: :reschedule_once })
  end

  it 'has an option to deduplicate scheduled jobs' do
    expect(described_class.get_deduplication_options).to include({ including_scheduled: true })
  end

  describe '#perform' do
    subject { worker.perform(resource_group_id) }

    let(:resource_group) { create(:ci_resource_group) }
    let(:resource_group_id) { resource_group.id }

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [resource_group_id] }
    end

    context 'when resource group exists' do
      it 'executes AssignResourceFromResourceGroupService' do
        expect_next_instance_of(Ci::ResourceGroups::AssignResourceFromResourceGroupService, resource_group.project, nil) do |service|
          expect(service).to receive(:execute).with(resource_group)
        end

        subject
      end
    end

    context 'when build does not exist' do
      let(:resource_group_id) { non_existing_record_id }

      it 'does not execute AssignResourceFromResourceGroupService' do
        expect(Ci::ResourceGroups::AssignResourceFromResourceGroupService).not_to receive(:new)

        subject
      end
    end
  end
end
