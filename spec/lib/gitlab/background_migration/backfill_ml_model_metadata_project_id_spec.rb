# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillMlModelMetadataProjectId,
  feature_category: :mlops,
  schema: 20240624142357 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :ml_model_metadata }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :ml_models }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :model_id }
  end
end
