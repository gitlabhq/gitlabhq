# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'InstanceStatisticsMeasurements' do
  include GraphqlHelpers

  let(:current_user) { create(:user, :admin) }
  let!(:instance_statistics_measurement_1) { create(:instance_statistics_measurement, :project_count, recorded_at: 20.days.ago, count: 5) }
  let!(:instance_statistics_measurement_2) { create(:instance_statistics_measurement, :project_count, recorded_at: 10.days.ago, count: 10) }

  let(:arguments) { 'identifier: PROJECTS' }
  let(:query) { graphql_query_for(:instanceStatisticsMeasurements, arguments, 'nodes { count identifier }') }

  before do
    post_graphql(query, current_user: current_user)
  end

  it 'returns measurement objects' do
    expect(graphql_data.dig('instanceStatisticsMeasurements', 'nodes')).to eq([
      { "count" => 10, 'identifier' => 'PROJECTS' },
      { "count" => 5, 'identifier' => 'PROJECTS' }
    ])
  end

  context 'with recorded_at filters' do
    let(:arguments) { %(identifier: PROJECTS, recordedAfter: "#{15.days.ago.to_date}", recordedBefore: "#{5.days.ago.to_date}") }

    it 'returns filtered measurement objects' do
      expect(graphql_data.dig('instanceStatisticsMeasurements', 'nodes')).to eq([
        { "count" => 10, 'identifier' => 'PROJECTS' }
      ])
    end
  end
end
