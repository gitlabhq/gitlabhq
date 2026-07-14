# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountProjectsWithMonitorEnabledMetric,
  feature_category: :observability do
  # `freeze: false` is required here: this `let_it_be` subject is mutated
  # in-memory across examples in a way that survives both
  # `let_it_be_with_reload` and `let_it_be_with_refind` (e.g. a memoized
  # association/collection or a non-persisted attribute). Keeping it unfrozen
  # is the only correct cure (see gitlab-org/gitlab#602925).
  let_it_be(:projects, freeze: false) { create_list(:project, 3) }

  let(:expected_value) { 2 }
  let(:expected_query) do
    'SELECT COUNT("project_features"."id") FROM "project_features" WHERE "project_features"."monitor_access_level" != 0'
  end

  before_all do
    # Monitor feature cannot have public visibility level. Therefore `ProjectFeature::PUBLIC` is missing here
    projects[0].project_feature.update!(monitor_access_level: ProjectFeature::DISABLED)
    projects[1].project_feature.update!(monitor_access_level: ProjectFeature::PRIVATE)
    projects[2].project_feature.update!(monitor_access_level: ProjectFeature::ENABLED)
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all' }
end
