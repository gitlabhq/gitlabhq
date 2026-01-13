# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountPackagesProtectionRulesMetric, feature_category: :service_ping do
  let_it_be(:project) { create(:project) }

  let(:expected_value) { 2 }
  let(:expected_query) do
    'SELECT COUNT("packages_protection_rules"."id") FROM "packages_protection_rules"'
  end

  before_all do
    create(:package_protection_rule, project: project, package_name_pattern: '@my_scope/package-1', package_type: :npm)
    create(:package_protection_rule, project: project, package_name_pattern: '@my_scope/package-2', package_type: :pypi)
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', data_source: 'database' }
end
