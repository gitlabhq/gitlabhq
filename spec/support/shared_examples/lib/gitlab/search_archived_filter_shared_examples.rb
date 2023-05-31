# frozen_string_literal: true

RSpec.shared_examples 'search results filtered by archived' do
  context 'when filter not provided (all behavior)' do
    let(:filters) { {} }

    it 'returns unarchived results only', :aggregate_failures do
      expect(results.objects('projects')).to include unarchived_project
      expect(results.objects('projects')).not_to include archived_project
    end
  end

  context 'when include_archived is true' do
    let(:filters) { { include_archived: true } }

    it 'returns archived and unarchived results', :aggregate_failures do
      expect(results.objects('projects')).to include unarchived_project
      expect(results.objects('projects')).to include archived_project
    end
  end

  context 'when include_archived filter is false' do
    let(:filters) { { include_archived: false } }

    it 'returns unarchived results only', :aggregate_failures do
      expect(results.objects('projects')).to include unarchived_project
      expect(results.objects('projects')).not_to include archived_project
    end
  end
end
