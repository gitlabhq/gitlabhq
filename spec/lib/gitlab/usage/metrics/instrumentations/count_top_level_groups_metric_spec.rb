# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountTopLevelGroupsMetric, feature_category: :groups_and_projects do
  let_it_be(:top_level_group) { create(:group) }
  let_it_be(:subgroup) { create(:group, :nested) }
  let_it_be(:project_in_group_namespace) { create(:project, group: subgroup) }
  let_it_be(:project_in_user_namespace) { create(:project) }
  let(:expected_value) { 2 }

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }
end
