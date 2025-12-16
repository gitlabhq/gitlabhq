# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountContainerRegistryProtectionRulesMetric, feature_category: :service_ping do
  let_it_be(:project) { create(:project) }

  let(:expected_value) { 2 }
  let(:expected_query) do
    'SELECT COUNT("container_registry_protection_rules"."id") ' \
      'FROM "container_registry_protection_rules"'
  end

  before_all do
    create(:container_registry_protection_rule,
      project: project,
      repository_path_pattern: "#{project.full_path}/image-1")
    create(:container_registry_protection_rule,
      project: project,
      repository_path_pattern: "#{project.full_path}/image-2")
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', data_source: 'database' }
end
