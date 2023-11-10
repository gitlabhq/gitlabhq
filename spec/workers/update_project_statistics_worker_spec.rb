# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UpdateProjectStatisticsWorker, feature_category: :source_code_management do
  include ExclusiveLeaseHelpers

  let(:worker) { described_class.new }
  let(:project) { create(:project, :repository) }
  let(:statistics) { %w[repository_size] }
  let(:lease_key) { "namespace:namespaces_root_statistics:#{project.namespace_id}" }

  describe '#perform' do
    context 'when a lease could be obtained' do
      it 'updates the project statistics' do
        expect(Projects::UpdateStatisticsService).to receive(:new)
          .with(project, nil, statistics: statistics)
          .and_call_original

        worker.perform(lease_key, project.id, statistics)
      end
    end

    context 'when a lease could not be obtained' do
      before do
        stub_exclusive_lease_taken(lease_key, timeout: ProjectCacheWorker::LEASE_TIMEOUT)
      end

      it 'does not update the project statistics' do
        lease_key = "namespace:namespaces_root_statistics:#{project.namespace_id}"
        expect(Projects::UpdateStatisticsService).not_to receive(:new)

        worker.perform(lease_key, project.id, statistics)
      end
    end
  end
end
