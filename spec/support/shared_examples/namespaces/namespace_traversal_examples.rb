# frozen_string_literal: true

RSpec.shared_examples 'namespace traversal' do
  describe '#self_and_hierarchy' do
    let!(:group) { create(:group, path: 'git_lab') }
    let!(:nested_group) { create(:group, parent: group) }
    let!(:deep_nested_group) { create(:group, parent: nested_group) }
    let!(:very_deep_nested_group) { create(:group, parent: deep_nested_group) }
    let!(:another_group) { create(:group, path: 'gitllab') }
    let!(:another_group_nested) { create(:group, path: 'foo', parent: another_group) }

    it 'returns the correct tree' do
      expect(group.self_and_hierarchy).to contain_exactly(group, nested_group, deep_nested_group, very_deep_nested_group)
      expect(nested_group.self_and_hierarchy).to contain_exactly(group, nested_group, deep_nested_group, very_deep_nested_group)
      expect(very_deep_nested_group.self_and_hierarchy).to contain_exactly(group, nested_group, deep_nested_group, very_deep_nested_group)
    end
  end

  describe '#ancestors' do
    let(:group) { create(:group) }
    let(:nested_group) { create(:group, parent: group) }
    let(:deep_nested_group) { create(:group, parent: nested_group) }
    let(:very_deep_nested_group) { create(:group, parent: deep_nested_group) }

    it 'returns the correct ancestors' do
      expect(very_deep_nested_group.ancestors).to include(group, nested_group, deep_nested_group)
      expect(deep_nested_group.ancestors).to include(group, nested_group)
      expect(nested_group.ancestors).to include(group)
      expect(group.ancestors).to eq([])
    end
  end

  describe '#self_and_ancestors' do
    let(:group) { create(:group) }
    let(:nested_group) { create(:group, parent: group) }
    let(:deep_nested_group) { create(:group, parent: nested_group) }
    let(:very_deep_nested_group) { create(:group, parent: deep_nested_group) }

    it 'returns the correct ancestors' do
      expect(very_deep_nested_group.self_and_ancestors).to contain_exactly(group, nested_group, deep_nested_group, very_deep_nested_group)
      expect(deep_nested_group.self_and_ancestors).to contain_exactly(group, nested_group, deep_nested_group)
      expect(nested_group.self_and_ancestors).to contain_exactly(group, nested_group)
      expect(group.self_and_ancestors).to contain_exactly(group)
    end
  end

  describe '#descendants' do
    let!(:group) { create(:group, path: 'git_lab') }
    let!(:nested_group) { create(:group, parent: group) }
    let!(:deep_nested_group) { create(:group, parent: nested_group) }
    let!(:very_deep_nested_group) { create(:group, parent: deep_nested_group) }
    let!(:another_group) { create(:group, path: 'gitllab') }
    let!(:another_group_nested) { create(:group, path: 'foo', parent: another_group) }

    it 'returns the correct descendants' do
      expect(very_deep_nested_group.descendants.to_a).to eq([])
      expect(deep_nested_group.descendants.to_a).to include(very_deep_nested_group)
      expect(nested_group.descendants.to_a).to include(deep_nested_group, very_deep_nested_group)
      expect(group.descendants.to_a).to include(nested_group, deep_nested_group, very_deep_nested_group)
    end
  end

  describe '#self_and_descendants' do
    let!(:group) { create(:group, path: 'git_lab') }
    let!(:nested_group) { create(:group, parent: group) }
    let!(:deep_nested_group) { create(:group, parent: nested_group) }
    let!(:very_deep_nested_group) { create(:group, parent: deep_nested_group) }
    let!(:another_group) { create(:group, path: 'gitllab') }
    let!(:another_group_nested) { create(:group, path: 'foo', parent: another_group) }

    it 'returns the correct descendants' do
      expect(very_deep_nested_group.self_and_descendants).to contain_exactly(very_deep_nested_group)
      expect(deep_nested_group.self_and_descendants).to contain_exactly(deep_nested_group, very_deep_nested_group)
      expect(nested_group.self_and_descendants).to contain_exactly(nested_group, deep_nested_group, very_deep_nested_group)
      expect(group.self_and_descendants).to contain_exactly(group, nested_group, deep_nested_group, very_deep_nested_group)
    end
  end
end
