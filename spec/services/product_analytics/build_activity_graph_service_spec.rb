# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProductAnalytics::BuildActivityGraphService do
  let_it_be(:project) { create(:project) }
  let_it_be(:time_now) { Time.zone.now }
  let_it_be(:time_ago) { Time.zone.now - 5.days }

  let_it_be(:events) do
    [
      create(:product_analytics_event, project: project, collector_tstamp: time_now),
      create(:product_analytics_event, project: project, collector_tstamp: time_now),
      create(:product_analytics_event, project: project, collector_tstamp: time_now),
      create(:product_analytics_event, project: project, collector_tstamp: time_ago),
      create(:product_analytics_event, project: project, collector_tstamp: time_ago)
    ]
  end

  let(:params) { { timerange: 7 } }

  subject { described_class.new(project, params).execute }

  it 'returns a valid graph hash' do
    expected_hash = {
      id: 'collector_tstamp',
      keys: [time_ago.to_date, time_now.to_date],
      values: [2, 3]
    }

    expect(subject).to eq(expected_hash)
  end
end
