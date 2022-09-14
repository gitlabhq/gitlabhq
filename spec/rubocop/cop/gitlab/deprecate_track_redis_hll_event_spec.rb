# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/deprecate_track_redis_hll_event'

RSpec.describe RuboCop::Cop::Gitlab::DeprecateTrackRedisHLLEvent do
  it 'does not flag the use of track_event' do
    expect_no_offenses('track_event :show, name: "p_analytics_insights"')
  end

  it 'flags the use of track_redis_hll_event' do
    expect_offense(<<~SOURCE)
      track_redis_hll_event :show, name: 'p_analytics_valuestream'
      ^^^^^^^^^^^^^^^^^^^^^ `track_redis_hll_event` is deprecated[...]
    SOURCE
  end
end
