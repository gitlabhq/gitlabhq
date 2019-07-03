# frozen_string_literal: true

require 'rails_helper'

describe Gitlab::Importers::CommonMetrics::PrometheusMetric do
  let(:existing_group_titles) do
    ::PrometheusMetricEnums.group_details.each_with_object({}) do |(key, value), memo|
      memo[key] = value[:group_title]
    end
  end

  it 'group enum equals ::PrometheusMetric' do
    expect(described_class.groups).to eq(::PrometheusMetric.groups)
  end

  it '.group_titles equals ::PrometheusMetric' do
    expect(Gitlab::Importers::CommonMetrics::PrometheusMetricEnums.group_titles).to eq(existing_group_titles)
  end
end
