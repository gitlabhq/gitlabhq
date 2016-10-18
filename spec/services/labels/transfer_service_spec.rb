require 'spec_helper'

describe Labels::TransferService, services: true do
  describe '#execute' do
    let(:user)    { create(:user) }
    let(:group_1) { create(:group) }
    let(:group_2) { create(:group) }
    let(:project) { create(:project, namespace: group_2) }

    let(:group_label_1) { create(:group_label, group: group_1, name: 'Group Label 1') }
    let(:group_label_2) { create(:group_label, group: group_1, name: 'Group Label 2') }
    let(:group_label_3) { create(:group_label, group: group_1, name: 'Group Label 3') }
    let(:group_label_4) { create(:group_label, group: group_2, name: 'Group Label 4') }
    let(:project_label_1) { create(:label, project: project, name: 'Project Label 1') }

    subject(:service) { described_class.new(user, group_1, project) }

    before do
      create(:labeled_issue, project: project, labels: [group_label_1])
      create(:labeled_issue, project: project, labels: [group_label_4])
      create(:labeled_issue, project: project, labels: [project_label_1])
      create(:labeled_merge_request, source_project: project, labels: [group_label_1, group_label_2])
    end

    it 'recreates the missing group labels at project level' do
      expect { service.execute }.to change(project.labels, :count).by(2)
    end

    it 'recreates label priorities related to the missing group labels' do
      create(:label_priority, project: project, label: group_label_1, priority: 1)

      service.execute

      new_project_label = project.labels.find_by(title: group_label_1.title)
      expect(new_project_label.id).not_to eq group_label_1.id
      expect(new_project_label.priorities).not_to be_empty
    end

    it 'does not recreate missing group labels that are not applied to issues or merge requests' do
      service.execute

      expect(project.labels.where(title: group_label_3.title)).to be_empty
    end

    it 'does not recreate missing group labels that already exist in the project group' do
      service.execute

      expect(project.labels.where(title: group_label_4.title)).to be_empty
    end
  end
end
