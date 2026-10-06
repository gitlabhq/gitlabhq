# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::FinalizePendingDetachPartitionsWorker, feature_category: :database do
  describe '#perform' do
    subject(:perform) { described_class.new.perform }

    it 'finalizes pending detach partitions' do
      expect(Gitlab::Database::Partitioning).to receive(:finalize_pending_detach_partitions)

      perform
    end

    context 'when ci_finalize_pending_detach_partitions_daily is disabled' do
      before do
        stub_feature_flags(ci_finalize_pending_detach_partitions_daily: false)
      end

      it 'does nothing' do
        expect(Gitlab::Database::Partitioning).not_to receive(:finalize_pending_detach_partitions)

        perform
      end
    end
  end
end
