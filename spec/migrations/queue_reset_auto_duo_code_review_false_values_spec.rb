# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueResetAutoDuoCodeReviewFalseValues, migration: :gitlab_main, feature_category: :code_review_workflow do
  let(:migration) { described_class.new }

  describe '#up' do
    it 'queues the background migration' do
      expect(migration).to receive(:queue_batched_background_migration).with(
        'ResetAutoDuoCodeReviewFalseValues',
        :project_settings,
        :project_id,
        batch_size: 50_000,
        sub_batch_size: 5_000
      )

      migration.up
    end
  end

  describe '#down' do
    it 'deletes the background migration' do
      expect(migration).to receive(:delete_batched_background_migration).with(
        'ResetAutoDuoCodeReviewFalseValues',
        :project_settings,
        :project_id,
        []
      )

      migration.down
    end
  end
end
