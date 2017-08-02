require 'spec_helper'

describe Gitlab::Prometheus::Queries::AdditionalMetricsEnvironmentQuery do
  include Prometheus::MetricBuilders

  let(:client) { double('prometheus_client') }
  let(:environment) { create(:environment, slug: 'environment-slug') }

  subject(:query_result) { described_class.new(client).query(environment.id) }

  around do |example|
    Timecop.freeze { example.run }
  end

  include_examples 'additional metrics query' do
    it 'queries using specific time' do
      expect(client).to receive(:query_range).with(anything, start: 8.hours.ago.to_f, stop: Time.now.to_f)
      expect(query_result).not_to be_nil
    end
  end
end
