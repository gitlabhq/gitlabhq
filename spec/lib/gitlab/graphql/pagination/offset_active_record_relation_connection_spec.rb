# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Pagination::OffsetActiveRecordRelationConnection do
  let(:context) { instance_double(GraphQL::Query::Context, schema: GitlabSchema) }

  it 'subclasses from GraphQL::Relay::RelationConnection' do
    expect(described_class.superclass).to eq GraphQL::Pagination::ActiveRecordRelationConnection
  end

  it_behaves_like 'a connection with collection methods' do
    let(:connection) { described_class.new(Project.all, context: context) }
  end

  it_behaves_like 'a redactable connection' do
    let_it_be(:users) { create_list(:user, 2) }

    let(:connection) { described_class.new(User.all, context: context, max_page_size: 10) }
    let(:unwanted) { users.second }
  end
end
