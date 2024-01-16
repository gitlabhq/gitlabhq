# frozen_string_literal: true

RSpec.shared_examples 'work item hierarchy restrictions importer' do
  shared_examples_for 'adds restrictions' do
    it "adds all restrictions if they don't exist" do
      expect { subject }.to change { WorkItems::HierarchyRestriction.count }.from(0).to(7)
    end
  end

  shared_examples 'clears type reactive cache' do
    specify do
      expect_next_found_instances_of(WorkItems::Type, 7) do |instance|
        expect(instance).to receive(:clear_reactive_cache!)
      end

      subject
    end
  end

  context 'when restrictions are missing' do
    before do
      WorkItems::HierarchyRestriction.delete_all
    end

    it_behaves_like 'adds restrictions'
    it_behaves_like 'clears type reactive cache'
  end

  context 'when base types are missing' do
    before do
      WorkItems::Type.delete_all
    end

    it_behaves_like 'adds restrictions'
  end

  context 'when restrictions already exist' do
    before do
      Gitlab::DatabaseImporters::WorkItems::HierarchyRestrictionsImporter.upsert_restrictions
    end

    it 'upserts restrictions' do
      restriction = WorkItems::HierarchyRestriction.first
      depth = restriction.maximum_depth

      restriction.update!(maximum_depth: depth + 1)

      expect do
        subject
        restriction.reload
      end.to not_change { WorkItems::HierarchyRestriction.count }.and(
        change { restriction.maximum_depth }.from(depth + 1).to(depth)
      )
    end

    it_behaves_like 'clears type reactive cache'
  end

  context 'when some restrictions are missing' do
    before do
      Gitlab::DatabaseImporters::WorkItems::HierarchyRestrictionsImporter.upsert_restrictions
      WorkItems::HierarchyRestriction.limit(1).delete_all
    end

    it 'inserts missing restrictions and does nothing if some already existed' do
      expect { subject }.to make_queries_matching(/INSERT/, 1).and(
        change { WorkItems::HierarchyRestriction.count }.by(1)
      )
      expect(WorkItems::HierarchyRestriction.count).to eq(7)
    end

    it_behaves_like 'clears type reactive cache'
  end

  context 'when restrictions contain attributes not present in the table' do
    before do
      allow(WorkItems::HierarchyRestriction)
        .to receive(:column_names).and_return(%w[parent_type_id child_type_id])
    end

    it 'filters out missing columns' do
      expect(WorkItems::HierarchyRestriction).to receive(:upsert_all) do |args|
        expect(args[0].keys).to eq(%i[parent_type_id child_type_id])
      end

      subject
    end

    it_behaves_like 'clears type reactive cache'
  end
end
