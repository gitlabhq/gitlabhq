# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Graphql::Connections::FilterableArrayConnection do
  let(:callback) { proc { |nodes| nodes } }
  let(:all_nodes) { Gitlab::Graphql::FilterableArray.new(callback, 1, 2, 3, 4, 5) }
  let(:arguments) { {} }

  subject(:connection) do
    described_class.new(all_nodes, arguments, max_page_size: 3)
  end

  describe '#paged_nodes' do
    let(:paged_nodes) { subject.paged_nodes }

    it_behaves_like "connection with paged nodes"

    context 'when callback filters some nodes' do
      let(:callback) { proc { |nodes| nodes[1..-1] } }

      it 'does not return filtered elements' do
        expect(subject.paged_nodes).to contain_exactly(all_nodes[1], all_nodes[2])
      end
    end
  end
end
