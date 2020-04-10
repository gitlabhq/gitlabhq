# frozen_string_literal: true

RSpec.shared_examples 'a where_composite scope' do |scope_name|
  let(:result) { described_class.public_send(scope_name, ids) }

  context 'we pass an empty array' do
    let(:ids) { [] }

    it 'returns a null relation' do
      expect(result).to be_empty
    end
  end

  context 'we pass nil' do
    let(:ids) { nil }

    it 'returns a null relation' do
      expect(result).to be_empty
    end
  end

  context 'we pass a singleton composite id' do
    let(:ids) { composite_ids.first }

    it 'finds the first result' do
      expect(result).to contain_exactly(first_result)
    end
  end

  context 'we pass group of ids' do
    let(:ids) { composite_ids }

    it 'finds all the results' do
      expect(result).to contain_exactly(*all_results)
    end
  end

  describe 'performance' do
    it 'is not O(N)' do
      all_ids = composite_ids
      one_id = composite_ids.first

      expect { described_class.public_send(scope_name, all_ids) }
        .to issue_same_number_of_queries_as { described_class.public_send(scope_name, one_id) }
    end
  end
end
