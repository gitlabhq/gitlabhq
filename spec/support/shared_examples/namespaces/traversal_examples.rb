# frozen_string_literal: true

RSpec.shared_examples 'namespace traversal' do
  shared_examples 'recursive version' do |method|
    let(:recursive_method) { "recursive_#{method}" }

    it "is equivalent to ##{method}" do
      groups.each do |group|
        expect(group.public_send(method)).to match_array group.public_send(recursive_method)
      end
    end

    it "makes a recursive query" do
      groups.each do |group|
        expect { group.public_send(recursive_method).load }.to make_queries_matching(/WITH RECURSIVE/)
      end
    end
  end

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

    describe '#recursive_self_and_hierarchy' do
      let(:groups) { [group, nested_group, very_deep_nested_group] }

      it_behaves_like 'recursive version', :self_and_hierarchy
    end
  end

  describe '#ancestors' do
    let_it_be(:group) { create(:group) }
    let_it_be(:nested_group) { create(:group, parent: group) }
    let_it_be(:deep_nested_group) { create(:group, parent: nested_group) }
    let_it_be(:very_deep_nested_group) { create(:group, parent: deep_nested_group) }

    it 'returns the correct ancestors' do
      # #reload is called to make sure traversal_ids are reloaded
      expect(very_deep_nested_group.reload.ancestors).to contain_exactly(group, nested_group, deep_nested_group)
      expect(deep_nested_group.reload.ancestors).to contain_exactly(group, nested_group)
      expect(nested_group.reload.ancestors).to contain_exactly(group)
      expect(group.reload.ancestors).to eq([])
    end

    describe '#recursive_ancestors' do
      let(:groups) { [nested_group, deep_nested_group, very_deep_nested_group] }

      it_behaves_like 'recursive version', :ancestors
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

    describe '#recursive_self_and_ancestors' do
      let(:groups) { [nested_group, deep_nested_group, very_deep_nested_group] }

      it_behaves_like 'recursive version', :self_and_ancestors
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

    describe '#recursive_descendants' do
      let(:groups) { [group, nested_group, deep_nested_group, very_deep_nested_group] }

      it_behaves_like 'recursive version', :descendants
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

    describe '#recursive_self_and_descendants' do
      let(:groups) { [group, nested_group, deep_nested_group, very_deep_nested_group] }

      it_behaves_like 'recursive version', :self_and_descendants
    end
  end
end
