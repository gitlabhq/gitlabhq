# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::Sessions do
  include_examples "redis_new_instance_shared_examples", 'sessions', Gitlab::Redis::SharedState
end
