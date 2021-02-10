# frozen_string_literal: true

RSpec.shared_examples 'search results sorted' do
  context 'sort: created_desc' do
    let(:sort) { 'created_desc' }

    it 'sorts results by created_at' do
      expect(results_created.objects(scope).map(&:id)).to eq([new_result.id, old_result.id, very_old_result.id])
    end
  end

  context 'sort: created_asc' do
    let(:sort) { 'created_asc' }

    it 'sorts results by created_at' do
      expect(results_created.objects(scope).map(&:id)).to eq([very_old_result.id, old_result.id, new_result.id])
    end
  end

  context 'sort: updated_desc' do
    let(:sort) { 'updated_desc' }

    it 'sorts results by updated_desc' do
      expect(results_updated.objects(scope).map(&:id)).to eq([new_updated.id, old_updated.id, very_old_updated.id])
    end
  end

  context 'sort: updated_asc' do
    let(:sort) { 'updated_asc' }

    it 'sorts results by updated_asc' do
      expect(results_updated.objects(scope).map(&:id)).to eq([very_old_updated.id, old_updated.id, new_updated.id])
    end
  end
end
