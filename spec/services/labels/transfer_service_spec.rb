# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Labels::TransferService, feature_category: :team_planning do
  describe '#execute' do
    let_it_be(:user) { create(:user) }

    let_it_be(:old_group_ancestor) { create(:group) }
    let_it_be(:old_group) { create(:group, parent: old_group_ancestor) }

    let_it_be(:new_group) { create(:group) }

    let_it_be(:project) { create(:project, :repository, group: new_group) }

    subject(:service) { described_class.new(user, old_group, project) }

    before do
      old_group_ancestor.add_developer(user)
      new_group.add_developer(user)
    end

    shared_examples 'recreates missing labels at project level and assigns them to issuables' do |label_group_method|
      it "recreates missing #{label_group_method.to_s.tr('_', ' ')} labels at project level and assigns them to the issuables" do
        label_group = send(label_group_method)

        label_1 = create(:group_label, group: label_group)
        label_2 = create(:group_label, group: label_group)

        labeled_issue = create(:labeled_issue, project: project, labels: [label_1])
        labeled_merge_request = create(:labeled_merge_request, source_project: project, labels: [label_2])

        expect { service.execute }.to change(project.labels, :count).by(2)
        expect(labeled_issue.reload.labels).to contain_exactly(project.labels.find_by_title(label_1.title))
        expect(labeled_merge_request.reload.labels).to contain_exactly(project.labels.find_by_title(label_2.title))
      end

      it "recreates #{label_group_method.to_s.tr('_', ' ')} label priorities related to the missing group labels" do
        label_group = send(label_group_method)

        old_group_label = create(:group_label, group: label_group)
        create(:labeled_issue, project: project, labels: [old_group_label])
        create(:label_priority, project: project, label: old_group_label, priority: 1)

        service.execute

        new_project_label = project.labels.find_by(title: old_group_label.title)
        expect(new_project_label.id).not_to eq old_group_label.id
        expect(new_project_label.priorities).not_to be_empty
      end

      it "does not recreate missing #{label_group_method.to_s.tr('_', ' ')} labels that are not applied to issues or merge requests" do
        label_group = send(label_group_method)
        old_group_label = create(:group_label, group: label_group)

        service.execute

        expect(project.labels.where(title: old_group_label.title)).to be_empty
      end

      it "does not recreate missing #{label_group_method.to_s.tr('_', ' ')} labels that already exist in the project group" do
        label_group = send(label_group_method)
        old_group_label = create(:group_label, group: label_group)
        labeled_issue = create(:labeled_issue, project: project, labels: [old_group_label])

        new_group_label = create(:group_label, group: new_group, title: old_group_label.title)

        service.execute

        expect(project.labels.where(title: old_group_label.title)).to be_empty
        expect(labeled_issue.reload.labels).to contain_exactly(new_group_label)
      end

      it "updates only #{label_group_method.to_s.tr('_', ' ')} label links in the given project" do
        label_group = send(label_group_method)
        old_group_label = create(:group_label, group: label_group)
        other_project = create(:project, group: label_group)

        labeled_issue = create(:labeled_issue, project: project, labels: [old_group_label])
        other_project_labeled_issue = create(:labeled_issue, project: other_project, labels: [old_group_label])

        service.execute

        expect(labeled_issue.reload.labels).not_to include(old_group_label)
        expect(other_project_labeled_issue.reload.labels).to contain_exactly(old_group_label)
      end
    end

    it_behaves_like 'recreates missing labels at project level and assigns them to issuables', :old_group
    it_behaves_like 'recreates missing labels at project level and assigns them to issuables', :old_group_ancestor

    context 'when project is archived' do
      let_it_be(:project) { create(:project, :repository, :archived, group: new_group) }

      it_behaves_like 'recreates missing labels at project level and assigns them to issuables', :old_group
      it_behaves_like 'recreates missing labels at project level and assigns them to issuables', :old_group_ancestor
    end

    context 'when moving within the same ancestor group' do
      let_it_be(:other_subgroup) { create(:group, parent: old_group_ancestor) }
      let_it_be(:project) { create(:project, :repository, group: other_subgroup) }

      it 'does not recreate ancestor group labels' do
        old_group_ancestor_label_1 = create(:group_label, group: old_group_ancestor)
        old_group_ancestor_label_2 = create(:group_label, group: old_group_ancestor)

        labeled_issue = create(:labeled_issue, project: project, labels: [old_group_ancestor_label_1])
        labeled_merge_request = create(:labeled_merge_request, source_project: project, labels: [old_group_ancestor_label_2])

        expect { service.execute }.not_to change(project.labels, :count)
        expect(labeled_issue.reload.labels).to contain_exactly(old_group_ancestor_label_1)
        expect(labeled_merge_request.reload.labels).to contain_exactly(old_group_ancestor_label_2)
      end
    end
  end
end
