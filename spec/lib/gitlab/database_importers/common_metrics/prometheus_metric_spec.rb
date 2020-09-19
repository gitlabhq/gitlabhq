# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DatabaseImporters::CommonMetrics::PrometheusMetric do
  it 'group enum equals ::PrometheusMetric' do
    expect(described_class.groups).to eq(::PrometheusMetric.groups)
  end

  it '.group_titles equals ::PrometheusMetric' do
    existing_group_titles = Enums::PrometheusMetric.group_details.transform_values do |value|
      value[:group_title]
    end
    expect(Gitlab::DatabaseImporters::CommonMetrics::PrometheusMetricEnums.group_titles).to eq(existing_group_titles)
  end
end
