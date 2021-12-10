# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ProjectMirror do
  let_it_be(:group1) { create(:group) }
  let_it_be(:group2) { create(:group) }

  let!(:project) { create(:project, namespace: group2) }

  describe '.sync!' do
    let!(:event) { Projects::SyncEvent.create!(project: project) }

    subject(:sync) { described_class.sync!(event.reload) }

    context 'when project hierarchy does not exist in the first place' do
      it 'creates a ci_projects record' do
        expect { sync }.to change { described_class.count }.from(0).to(1)

        expect(project.ci_project_mirror).to have_attributes(namespace_id: group2.id)
      end
    end

    context 'when project hierarchy does already exist' do
      before do
        described_class.create!(project_id: project.id, namespace_id: group1.id)
      end

      it 'updates the related ci_projects record' do
        expect { sync }.not_to change { described_class.count }

        expect(project.ci_project_mirror).to have_attributes(namespace_id: group2.id)
      end
    end
  end
end
