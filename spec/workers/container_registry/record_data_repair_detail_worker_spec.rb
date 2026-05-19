# frozen_string_literal: true

require 'spec_helper'

# This worker is deprecated and scheduled for removal in 19.2. It is kept as a
# no-op for one release so that jobs still present in Redis (queued, retry,
# dead, or scheduled sets) can be drained by Sidekiq without raising NameError.
# See https://docs.gitlab.com/ee/development/sidekiq/compatibility_across_updates.html#removing-worker-classes
RSpec.describe ContainerRegistry::RecordDataRepairDetailWorker, feature_category: :container_registry do
  it 'is a no-op' do
    expect { described_class.new.perform }.not_to raise_error
    expect { described_class.new.perform('arg') }.not_to raise_error
  end
end
