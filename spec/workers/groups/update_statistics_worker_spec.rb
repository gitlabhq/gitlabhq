# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::UpdateStatisticsWorker, feature_category: :source_code_management do
  let_it_be(:group) { create(:group) }

  let(:statistics) { %w[wiki_size] }

  subject(:worker) { described_class.new }

  describe '#perform' do
    it 'updates the group statistics' do
      expect(Groups::UpdateStatisticsService).to receive(:new)
        .with(group, statistics: statistics)
        .and_call_original

      worker.perform(group.id, statistics)
    end

    context 'when group id does not exist' do
      it 'ends gracefully' do
        expect(Groups::UpdateStatisticsService).not_to receive(:new)

        expect { worker.perform(non_existing_record_id, statistics) }.not_to raise_error
      end
    end
  end
end
