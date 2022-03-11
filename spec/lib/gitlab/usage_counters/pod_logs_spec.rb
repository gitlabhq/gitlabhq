# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageCounters::PodLogs, :clean_gitlab_redis_shared_state do
  it_behaves_like 'a usage counter'
end
