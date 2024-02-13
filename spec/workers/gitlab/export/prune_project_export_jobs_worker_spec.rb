# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Export::PruneProjectExportJobsWorker, feature_category: :importers do
  subject(:worker) { described_class.new }

  describe '#perform' do
    it_behaves_like 'an idempotent worker'

    it 'executes PruneExpiredExportJobsService' do
      expect(Projects::ImportExport::PruneExpiredExportJobsService).to receive(:execute)

      worker.perform
    end
  end
end
