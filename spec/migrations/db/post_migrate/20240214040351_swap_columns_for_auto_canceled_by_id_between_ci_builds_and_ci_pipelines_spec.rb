# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SwapColumnsForAutoCanceledByIdBetweenCiBuildsAndCiPipelines, feature_category: :continuous_integration do
  it_behaves_like(
    'swap conversion columns',
    table_name: :p_ci_builds,
    from: :auto_canceled_by_id,
    to: :auto_canceled_by_id_convert_to_bigint,
    before_type: 'integer',
    after_type: 'bigint'
  )
end
