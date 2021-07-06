# frozen_string_literal: true

RSpec.shared_context 'stubbed service ping metrics definitions' do
  include UsageDataHelpers

  let(:metrics_definitions) { standard_metrics + subscription_metrics + operational_metrics + optional_metrics }
  let(:standard_metrics) do
    [
      metric_attributes('uuid', "Standard")
    ]
  end

  let(:operational_metrics) do
    [
      metric_attributes('counts.merge_requests', "Operational"),
      metric_attributes('counts.todos', "Operational")
    ]
  end

  let(:optional_metrics) do
    [
      metric_attributes('counts.boards', "Optional"),
      metric_attributes('gitaly.filesystems', '').except('data_category')
    ]
  end

  before do
    stub_usage_data_connections
    stub_object_store_settings

    allow(Gitlab::Usage::MetricDefinition).to(
      receive(:definitions)
        .and_return(metrics_definitions.to_h { |definition| [definition['key_path'], Gitlab::Usage::MetricDefinition.new('', definition.symbolize_keys)] })
    )
  end

  def metric_attributes(key_path, category)
    {
      'key_path' => key_path,
      'data_category' => category
    }
  end
end
