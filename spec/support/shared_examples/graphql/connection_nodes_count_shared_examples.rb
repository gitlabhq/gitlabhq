# frozen_string_literal: true

# requires:
#  - `connection` (non-empty, with a real `GraphQL::Query::Context` or a `namespace` stub that returns a Hash)
RSpec.shared_examples 'a connection that counts its nodes' do
  it 'adds the page size to the connection nodes count once' do
    3.times { connection.nodes }

    expect(connection.nodes).not_to be_empty
    expect(connection.context.namespace(:gl_logging)[:connection_nodes]).to eq(connection.nodes.size)
  end
end
