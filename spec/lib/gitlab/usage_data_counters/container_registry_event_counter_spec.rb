# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::ContainerRegistryEventCounter, :clean_gitlab_redis_shared_state,
  feature_category: :container_registry do
  described_class::KNOWN_EVENTS.each do |event|
    it_behaves_like 'a redis usage counter', 'ContainerRegistryEvent', event
    it_behaves_like 'a redis usage counter with totals', :container_registry_events, "#{event}": 5
  end
end
