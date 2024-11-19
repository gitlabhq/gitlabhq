# frozen_string_literal: true

RSpec.shared_examples 'every metric definition' do
  include UsageDataHelpers

  let(:usage_ping) { Gitlab::Usage::ServicePingReport.for(output: :all_metrics_values, cached: false) }
  let(:ignored_usage_ping_key_patterns) do
    %w[
      testing_total_unique_counts
      user_auth_by_provider
      counts.groups_google_cloud_platform_artifact_registry_active
      counts.groups_inheriting_google_cloud_platform_artifact_registry_active
      counts.groups_inheriting_google_cloud_platform_workload_identity_federation_active
      counts.instances_google_cloud_platform_artifact_registry_active
      counts.instances_google_cloud_platform_workload_identity_federation_active
      counts.projects_inheriting_google_cloud_platform_artifact_registry_active
      counts.projects_inheriting_google_cloud_platform_workload_identity_federation_active
    ].freeze
  end

  let(:usage_ping_key_paths) do
    parse_usage_ping_keys(usage_ping)
      .flatten
      .grep_v(Regexp.union(ignored_usage_ping_key_patterns))
      .sort
  end

  let(:ignored_metric_files_key_patterns) do
    %w[
      ci_runners_online
      mock_ci
      mock_monitoring
      user_auth_by_provider
      p_ci_templates_5_min_production_app
      p_ci_templates_aws_cf_deploy_ec2
      p_ci_templates_auto_devops_build
      p_ci_templates_auto_devops_deploy
      p_ci_templates_auto_devops_deploy_latest
      p_ci_templates_implicit_auto_devops_build
      p_ci_templates_implicit_auto_devops_deploy_latest
      p_ci_templates_implicit_auto_devops_deploy
    ].freeze
  end

  let(:metric_files_key_paths) do
    Gitlab::Usage::MetricDefinition
      .definitions
      .reject { |_, v| v.status == 'removed' || v.key_path =~ Regexp.union(ignored_metric_files_key_patterns) }
      .keys
      .sort
  end

  let(:metric_files_with_schema) do
    Gitlab::Usage::MetricDefinition
      .definitions
      .select { |_, v| v.value_json_schema }
  end

  let(:expected_metric_files_key_paths) { metric_files_key_paths }

  # Recursively traverse nested Hash of a generated Usage Ping to return an Array of key paths
  # in the dotted format used in metric definition YAML files, e.g.: 'count.category.metric_name'
  def parse_usage_ping_keys(object, key_path = [])
    if object.is_a?(Hash) && !object_with_schema?(key_path.join('.'))
      object.each_with_object([]) do |(key, value), result|
        result.append parse_usage_ping_keys(value, key_path + [key])
      end
    else
      key_path.join('.')
    end
  end

  def object_with_schema?(key_path)
    metric_files_with_schema.key?(key_path)
  end

  before do
    allow(Gitlab::UsageData).to receive_messages(count: -1, distinct_count: -1, estimate_batch_distinct_count: -1,
      sum: -1)
    allow(Gitlab::UsageData).to receive(:alt_usage_data).and_wrap_original do |_m, *_args, **kwargs|
      kwargs[:fallback] || Gitlab::Utils::UsageData::FALLBACK
    end
    stub_licensed_features(requirements: true)
    stub_prometheus_queries
    stub_usage_data_connections
  end

  it 'is included in the Usage Ping hash structure' do
    msg = "see https://docs.gitlab.com/ee/development/internal_analytics/metrics/metrics_dictionary.html#metrics-added-dynamic-to-service-ping-payload"
    expect(expected_metric_files_key_paths).to match_array(usage_ping_key_paths), msg
  end

  it 'only uses .yml and .json formats from metric related files in (ee/)config/metrics directory' do
    metric_definition_format = '.yml'
    object_schema_format = '.json'
    allowed_formats = [metric_definition_format, object_schema_format]
    glob_paths = Gitlab::Usage::MetricDefinition.paths.map do |glob_path|
      File.join(File.dirname(glob_path), '*.*')
    end

    files_with_wrong_extensions = glob_paths.each_with_object([]) do |glob_path, array|
      Dir.glob(glob_path).each do |path|
        array << path unless allowed_formats.include? File.extname(path)
      end
    end

    msg = <<~MSG
    The only supported file extensions are: #{allowed_formats.join(', ')}.
    The following files has the wrong extension: #{files_with_wrong_extensions}"
    MSG

    expect(files_with_wrong_extensions).to be_empty, msg
  end

  describe 'metrics classes' do
    let(:parent_metric_classes) do
      [
        Gitlab::Usage::Metrics::Instrumentations::BaseMetric,
        Gitlab::Usage::Metrics::Instrumentations::GenericMetric,
        Gitlab::Usage::Metrics::Instrumentations::DatabaseMetric,
        Gitlab::Usage::Metrics::Instrumentations::RedisMetric,
        Gitlab::Usage::Metrics::Instrumentations::RedisHLLMetric,
        Gitlab::Usage::Metrics::Instrumentations::NumbersMetric,
        Gitlab::Usage::Metrics::Instrumentations::PrometheusMetric,
        Gitlab::Usage::Metrics::Instrumentations::TotalCountMetric
      ]
    end

    let(:ignored_classes) do
      Gitlab::Usage::Metrics::Instrumentations::UniqueUsersAllImportsMetric::IMPORTS_METRICS
    end

    def assert_uses_all_nested_classes(parent_module)
      parent_module.constants(false).each do |const_name|
        next if const_name == :TotalSumMetric # TODO: Remove when first metric is implemented

        constant = parent_module.const_get(const_name, false)
        next if parent_metric_classes.include?(constant) ||
          ignored_classes.include?(constant)

        case constant
        when Class
          metric_class_instance = instance_double(constant)
          expect(constant).to receive(:new).at_least(:once).and_return(metric_class_instance)
          allow(metric_class_instance).to receive(:available?).and_return(true)
          allow(metric_class_instance).to receive(:value).and_return(-1)
          expect(metric_class_instance).to receive(:value).at_least(:once)
        when Module
          assert_uses_all_nested_classes(constant)
        end
      end
    end

    it 'uses all metrics classes' do
      assert_uses_all_nested_classes(Gitlab::Usage::Metrics::Instrumentations)
      usage_ping
    end
  end

  context 'with value json schema' do
    it 'has a valid structure', :aggregate_failures do
      metric_files_with_schema.each do |key_path, metric|
        structure = usage_ping.dig(*key_path.split('.').map(&:to_sym))

        expect(structure).to match_metric_definition_schema(metric.value_json_schema)
      end
    end
  end
end
