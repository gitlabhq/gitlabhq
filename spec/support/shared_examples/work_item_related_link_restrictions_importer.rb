# frozen_string_literal: true

RSpec.shared_examples 'work item related links restrictions importer' do
  shared_examples_for 'adds restrictions' do
    it "adds all restrictions if they don't exist" do
      expect { subject }.to change { WorkItems::RelatedLinkRestriction.count }.from(0).to(34)
    end
  end

  context 'when restrictions are missing' do
    before do
      WorkItems::RelatedLinkRestriction.delete_all
    end

    it_behaves_like 'adds restrictions'
  end

  context 'when base types are missing' do
    before do
      WorkItems::Type.delete_all
    end

    it_behaves_like 'adds restrictions'
  end

  context 'when some restrictions are missing' do
    before do
      Gitlab::DatabaseImporters::WorkItems::RelatedLinksRestrictionsImporter.upsert_restrictions
      WorkItems::RelatedLinkRestriction.limit(1).delete_all
    end

    it 'inserts missing restrictions and does nothing if some already existed' do
      expect { subject }.to make_queries_matching(/INSERT/, 1).and(
        change { WorkItems::RelatedLinkRestriction.count }.by(1)
      )
      expect(WorkItems::RelatedLinkRestriction.count).to eq(34)
    end
  end
end
