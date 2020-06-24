# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::ProductivityAnalyticsCounter do
  it_behaves_like 'a redis usage counter', 'ProductivityAnalytics', :views

  it_behaves_like 'a redis usage counter with totals', :productivity_analytics, views: 3
end
