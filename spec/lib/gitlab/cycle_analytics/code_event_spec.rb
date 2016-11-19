require 'spec_helper'
require 'lib/gitlab/cycle_analytics/shared_event_spec'

describe Gitlab::CycleAnalytics::CodeEvent do
  it_behaves_like 'default query config' do
    it 'does not have the default order' do
      expect(event.order).not_to eq(event.start_time_attrs)
    end
  end
end
