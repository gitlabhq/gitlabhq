# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ProjectMirror, feature_category: :organization do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe '.sync!' do
    let!(:event) { Projects::SyncEvent.create!(project: project) }

    subject(:sync) { described_class.sync!(event) }

    context 'when the project mirror does not exist yet' do
      it 'creates the mirror' do
        expect { sync }.to change { described_class.count }.from(0).to(1)

        expect(described_class.find_by(project_id: project.id)).to have_attributes(
          namespace_id: group.id,
          organization_id: project.organization_id
        )
      end
    end

    context 'when the project mirror already exists' do
      let_it_be(:other_group) { create(:group) }

      before do
        described_class.create!(
          project_id: project.id, namespace_id: other_group.id, organization_id: other_group.organization_id
        )
      end

      it 'updates the mirror' do
        expect { sync }.not_to change { described_class.count }

        expect(described_class.find_by(project_id: project.id)).to have_attributes(
          namespace_id: group.id,
          organization_id: project.organization_id
        )
      end
    end
  end
end
