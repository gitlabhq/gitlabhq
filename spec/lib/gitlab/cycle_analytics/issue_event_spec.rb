require 'spec_helper'
require 'lib/gitlab/cycle_analytics/shared_event_spec'

describe Gitlab::CycleAnalytics::IssueEvent do
  it_behaves_like 'default query config' do
    it 'has the default order' do
      expect(event.order).to eq(event.start_time_attrs)
    end
  end
end
