# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountProjectsWithContainerRegistryProtectionRulesMetric, feature_category: :service_ping do
  let_it_be(:project1) { create(:project) }
  let_it_be(:project2) { create(:project) }
  let_it_be(:project3) { create(:project) }

  let(:expected_value) { 2 }
  let(:expected_query) do
    'SELECT COUNT(DISTINCT "container_registry_protection_rules"."project_id") ' \
      'FROM "container_registry_protection_rules"'
  end

  before_all do
    create(:container_registry_protection_rule, project: project1)
    create(:container_registry_protection_rule, project: project2)
    # Project 3 has no rules
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', data_source: 'database' }
end
