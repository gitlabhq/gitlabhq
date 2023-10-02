# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::QueuesMetadata, feature_category: :redis do
  include_examples "redis_new_instance_shared_examples", 'queues_metadata', Gitlab::Redis::Queues
  include_examples "redis_shared_examples"
end
