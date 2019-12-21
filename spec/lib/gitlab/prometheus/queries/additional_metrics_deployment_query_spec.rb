# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Prometheus::Queries::AdditionalMetricsDeploymentQuery do
  around do |example|
    Timecop.freeze(Time.local(2008, 9, 1, 12, 0, 0)) { example.run }
  end

  include_examples 'additional metrics query' do
    let(:project) { create(:project, :repository) }
    let(:deployment) { create(:deployment, environment: environment, project: project) }
    let(:query_params) { [deployment.id] }

    it 'queries using specific time' do
      expect(client).to receive(:query_range).with(anything,
                                                   start: (deployment.created_at - 30.minutes).to_f,
                                                   stop: (deployment.created_at + 30.minutes).to_f)

      expect(query_result).not_to be_nil
    end
  end
end
