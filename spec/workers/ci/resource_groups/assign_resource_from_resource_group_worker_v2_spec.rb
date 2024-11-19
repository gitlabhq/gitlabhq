# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ResourceGroups::AssignResourceFromResourceGroupWorkerV2, feature_category: :continuous_delivery do
  let(:worker) { described_class.new }

  it 'has the `until_executing` deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executing)
  end

  it 'has an option to reschedule once if deduplicated' do
    expect(described_class.get_deduplication_options).to include({ if_deduplicated: :reschedule_once })
  end

  it 'has an option to deduplicate scheduled jobs' do
    expect(described_class.get_deduplication_options).to include({ including_scheduled: true })
  end

  describe '#perform' do
    subject(:perform) { worker.perform(resource_group_id) }

    let(:resource_group) { create(:ci_resource_group) }
    let(:resource_group_id) { resource_group.id }

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [resource_group_id] }
    end

    context 'when resource group exists' do
      it 'does not execute AssignResourceFromResourceGroupService' do
        expect(Ci::ResourceGroups::AssignResourceFromResourceGroupService).not_to receive(:new)

        perform
      end
    end

    context 'when build does not exist' do
      let(:resource_group_id) { non_existing_record_id }

      it 'does not execute AssignResourceFromResourceGroupService' do
        expect(Ci::ResourceGroups::AssignResourceFromResourceGroupService).not_to receive(:new)

        perform
      end
    end
  end
end
