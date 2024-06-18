# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillMlExperimentMetadataProjectId,
  feature_category: :mlops,
  schema: 20240604074200 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :ml_experiment_metadata }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :ml_experiments }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :experiment_id }
  end
end
