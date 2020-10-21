# frozen_string_literal: true

RSpec.shared_examples 'search results sorted' do
  context 'sort: newest' do
    let(:sort) { 'newest' }

    it 'sorts results by created_at' do
      expect(results.objects(scope).map(&:id)).to eq([new_result.id, old_result.id, very_old_result.id])
    end
  end

  context 'sort: oldest' do
    let(:sort) { 'oldest' }

    it 'sorts results by created_at' do
      expect(results.objects(scope).map(&:id)).to eq([very_old_result.id, old_result.id, new_result.id])
    end
  end
end
