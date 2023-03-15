# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MigrateExternalDiffsWorker, feature_category: :code_review_workflow do
  let(:worker) { described_class.new }
  let(:diff) { create(:merge_request).merge_request_diff }

  describe '#perform' do
    it 'migrates the listed diff' do
      expect_next_instance_of(MergeRequests::MigrateExternalDiffsService) do |instance|
        expect(instance.diff).to eq(diff)
        expect(instance).to receive(:execute)
      end

      worker.perform(diff.id)
    end

    it 'does nothing if the diff is missing' do
      diff.destroy!

      worker.perform(diff.id)
    end
  end
end
