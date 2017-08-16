require 'spec_helper'

describe Gitlab::Prometheus::Queries::AdditionalMetricsEnvironmentQuery do
  around do |example|
    Timecop.freeze { example.run }
  end

  include_examples 'additional metrics query' do
    let(:query_params) { [environment.id] }

    it 'queries using specific time' do
      expect(client).to receive(:query_range).with(anything, start: 8.hours.ago.to_f, stop: Time.now.to_f)

      expect(query_result).not_to be_nil
    end
  end
end
