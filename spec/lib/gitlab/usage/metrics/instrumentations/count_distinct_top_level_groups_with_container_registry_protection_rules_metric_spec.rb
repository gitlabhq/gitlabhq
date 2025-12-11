# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountDistinctTopLevelGroupsWithContainerRegistryProtectionRulesMetric, feature_category: :service_ping do
  let_it_be(:top_level_group1) { create(:group) }
  let_it_be(:top_level_group2) { create(:group) }
  let_it_be(:subgroup1) { create(:group, parent: top_level_group1) }
  let_it_be(:subgroup2) { create(:group, parent: top_level_group2) }
  let_it_be(:project1) { create(:project, namespace: top_level_group1) }
  let_it_be(:project2) { create(:project, namespace: subgroup1) }
  let_it_be(:project3) { create(:project, namespace: subgroup2) }

  let(:expected_value) { 2 }
  let(:expected_query) do
    'SELECT COUNT(DISTINCT "namespaces"."id") ' \
      'FROM "namespaces" ' \
      'WHERE "namespaces"."type" = \'Group\' ' \
      'AND "namespaces"."id" IN (' \
      'SELECT DISTINCT "namespaces".traversal_ids[1] ' \
      'FROM "namespaces" ' \
      'WHERE "namespaces"."type" = \'Group\' ' \
      'AND "namespaces"."id" IN (' \
      'SELECT "projects"."namespace_id" ' \
      'FROM "projects" ' \
      'WHERE "projects"."id" IN (' \
      'SELECT DISTINCT "container_registry_protection_rules"."project_id" ' \
      'FROM "container_registry_protection_rules")))'
  end

  before_all do
    create(:container_registry_protection_rule, project: project1)
    create(:container_registry_protection_rule, project: project2)
    create(:container_registry_protection_rule, project: project3)
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', data_source: 'database' }
end
