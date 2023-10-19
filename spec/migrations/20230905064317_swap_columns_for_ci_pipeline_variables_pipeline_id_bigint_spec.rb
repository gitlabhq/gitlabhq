# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SwapColumnsForCiPipelineVariablesPipelineIdBigint, feature_category: :continuous_integration do
  it_behaves_like(
    'swap conversion columns',
    table_name: :ci_pipeline_variables,
    from: :pipeline_id,
    to: :pipeline_id_convert_to_bigint
  )
end
