# frozen_string_literal: true

RSpec.shared_examples 'connection with paged nodes' do
  it 'returns the collection limited to max page size' do
    expect(paged_nodes.size).to eq(3)
  end

  it 'is a loaded memoized array' do
    expect(paged_nodes).to be_an(Array)
    expect(paged_nodes.object_id).to eq(paged_nodes.object_id)
  end

  context 'when `first` is passed' do
    let(:arguments) { { first: 2 } }

    it 'returns only the first elements' do
      expect(paged_nodes).to contain_exactly(all_nodes.first, all_nodes.second)
    end
  end

  context 'when `last` is passed' do
    let(:arguments) { { last: 2 } }

    it 'returns only the last elements' do
      expect(paged_nodes).to contain_exactly(all_nodes[3], all_nodes[4])
    end
  end
end
