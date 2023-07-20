# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountDeploymentsMetric, feature_category: :service_ping do
  using RSpec::Parameterized::TableSyntax

  before_all do
    env = create(:environment)
    [3, 60].each do |n|
      deployment_options = { created_at: n.days.ago, project: env.project, environment: env }
      create(:deployment, :failed, deployment_options)
      create(:deployment, :success, deployment_options)
      create(:deployment, :success, deployment_options)
    end
  end

  where(:type, :time_frame, :expected_value) do
    :all      | 'all'  | 6
    :all      | '28d'  | 3
    :success  | 'all'  | 4
    :success  | '28d'  | 2
    :failed   | 'all'  | 2
    :failed   | '28d'  | 1
  end

  with_them do
    expected_value = params[:expected_value] # rubocop: disable Lint/UselessAssignment
    time_frame = params[:time_frame]
    type = params[:type]

    it_behaves_like 'a correct instrumented metric value', { time_frame: time_frame, options: { type: type } }
  end
end
