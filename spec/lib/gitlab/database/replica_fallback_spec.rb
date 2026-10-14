# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::ReplicaFallback, feature_category: :database do
  subject(:helper) { Class.new { include Gitlab::Database::ReplicaFallback }.new }

  it 'runs the block with replica fallback for ambiguous queries' do
    Gitlab::Database::LoadBalancing::SessionMap.clear_session
    session = Gitlab::Database::LoadBalancing::SessionMap.current(ApplicationRecord.load_balancer)

    inside = helper.with_replica_fallback(ApplicationRecord) { session.fallback_to_replicas_for_ambiguous_queries? }

    expect(inside).to be(true)
  end
end
