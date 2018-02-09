require 'spec_helper'

describe Labels::PromoteService do
  describe '#execute' do
    let!(:user) { create(:user) }

    context 'project without group' do
      let!(:project_1)  { create(:project) }

      let!(:project_label_1_1)  { create(:label, project: project_1) }

      subject(:service) { described_class.new(project_1, user) }

      it 'fails on project without group' do
        expect(service.execute(project_label_1_1)).to be_falsey
      end
    end

    context 'project with group' do
      let!(:promoted_label_name)  { "Promoted Label" }
      let!(:untouched_label_name) { "Untouched Label" }
      let!(:promoted_description) { "Promoted Description" }
      let!(:promoted_color)       { "#0000FF" }
      let!(:label_2_1_priority)   { 1 }
      let!(:label_3_1_priority)   { 2 }

      let!(:group_1)  { create(:group) }
      let!(:group_2)  { create(:group) }

      let!(:project_1)  { create(:project, namespace: group_1) }
      let!(:project_2)  { create(:project, namespace: group_1) }
      let!(:project_3)  { create(:project, namespace: group_1) }
      let!(:project_4)  { create(:project, namespace: group_2) }

      # Labels/issues can't be lazily created so we might as well eager initialize
      # all other objects too since we use them inside
      let!(:project_label_1_1)  { create(:label, project: project_1, name: promoted_label_name, color: promoted_color, description: promoted_description) }
      let!(:project_label_1_2)  { create(:label, project: project_1, name: untouched_label_name) }
      let!(:project_label_2_1)  { create(:label, project: project_2, priority: label_2_1_priority, name: promoted_label_name, color: "#FF0000") }
      let!(:project_label_3_1)  { create(:label, project: project_3, priority: label_3_1_priority, name: promoted_label_name) }
      let!(:project_label_3_2)  { create(:label, project: project_3, priority: 1, name: untouched_label_name) }
      let!(:project_label_4_1)  { create(:label, project: project_4, name: promoted_label_name) }

      let!(:issue_1_1)  { create(:labeled_issue, project: project_1, labels: [project_label_1_1, project_label_1_2]) }
      let!(:issue_1_2)  { create(:labeled_issue, project: project_1, labels: [project_label_1_2]) }
      let!(:issue_2_1)  { create(:labeled_issue, project: project_2, labels: [project_label_2_1]) }
      let!(:issue_4_1)  { create(:labeled_issue, project: project_4, labels: [project_label_4_1]) }

      let!(:merge_3_1)  { create(:labeled_merge_request, source_project: project_3, target_project: project_3, labels: [project_label_3_1, project_label_3_2]) }

      let!(:issue_board_2_1)      { create(:board, project: project_2) }
      let!(:issue_board_list_2_1) { create(:list, board: issue_board_2_1, label: project_label_2_1) }

      let(:new_label) { group_1.labels.find_by(title: promoted_label_name) }

      subject(:service) { described_class.new(project_1, user) }

      it 'fails on group label' do
        group_label = create(:group_label, group: group_1)

        expect(service.execute(group_label)).to be_falsey
      end

      it 'is truthy on success' do
        expect(service.execute(project_label_1_1)).to be_truthy
      end

      it 'recreates the label as a group label' do
        expect { service.execute(project_label_1_1) }
          .to change(project_1.labels, :count).by(-1)
          .and change(group_1.labels, :count).by(1)
        expect(new_label).not_to be_nil
      end

      it 'copies title, description and color' do
        service.execute(project_label_1_1)

        expect(new_label.title).to eq(promoted_label_name)
        expect(new_label.description).to eq(promoted_description)
        expect(new_label.color).to eq(promoted_color)
      end

      it 'merges labels with the same name in group' do
        expect { service.execute(project_label_1_1) }.to change(project_2.labels, :count).by(-1).and \
          change(project_3.labels, :count).by(-1)
      end

      it 'keeps users\' subscriptions' do
        user2 = create(:user)
        project_label_1_1.subscriptions.create(user: user, subscribed: true)
        project_label_2_1.subscriptions.create(user: user, subscribed: true)
        project_label_3_2.subscriptions.create(user: user, subscribed: true)
        project_label_2_1.subscriptions.create(user: user2, subscribed: true)

        expect { service.execute(project_label_1_1) }.to change { Subscription.count }.from(4).to(3)

        expect(new_label.subscribed?(user)).to be_truthy
        expect(new_label.subscribed?(user2)).to be_truthy
      end

      it 'recreates priorities' do
        service.execute(project_label_1_1)

        expect(new_label.priority(project_1)).to be_nil
        expect(new_label.priority(project_2)).to eq(label_2_1_priority)
        expect(new_label.priority(project_3)).to eq(label_3_1_priority)
      end

      it 'does not touch project out of promoted group' do
        service.execute(project_label_1_1)
        project_4_new_label = project_4.labels.find_by(title: promoted_label_name)

        expect(project_4_new_label).not_to be_nil
        expect(project_4_new_label.id).to eq(project_label_4_1.id)
      end

      it 'does not touch out of group priority' do
        service.execute(project_label_1_1)

        expect(new_label.priority(project_4)).to be_nil
      end

      it 'relinks issue with the promoted label' do
        service.execute(project_label_1_1)
        issue_label = issue_1_1.labels.find_by(title: promoted_label_name)

        expect(issue_label).not_to be_nil
        expect(issue_label.id).to eq(new_label.id)
      end

      it 'does not remove untouched labels from issue' do
        expect { service.execute(project_label_1_1) }.not_to change(issue_1_1.labels, :count)
      end

      it 'does not relink untouched label in issue' do
        service.execute(project_label_1_1)
        issue_label = issue_1_2.labels.find_by(title: untouched_label_name)

        expect(issue_label).not_to be_nil
        expect(issue_label.id).to eq(project_label_1_2.id)
      end

      it 'relinks issues with merged labels' do
        service.execute(project_label_1_1)
        issue_label = issue_2_1.labels.find_by(title: promoted_label_name)

        expect(issue_label).not_to be_nil
        expect(issue_label.id).to eq(new_label.id)
      end

      it 'does not relink issues from other group' do
        service.execute(project_label_1_1)
        issue_label = issue_4_1.labels.find_by(title: promoted_label_name)

        expect(issue_label).not_to be_nil
        expect(issue_label.id).to eq(project_label_4_1.id)
      end

      it 'updates merge request' do
        service.execute(project_label_1_1)
        merge_label = merge_3_1.labels.find_by(title: promoted_label_name)

        expect(merge_label).not_to be_nil
        expect(merge_label.id).to eq(new_label.id)
      end

      it 'updates board lists' do
        service.execute(project_label_1_1)
        list = issue_board_2_1.lists.find_by(label: new_label)

        expect(list).not_to be_nil
      end

      # In case someone adds a new relation to Label.rb and forgets to relink it
      # and the database doesn't have foreign key constraints
      it 'relinks all relations' do
        service.execute(project_label_1_1)

        Label.reflect_on_all_associations.each do |association|
          expect(project_label_1_1.send(association.name).any?).to be_falsey
        end
      end

      context 'with invalid group label' do
        before do
          allow(service).to receive(:clone_label_to_group_label).and_wrap_original do |m, *args|
            label = m.call(*args)
            allow(label).to receive(:valid?).and_return(false)

            label
          end
        end

        it 'raises an exception' do
          expect { service.execute(project_label_1_1) }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end
  end
end
