# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountTopLevelGroupsRequiringTwoFactorAuthenticationMetric,
  feature_category: :system_access do
  let_it_be(:top_level_group_with_2fa) do
    create(:group, require_two_factor_authentication: true)
  end

  let_it_be(:another_top_level_group_with_2fa) do
    create(:group, require_two_factor_authentication: true)
  end

  let_it_be(:top_level_group_without_2fa) do
    create(:group, require_two_factor_authentication: false)
  end

  let_it_be(:subgroup_with_2fa) do
    create(:group, parent: top_level_group_with_2fa, require_two_factor_authentication: true)
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', data_source: 'database' } do
    let(:expected_value) { 2 }

    let(:expected_query) do
      'SELECT COUNT("namespaces"."id") FROM "namespaces" ' \
        'WHERE "namespaces"."type" = \'Group\' ' \
        'AND "namespaces"."parent_id" IS NULL ' \
        'AND "namespaces"."require_two_factor_authentication" = TRUE'
    end
  end
end
