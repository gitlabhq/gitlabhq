# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::NamespaceMirror, feature_category: :organization do
  let_it_be(:parent_group) { create(:group) }
  let_it_be(:group) { create(:group, parent: parent_group) }

  describe 'associations' do
    it { is_expected.to belong_to(:namespace) }
  end

  describe '.sync!' do
    let!(:event) { group.sync_events.create! }

    subject(:sync) { described_class.sync!(event) }

    context 'when the namespace mirror does not exist yet' do
      it 'creates the mirror' do
        expect { sync }.to change { described_class.count }.from(0).to(1)

        expect(described_class.find_by(namespace_id: group.id)).to have_attributes(
          traversal_ids: [parent_group.id, group.id],
          organization_id: group.organization_id
        )
      end
    end

    context 'when the namespace mirror already exists' do
      before do
        described_class.create!(
          namespace_id: group.id, traversal_ids: [group.id], organization_id: group.organization_id
        )
      end

      it 'updates the mirror' do
        expect { sync }.not_to change { described_class.count }

        expect(described_class.find_by(namespace_id: group.id)).to have_attributes(
          traversal_ids: [parent_group.id, group.id],
          organization_id: group.organization_id
        )
      end
    end
  end
end
