# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountDistinctNamespacesWithPackagesProtectionRulesMetric, feature_category: :service_ping do
  let_it_be(:namespace1) { create(:namespace) }
  let_it_be(:namespace2) { create(:namespace) }
  let_it_be(:project1) { create(:project, namespace: namespace1) }
  let_it_be(:project2) { create(:project, namespace: namespace1) }
  let_it_be(:project3) { create(:project, namespace: namespace2) }

  let(:expected_value) { 2 }
  let(:expected_query) do
    'SELECT COUNT(DISTINCT "namespaces"."id") ' \
      'FROM "packages_protection_rules" ' \
      'INNER JOIN "projects" ON "projects"."id" = "packages_protection_rules"."project_id" ' \
      'INNER JOIN "namespaces" ON "namespaces"."id" = "projects"."namespace_id"'
  end

  before_all do
    create(:package_protection_rule, project: project1, package_name_pattern: '@my_scope/package-1', package_type: :npm)
    # Same namespace as project1
    create(:package_protection_rule,
      project: project2,
      package_name_pattern: '@my_scope/package-2',
      package_type: :pypi)
    create(:package_protection_rule,
      project: project3,
      package_name_pattern: '@my_scope/package-3',
      package_type: :maven)
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', data_source: 'database' }
end
