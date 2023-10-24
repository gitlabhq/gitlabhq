# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SwapColumnsForCiPipelinesPipelineIdBigintV2, feature_category: :continuous_integration do
  context 'when auto_canceled_by_id sql type is integer' do
    before do
      active_record_base.connection.execute(<<~SQL)
        ALTER TABLE ci_pipelines ALTER COLUMN auto_canceled_by_id TYPE integer;
        ALTER TABLE ci_pipelines ALTER COLUMN auto_canceled_by_id_convert_to_bigint TYPE bigint;
      SQL
    end

    it_behaves_like(
      'swap conversion columns',
      table_name: :ci_pipelines,
      from: :auto_canceled_by_id,
      to: :auto_canceled_by_id_convert_to_bigint
    )
  end

  context 'when auto_canceled_by_id sql type is bigint' do
    before do
      active_record_base.connection.execute(<<~SQL)
        ALTER TABLE ci_pipelines ALTER COLUMN auto_canceled_by_id TYPE bigint;
        ALTER TABLE ci_pipelines ALTER COLUMN auto_canceled_by_id_convert_to_bigint TYPE integer;
      SQL
    end

    it 'does nothing' do
      recorder = ActiveRecord::QueryRecorder.new { migrate! }
      expect(recorder.log).not_to include(/LOCK TABLE/)
      expect(recorder.log).not_to include(/ALTER TABLE/)
    end
  end
end
