# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'InstanceStatisticsMeasurements' do
  include GraphqlHelpers

  let(:current_user) { create(:user, :admin) }
  let!(:instance_statistics_measurement_1) { create(:instance_statistics_measurement, :project_count, recorded_at: 20.days.ago, count: 5) }
  let!(:instance_statistics_measurement_2) { create(:instance_statistics_measurement, :project_count, recorded_at: 10.days.ago, count: 10) }

  let(:query) { graphql_query_for(:instanceStatisticsMeasurements, 'identifier: PROJECTS', 'nodes { count identifier }') }

  before do
    post_graphql(query, current_user: current_user)
  end

  it 'returns measurement objects' do
    expect(graphql_data.dig('instanceStatisticsMeasurements', 'nodes')).to eq([
      { "count" => 10, 'identifier' => 'PROJECTS' },
      { "count" => 5, 'identifier' => 'PROJECTS' }
    ])
  end
end
