# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::NamespaceMirror do
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
    expect(group4.reload.ci_namespace_mirror).to have_attributes(traversal_ids: [group1.id, group2.id, group3.id, group4.id])
  end

  context 'scopes' do
    describe '.by_group_and_descendants' do
      let_it_be(:another_group) { create(:group) }

      subject(:result) { described_class.by_group_and_descendants(group2.id) }

      it 'returns groups having group2.id in traversal_ids' do
        expect(result.pluck(:namespace_id)).to contain_exactly(group2.id, group3.id, group4.id)
      end
    end

    describe '.contains_any_of_namespaces' do
      let!(:other_group1) { create(:group) }
      let!(:other_group2) { create(:group, parent: other_group1) }
      let!(:other_group3) { create(:group, parent: other_group2) }

      subject(:result) { described_class.contains_any_of_namespaces([group2.id, other_group2.id]) }

      it 'returns groups having group2.id in traversal_ids' do
        expect(result.pluck(:namespace_id)).to contain_exactly(
          group2.id, group3.id, group4.id, other_group2.id, other_group3.id
        )
      end
    end

    describe '.by_namespace_id' do
      subject(:result) { described_class.by_namespace_id(group2.id) }

      it 'returns namesapce mirrors of namespace id' do
        expect(result).to contain_exactly(group2.ci_namespace_mirror)
      end
    end
  end

  describe '.sync!' do
    subject(:sync) { described_class.sync!(Namespaces::SyncEvent.last) }

    context 'when namespace mirror does not exist in the first place' do
      let(:namespace) { group3 }

      before do
        namespace.ci_namespace_mirror.destroy!
        namespace.sync_events.create!
      end

      it 'creates the mirror' do
        expect { sync }.to change { described_class.count }.from(3).to(4)

        expect(namespace.reload.ci_namespace_mirror).to have_attributes(traversal_ids: [group1.id, group2.id, group3.id])
      end
    end

    context 'when namespace mirror does already exist' do
      let(:namespace) { group3 }

      before do
        namespace.sync_events.create!
      end

      it 'updates the mirror' do
        expect { sync }.not_to change { described_class.count }

        expect(namespace.reload.ci_namespace_mirror).to have_attributes(traversal_ids: [group1.id, group2.id, group3.id])
      end
    end

    shared_context 'changing the middle namespace' do
      let(:namespace) { group2 }

      before do
        group2.update!(parent: nil) # creates a sync event
      end

      it 'updates traversal_ids for the base and descendants' do
        expect { sync }.not_to change { described_class.count }

        expect(group1.reload.ci_namespace_mirror).to have_attributes(traversal_ids: [group1.id])
        expect(group2.reload.ci_namespace_mirror).to have_attributes(traversal_ids: [group2.id])
        expect(group3.reload.ci_namespace_mirror).to have_attributes(traversal_ids: [group2.id, group3.id])
        expect(group4.reload.ci_namespace_mirror).to have_attributes(traversal_ids: [group2.id, group3.id, group4.id])
      end
    end

    it_behaves_like 'changing the middle namespace'

    context 'when the FFs sync_traversal_ids, use_traversal_ids and use_traversal_ids_for_ancestors are disabled' do
      before do
        stub_feature_flags(sync_traversal_ids: false,
                           use_traversal_ids: false,
                           use_traversal_ids_for_ancestors: false)
      end

      it_behaves_like 'changing the middle namespace'
    end
  end
end
