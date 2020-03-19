# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Graphql::Pagination::OffsetActiveRecordRelationConnection do
  it 'subclasses from GraphQL::Relay::RelationConnection' do
    expect(described_class.superclass).to eq GraphQL::Relay::RelationConnection
  end
end
