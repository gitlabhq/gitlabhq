# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.group.pipelineAnalytics', :aggregate_failures, :click_house, feature_category: :fleet_visibility do
  include GraphqlHelpers
  include ClickHouseHelpers

  let_it_be_with_reload(:group) { create(:group) } # NOTE: reload is necessary to compute traversal_ids
  # NOTE: reload is necessary to compute traversal_ids
  let_it_be_with_reload(:sub_group) do
    create(:group, parent: group)
  end

  # NOTE: reload is necessary to compute traversal_ids
  let_it_be_with_refind(:project) do
    create(:project, group: sub_group)
  end

  let_it_be(:reporter) { create(:user, reporter_of: group) }
  let_it_be(:guest) { create(:user, guest_of: group) }
  let_it_be(:pipelines_data) do
    current_time = Time.utc(2024, 5, 11)

    [
      [:running, 35.minutes.before(current_time), 30.minutes, 'main', :pipeline],
      [:success, 1.day.before(current_time), 30.minutes, 'main2', :push],
      [:failed, 5.days.before(current_time), 2.hours, 'main', :pipeline],
      [:canceled, 4.5.days.before(current_time), 30.minutes, 'main', :pipeline],
      [:failed, 1.week.before(current_time), 45.minutes, 'main', :pipeline],
      [:skipped, 7.months.before(current_time), 45.minutes, 'main', :pipeline]
    ]
  end

  let(:simulated_current_time) { Time.current }
  let(:user) { reporter }
  let(:from_time) { nil }
  let(:to_time) { nil }
  let(:source) { nil }
  let(:ref) { nil }

  let(:period_fields) do
    <<~QUERY
      label
      all: count
      success: count(status: SUCCESS)
      failed: count(status: FAILED)
      other: count(status: OTHER)
    QUERY
  end

  let(:query) do
    graphql_query_for(
      :group, { full_path: sub_group.full_path }, # Query for sub_group to ensure traversal_path filtering works
      query_graphql_field(
        :pipeline_analytics, { from_time: from_time, to_time: to_time, ref: ref, source: source }.compact,
        fields)
    )
  end

  before do
    travel_to simulated_current_time
  end

  subject(:perform_request) do
    post_graphql(query, current_user: user)
  end

  it_behaves_like 'pipeline analytics graphql query', :group
end
