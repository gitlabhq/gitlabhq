# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountProjectsWithContainerRegistryProtectedTagRulesMetric, feature_category: :service_ping do
  let_it_be(:project1) { create(:project) }
  let_it_be(:project2) { create(:project) }
  let_it_be(:project3) { create(:project) }

  let(:expected_value) { 2 }
  let(:expected_query) do
    'SELECT COUNT(DISTINCT "container_registry_protection_tag_rules"."project_id") ' \
      'FROM "container_registry_protection_tag_rules" ' \
      'WHERE "container_registry_protection_tag_rules"."minimum_access_level_for_push" IS NOT NULL ' \
      'AND "container_registry_protection_tag_rules"."minimum_access_level_for_delete" IS NOT NULL'
  end

  before_all do
    create(:container_registry_protection_tag_rule, project: project1, tag_name_pattern: 'v.+')
    create(:container_registry_protection_tag_rule, project: project2, tag_name_pattern: 'release-.*')
    # Project 3 has no rules
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', data_source: 'database' }
end
