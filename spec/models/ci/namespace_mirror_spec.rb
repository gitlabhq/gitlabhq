# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::NamespaceMirror, feature_category: :continuous_integration do
  let!(:group1) { create(:group) }
  let!(:group2) { create(:group, parent: group1) }
  let!(:group3) { create(:group, parent: group2) }
  let!(:group4) { create(:group, parent: group3) }

  before do
    # refreshing ci mirrors according to the parent tree above
    Namespaces::SyncEvent.find_each { |event| Ci::NamespaceMirror.sync!(event) }

    # checking initial situation. we need to reload to reflect the changes of event sync
    expect(group1.reload.ci_namespace_mirror).to have_attributes(traversal_ids: [group1.id])
    expect(group2.reload.ci_namespace_mirror).to have_attributes(traversal_ids: [group1.id, group2.id])
    expect(group3.reload.ci_namespace_mirror).to have_attributes(traversal_ids: [group1.id, group2.id, group3.id])
    expect(group4.reload.ci_namespace_mirror).to have_attributes(
      traversal_ids: [group1.id, group2.id, group3.id, group4.id]
    )
  end

  describe 'associations' do
    it { is_expected.to belong_to(:namespace) }
    it { is_expected.to have_many(:project_mirrors) }

    it 'has a bidirectional relationship with project mirrors' do
      expect(described_class.reflect_on_association(:project_mirrors).has_inverse?).to eq(:namespace_mirror)
      expect(Ci::ProjectMirror.reflect_on_association(:namespace_mirror).has_inverse?).to eq(:project_mirrors)
    end
  end

  context 'scopes' do
    describe '.by_group_and_descendants' do
      let_it_be(:another_group) { create(:group) }

      subject(:result) { described_class.by_group_and_descendants(group2.id) }

      it 'returns groups having group2.id in traversal_ids' do
        expect(result.pluck(:namespace_id)).to contain_exactly(group2.id, group3.id, group4.id)
      end
    end

    describe '.contains_traversal_ids' do
      let!(:other_group1) { create(:group) }
      let!(:other_group2) { create(:group, parent: other_group1) }
      let!(:other_group3) { create(:group, parent: other_group2) }
      let!(:other_group4) { create(:group) }

      subject(:result) { described_class.contains_traversal_ids(all_traversal_ids) }

      context 'when passing a top-level group' do
        let(:all_traversal_ids) do
          [
            [other_group1.id]
          ]
        end

        it 'returns only itself and children of that group' do
          expect(result.map(&:namespace)).to contain_exactly(other_group1, other_group2, other_group3)
        end
      end

      context 'when passing many levels of groups' do
        let(:all_traversal_ids) do
          [
            [other_group2.parent_id, other_group2.id],
            [other_group3.parent_id, other_group3.id],
            [other_group4.id]
          ]
        end

        it 'returns only the asked group' do
          expect(result.map(&:namespace)).to contain_exactly(other_group2, other_group3, other_group4)
        end
      end

      context 'when passing invalid data ' do
        let(:all_traversal_ids) do
          [
            ["; UPDATE"]
          ]
        end

        it 'data is properly sanitised' do
          expect(result.to_sql).to include "((traversal_ids[1])) IN (('; UPDATE'))"
        end
      end
    end

    describe '.by_namespace_id' do
      subject(:result) { described_class.by_namespace_id(group2.id) }

      it 'returns namespace mirrors of namespace id' do
        expect(result).to contain_exactly(group2.ci_namespace_mirror)
      end
    end
  end

  describe '.sync!' do
    subject(:sync) { described_class.sync!(Namespaces::SyncEvent.last) }

    let(:expected_traversal_ids) { [group1.id, group2.id, group3.id] }

    context 'when namespace mirror does not exist in the first place' do
      let(:namespace) { group3 }

      before do
        namespace.ci_namespace_mirror.destroy!
        namespace.sync_events.create!
      end

      it 'creates the mirror' do
        expect { sync }.to change { described_class.count }.from(3).to(4)

        expect(namespace.reload.ci_namespace_mirror).to have_attributes(traversal_ids: expected_traversal_ids)
      end
    end

    context 'when namespace mirror does already exist' do
      let(:namespace) { group3 }

      before do
        namespace.sync_events.create!
      end

      it 'updates the mirror' do
        expect { sync }.not_to change { described_class.count }

        expect(namespace.reload.ci_namespace_mirror).to have_attributes(traversal_ids: expected_traversal_ids)
      end
    end
  end
end
