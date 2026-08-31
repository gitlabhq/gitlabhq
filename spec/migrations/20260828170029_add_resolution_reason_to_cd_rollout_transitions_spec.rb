# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddResolutionReasonToCdRolloutTransitions,
  migration: :gitlab_main, feature_category: :continuous_delivery do
  describe '#up' do
    it 'adds the resolution_reason column with a length limit' do
      migrate!

      column = ActiveRecord::Base.connection.columns(:cd_rollout_transitions)
        .find { |c| c.name == 'resolution_reason' }

      expect(column).to be_present
      expect(column.sql_type).to eq('text')
      expect(column.null).to be true

      expect(
        ActiveRecord::Base.connection.check_constraints(:cd_rollout_transitions)
          .any? { |c| c.expression == 'char_length(resolution_reason) <= 2000' }
      ).to be true
    end
  end

  describe '#down' do
    it 'removes the resolution_reason column' do
      migrate!
      schema_migrate_down!

      column = ActiveRecord::Base.connection.columns(:cd_rollout_transitions)
        .find { |c| c.name == 'resolution_reason' }

      expect(column).to be_nil
    end
  end
end
