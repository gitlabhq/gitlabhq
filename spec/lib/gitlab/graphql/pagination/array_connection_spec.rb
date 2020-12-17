# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Graphql::Pagination::ArrayConnection do
  let(:nodes) { (1..10) }

  subject(:connection) { described_class.new(nodes, max_page_size: 100) }

  it_behaves_like 'a connection with collection methods'

  it_behaves_like 'a redactable connection' do
    let(:unwanted) { 5 }
  end
end
