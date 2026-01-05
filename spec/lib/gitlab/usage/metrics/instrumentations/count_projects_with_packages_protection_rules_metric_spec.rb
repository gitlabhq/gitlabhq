# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountProjectsWithPackagesProtectionRulesMetric, feature_category: :service_ping do
  let_it_be(:project1) { create(:project) }
  let_it_be(:project2) { create(:project) }
  let_it_be(:project3) { create(:project) }

  let(:expected_value) { 2 }
  let(:expected_query) do
    'SELECT COUNT(DISTINCT "packages_protection_rules"."project_id") FROM "packages_protection_rules"'
  end

  before_all do
    create(:package_protection_rule, project: project1, package_name_pattern: '@my_scope/package-1', package_type: :npm)
    create(:package_protection_rule, project: project1, package_name_pattern: '@my_scope/package-3', package_type: :npm)
    create(:package_protection_rule,
      project: project2,
      package_name_pattern: '@my_scope/package-2',
      package_type: :pypi)
    # Project 3 has no rules
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', data_source: 'database' }
end
