# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::UsageDataCounters::CycleAnalyticsCounter do
  it_behaves_like 'a redis usage counter', 'CycleAnalytics', :views

  it_behaves_like 'a redis usage counter with totals', :cycle_analytics, views: 3
end
