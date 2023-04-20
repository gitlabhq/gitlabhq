# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Subscriptions::ActionCableWithLoadBalancing, feature_category: :shared do
  let(:session_class) { ::Gitlab::Database::LoadBalancing::Session }
  let(:session) { instance_double(session_class) }
  let(:event) { instance_double(::GraphQL::Subscriptions::Event) }

  subject(:subscriptions) { described_class.new(schema: GitlabSchema) }

  it 'forces use of DB primary when executing subscription updates' do
    expect(session_class).to receive(:current).and_return(session)
    expect(session).to receive(:use_primary!)

    subscriptions.execute_update('sub:123', event, {})
  end
end
