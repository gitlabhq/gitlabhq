# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Graphql::Pagination::ArrayConnection do
  let(:context) { instance_double(GraphQL::Query::Context, schema: GitlabSchema) }
  let(:nodes) { (1..10) }

  subject(:connection) { described_class.new(nodes, context: context, max_page_size: 100) }

  it_behaves_like 'a connection with collection methods'

  it_behaves_like 'a redactable connection' do
    let(:unwanted) { 5 }
  end
end
