# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::StatisticsRestorer, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let_it_be(:shared) { project.import_export_shared }

  subject(:restorer) { described_class.new(project: project, shared: shared) }

  describe '#restore' do
    it 'refreshes project statistics' do
      expect(project).to receive_message_chain(:statistics, :refresh!)

      restorer.restore
    end

    describe 'progress tracking' do
      it 'tracks refreshed statistics' do
        restorer.restore

        expect(
          restorer.processed_entry?(
            scope: { project_id: project.id },
            data: 'statistics_refresh'
          )
        ).to be(true)
      end

      context 'when statistics are already refreshed' do
        it 'does not refresh statistics again' do
          restorer.restore

          expect(restorer).not_to receive(:save_processed_entry)

          restorer.restore
        end
      end
    end
  end
end
