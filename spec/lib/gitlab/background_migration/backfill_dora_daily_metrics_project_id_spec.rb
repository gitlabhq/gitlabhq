# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDoraDailyMetricsProjectId,
  feature_category: :continuous_delivery,
  schema: 20240529185025 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :dora_daily_metrics }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :environments }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :environment_id }
  end
end
