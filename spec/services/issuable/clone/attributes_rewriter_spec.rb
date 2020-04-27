# frozen_string_literal: true

require 'spec_helper'

describe Issuable::Clone::AttributesRewriter do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project1) { create(:project, :public, group: group) }
  let(:project2) { create(:project, :public, group: group) }
  let(:original_issue) { create(:issue, project: project1) }
  let(:new_issue) { create(:issue, project: project2) }

  subject { described_class.new(user, original_issue, new_issue) }

  context 'setting labels' do
    it 'sets labels present in the new project and group labels' do
      project1_label_1 = create(:label, title: 'label1', project: project1)
      project1_label_2 = create(:label, title: 'label2', project: project1)
      project2_label_1 = create(:label, title: 'label1', project: project2)
      group_label = create(:group_label, title: 'group_label', group: group)
      create(:label, title: 'label3', project: project2)

      original_issue.update(labels: [project1_label_1, project1_label_2, group_label])

      subject.execute

      expect(new_issue.reload.labels).to match_array([project2_label_1, group_label])
    end

    it 'does not set any labels when not used on the original issue' do
      subject.execute

      expect(new_issue.reload.labels).to be_empty
    end

    it 'copies the resource label events' do
      resource_label_events = create_list(:resource_label_event, 2, issue: original_issue)

      subject.execute

      expected = resource_label_events.map(&:label_id)

      expect(new_issue.resource_label_events.map(&:label_id)).to match_array(expected)
    end
  end

  context 'setting milestones' do
    it 'sets milestone to nil when old issue milestone is not in the new project' do
      milestone = create(:milestone, title: 'milestone', project: project1)

      original_issue.update(milestone: milestone)

      subject.execute

      expect(new_issue.reload.milestone).to be_nil
    end

    it 'copies the milestone when old issue milestone title is in the new project' do
      milestone_project1 = create(:milestone, title: 'milestone', project: project1)
      milestone_project2 = create(:milestone, title: 'milestone', project: project2)

      original_issue.update(milestone: milestone_project1)

      subject.execute

      expect(new_issue.reload.milestone).to eq(milestone_project2)
    end

    it 'copies the milestone when old issue milestone is a group milestone' do
      milestone = create(:milestone, title: 'milestone', group: group)

      original_issue.update(milestone: milestone)

      subject.execute

      expect(new_issue.reload.milestone).to eq(milestone)
    end

    context 'with existing milestone events' do
      let!(:milestone1_project1) { create(:milestone, title: 'milestone1', project: project1) }
      let!(:milestone2_project1) { create(:milestone, title: 'milestone2', project: project1) }
      let!(:milestone3_project1) { create(:milestone, title: 'milestone3', project: project1) }

      let!(:milestone1_project2) { create(:milestone, title: 'milestone1', project: project2) }
      let!(:milestone2_project2) { create(:milestone, title: 'milestone2', project: project2) }

      before do
        original_issue.update(milestone: milestone2_project1)

        create_event(milestone1_project1)
        create_event(milestone2_project1)
        create_event(nil, 'remove')
        create_event(milestone3_project1)
      end

      it 'copies existing resource milestone events' do
        subject.execute

        new_issue_milestone_events = new_issue.reload.resource_milestone_events
        expect(new_issue_milestone_events.count).to eq(3)

        expect_milestone_event(new_issue_milestone_events.first, milestone: milestone1_project2, action: 'add', state: 'opened')
        expect_milestone_event(new_issue_milestone_events.second, milestone: milestone2_project2, action: 'add', state: 'opened')
        expect_milestone_event(new_issue_milestone_events.third, milestone: nil, action: 'remove', state: 'opened')
      end

      def create_event(milestone, action = 'add')
        create(:resource_milestone_event, issue: original_issue, milestone: milestone, action: action)
      end

      def expect_milestone_event(event, expected_attrs)
        expect(event.milestone_id).to eq(expected_attrs[:milestone]&.id)
        expect(event.action).to eq(expected_attrs[:action])
        expect(event.state).to eq(expected_attrs[:state])
      end
    end
  end
end
