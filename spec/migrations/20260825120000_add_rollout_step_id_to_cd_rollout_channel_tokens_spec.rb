# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddRolloutStepIdToCdRolloutChannelTokens, migration: :gitlab_main,
  feature_category: :continuous_delivery do
  describe '#up' do
    it 'adds the rollout_step_id column with an index' do
      migrate!

      column = ActiveRecord::Base.connection.columns(:cd_rollout_channel_tokens)
        .find { |c| c.name == 'rollout_step_id' }

      expect(column).to be_present
      expect(column.sql_type).to eq('bigint')
      expect(column.null).to be true

      expect(
        ActiveRecord::Base.connection.index_exists?(
          :cd_rollout_channel_tokens, :rollout_step_id, name: described_class::INDEX_NAME
        )
      ).to be true
    end
  end

  describe '#down' do
    it 'removes the rollout_step_id column and its index' do
      migrate!
      schema_migrate_down!

      column = ActiveRecord::Base.connection.columns(:cd_rollout_channel_tokens)
        .find { |c| c.name == 'rollout_step_id' }

      expect(column).to be_nil
    end
  end
end
