# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::NamespaceMirror do
  let!(:group1) { create(:group) }
  let!(:group2) { create(:group, parent: group1) }
  let!(:group3) { create(:group, parent: group2) }
  let!(:group4) { create(:group, parent: group3) }

  describe '.sync!' do
    let!(:event) { namespace.sync_events.create! }

    subject(:sync) { described_class.sync!(event.reload) }

    context 'when namespace hierarchy does not exist in the first place' do
      let(:namespace) { group3 }

      it 'creates the hierarchy' do
        expect { sync }.to change { described_class.count }.from(0).to(1)

        expect(namespace.ci_namespace_mirror).to have_attributes(traversal_ids: [group1.id, group2.id, group3.id])
      end
    end

    context 'when namespace hierarchy does already exist' do
      let(:namespace) { group3 }

      before do
        described_class.create!(namespace: namespace, traversal_ids: [namespace.id])
      end

      it 'updates the hierarchy' do
        expect { sync }.not_to change { described_class.count }

        expect(namespace.ci_namespace_mirror).to have_attributes(traversal_ids: [group1.id, group2.id, group3.id])
      end
    end

    # I did not extract this context to a `shared_context` because the behavior will change
    # after implementing the TODO in `Ci::NamespaceMirror.sync!`
    context 'changing the middle namespace' do
      let(:namespace) { group2 }

      before do
        described_class.create!(namespace_id: group1.id, traversal_ids: [group1.id])
        described_class.create!(namespace_id: group2.id, traversal_ids: [group1.id, group2.id])
        described_class.create!(namespace_id: group3.id, traversal_ids: [group1.id, group2.id, group3.id])
        described_class.create!(namespace_id: group4.id, traversal_ids: [group1.id, group2.id, group3.id, group4.id])

        group2.update!(parent: nil)
      end

      it 'updates hierarchies for the base but wait for events for the children' do
        expect { sync }.not_to change { described_class.count }

        expect(group1.reload.ci_namespace_mirror).to have_attributes(traversal_ids: [group1.id])
        expect(group2.reload.ci_namespace_mirror).to have_attributes(traversal_ids: [group2.id])
        expect(group3.reload.ci_namespace_mirror).to have_attributes(traversal_ids: [group2.id, group3.id])
        expect(group4.reload.ci_namespace_mirror).to have_attributes(traversal_ids: [group2.id, group3.id, group4.id])
      end
    end

    context 'when the FFs sync_traversal_ids, use_traversal_ids and use_traversal_ids_for_ancestors are disabled' do
      before do
        stub_feature_flags(sync_traversal_ids: false,
                           use_traversal_ids: false,
                           use_traversal_ids_for_ancestors: false)
      end

      context 'changing the middle namespace' do
        let(:namespace) { group2 }

        before do
          described_class.create!(namespace_id: group1.id, traversal_ids: [group1.id])
          described_class.create!(namespace_id: group2.id, traversal_ids: [group1.id, group2.id])
          described_class.create!(namespace_id: group3.id, traversal_ids: [group1.id, group2.id, group3.id])
          described_class.create!(namespace_id: group4.id, traversal_ids: [group1.id, group2.id, group3.id, group4.id])

          group2.update!(parent: nil)
        end

        it 'updates hierarchies for the base and descendants' do
          expect { sync }.not_to change { described_class.count }

          expect(group1.reload.ci_namespace_mirror).to have_attributes(traversal_ids: [group1.id])
          expect(group2.reload.ci_namespace_mirror).to have_attributes(traversal_ids: [group2.id])
          expect(group3.reload.ci_namespace_mirror).to have_attributes(traversal_ids: [group2.id, group3.id])
          expect(group4.reload.ci_namespace_mirror).to have_attributes(traversal_ids: [group2.id, group3.id, group4.id])
        end
      end
    end
  end
end
