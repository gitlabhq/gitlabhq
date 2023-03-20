# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuables::ClearGroupsIssueCounterWorker, feature_category: :team_planning do
  describe '#perform' do
    let_it_be(:user) { create(:user) }
    let_it_be(:parent_group) { create(:group) }
    let_it_be(:root_group) { create(:group, parent: parent_group) }
    let_it_be(:subgroup) { create(:group, parent: root_group) }

    let(:count_service) { Groups::OpenIssuesCountService }
    let(:instance1) { instance_double(count_service) }
    let(:instance2) { instance_double(count_service) }

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [[root_group.id]] }
      let(:exec_times) { IdempotentWorkerHelper::WORKER_EXEC_TIMES }

      it 'clears the cached issue count in given groups and ancestors' do
        expect(count_service).to receive(:new)
          .exactly(exec_times).times.with(root_group).and_return(instance1)
        expect(count_service).to receive(:new)
          .exactly(exec_times).times.with(parent_group).and_return(instance2)
        expect(count_service).not_to receive(:new).with(subgroup)

        [instance1, instance2].all? do |instance|
          expect(instance).to receive(:clear_all_cache_keys).exactly(exec_times).times
        end

        subject
      end
    end

    it 'does not call count service or rise error when group_ids is empty' do
      expect(count_service).not_to receive(:new)
      expect(Gitlab::ErrorTracking).not_to receive(:log_exception)

      described_class.new.perform([])
    end
  end
end
