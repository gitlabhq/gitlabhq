# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::DistinctCountProjectsWithPackagesCleanupPolicyMetric,
  feature_category: :package_registry do
  before_all do
    create(:packages_cleanup_policy, keep_n_duplicated_package_files: 'all')
    create(:packages_cleanup_policy, keep_n_duplicated_package_files: 'all')
    create(:packages_cleanup_policy, keep_n_duplicated_package_files: '1')
    create(:packages_cleanup_policy, keep_n_duplicated_package_files: '10')
    create(:packages_cleanup_policy, keep_n_duplicated_package_files: '10')
    create(:packages_cleanup_policy, keep_n_duplicated_package_files: '10')
    create(:packages_cleanup_policy, keep_n_duplicated_package_files: '20')
    create(:packages_cleanup_policy, keep_n_duplicated_package_files: '30')
    create(:packages_cleanup_policy, keep_n_duplicated_package_files: '40')
    create(:packages_cleanup_policy, keep_n_duplicated_package_files: '50')
  end

  it_behaves_like 'a correct instrumented metric value and query',
    { time_frame: 'all', options: { keep_n_duplicated_package_files: 'all' } } do
    let(:expected_value) { 2 }
    let(:expected_query) do
      <<~SQL.squish
        SELECT COUNT(DISTINCT "packages_cleanup_policies"."project_id")
        FROM "packages_cleanup_policies"
        WHERE "packages_cleanup_policies"."keep_n_duplicated_package_files" = 'all'
      SQL
    end
  end

  it_behaves_like 'a correct instrumented metric value and query',
    { time_frame: 'all', options: { keep_n_duplicated_package_files: '1' } } do
    let(:expected_value) { 1 }
    let(:expected_query) do
      <<~SQL.squish
        SELECT COUNT(DISTINCT "packages_cleanup_policies"."project_id")
        FROM "packages_cleanup_policies"
        WHERE "packages_cleanup_policies"."keep_n_duplicated_package_files" = '1'
      SQL
    end
  end

  it_behaves_like 'a correct instrumented metric value and query',
    { time_frame: 'all', options: { keep_n_duplicated_package_files: '10' } } do
    let(:expected_value) { 3 }
    let(:expected_query) do
      <<~SQL.squish
        SELECT COUNT(DISTINCT "packages_cleanup_policies"."project_id")
        FROM "packages_cleanup_policies"
        WHERE "packages_cleanup_policies"."keep_n_duplicated_package_files" = '10'
      SQL
    end
  end

  it_behaves_like 'a correct instrumented metric value and query',
    { time_frame: 'all', options: { keep_n_duplicated_package_files: '20' } } do
    let(:expected_value) { 1 }
    let(:expected_query) do
      <<~SQL.squish
        SELECT COUNT(DISTINCT "packages_cleanup_policies"."project_id")
        FROM "packages_cleanup_policies"
        WHERE "packages_cleanup_policies"."keep_n_duplicated_package_files" = '20'
      SQL
    end
  end

  it_behaves_like 'a correct instrumented metric value and query',
    { time_frame: 'all', options: { keep_n_duplicated_package_files: '30' } } do
    let(:expected_value) { 1 }
    let(:expected_query) do
      <<~SQL.squish
        SELECT COUNT(DISTINCT "packages_cleanup_policies"."project_id")
        FROM "packages_cleanup_policies"
        WHERE "packages_cleanup_policies"."keep_n_duplicated_package_files" = '30'
      SQL
    end
  end

  it_behaves_like 'a correct instrumented metric value and query',
    { time_frame: 'all', options: { keep_n_duplicated_package_files: '40' } } do
    let(:expected_value) { 1 }
    let(:expected_query) do
      <<~SQL.squish
        SELECT COUNT(DISTINCT "packages_cleanup_policies"."project_id")
        FROM "packages_cleanup_policies"
        WHERE "packages_cleanup_policies"."keep_n_duplicated_package_files" = '40'
      SQL
    end
  end

  it_behaves_like 'a correct instrumented metric value and query',
    { time_frame: 'all', options: { keep_n_duplicated_package_files: '50' } } do
    let(:expected_value) { 1 }
    let(:expected_query) do
      <<~SQL.squish
        SELECT COUNT(DISTINCT "packages_cleanup_policies"."project_id")
        FROM "packages_cleanup_policies"
        WHERE "packages_cleanup_policies"."keep_n_duplicated_package_files" = '50'
      SQL
    end
  end
end
