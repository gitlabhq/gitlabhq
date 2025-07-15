# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Issuable::Clone::CopyResourceEventsService, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project1) { create(:project, :public, group: group) }
  let_it_be(:project2) { create(:project, :public, group: group) }
  let_it_be(:new_issue) { create(:issue, project: project2) }
  let_it_be_with_reload(:original_issue) { create(:issue, project: project1) }
  let(:used_new_issue) { new_issue }

  subject { described_class.new(user, original_issue, used_new_issue) }

  it 'copies the resource label events' do
    resource_label_events = create_list(:resource_label_event, 2, issue: original_issue)

    subject.execute

    expected = resource_label_events.map(&:label_id)

    expect(new_issue.resource_label_events.map(&:label_id)).to match_array(expected)
  end

  context 'with existing milestone events' do
    let!(:milestone1_project1) { create(:milestone, title: 'milestone1', project: project1) }
    let!(:milestone2_project1) { create(:milestone, title: 'milestone2', project: project1) }
    let!(:milestone3_project1) { create(:milestone, title: 'milestone3', project: project1) }

    let!(:milestone1_project2) { create(:milestone, title: 'milestone1', project: project2) }
    let!(:milestone2_project2) { create(:milestone, title: 'milestone2', project: project2) }

    before do
      original_issue.update!(milestone: milestone2_project1)

      create_event(milestone1_project1)
      create_event(milestone2_project1)
      create_event(nil, 'remove')
      create_event(milestone3_project1)
    end

    it 'copies existing resource milestone events', :aggregate_failures do
      subject.execute

      new_issue_milestone_events = new_issue.reload.resource_milestone_events
      expect(new_issue_milestone_events.count).to eq(4)

      expect_milestone_event(
        new_issue_milestone_events.first,
        milestone: milestone1_project1,
        action: 'add',
        state: 'opened',
        namespace_id: new_issue.namespace_id,
        imported_from: 'bitbucket'
      )
      expect_milestone_event(
        new_issue_milestone_events.second,
        milestone: milestone2_project1,
        action: 'add',
        state: 'opened',
        namespace_id: new_issue.namespace_id,
        imported_from: 'github'
      )
      expect_milestone_event(
        new_issue_milestone_events.third,
        milestone: nil,
        action: 'remove',
        state: 'opened',
        namespace_id: new_issue.namespace_id
      )
      expect_milestone_event(
        new_issue_milestone_events.fourth,
        milestone: milestone3_project1,
        action: 'add',
        state: 'opened',
        namespace_id: new_issue.namespace_id,
        imported_from: 'github'
      )
    end

    def create_event(milestone, action = 'add')
      create(:resource_milestone_event, issue: original_issue, milestone: milestone, action: action)
    end

    def expect_milestone_event(event, expected_attrs)
      expect(event.milestone_id).to eq(expected_attrs[:milestone]&.id)
      expect(event.action).to eq(expected_attrs[:action])
      expect(event.state).to eq(expected_attrs[:state])
      expect(event.namespace_id).to eq(expected_attrs[:namespace_id])
      expect(event.imported_from).to eq('none')
    end
  end

  context 'with existing state events' do
    let!(:event1) { create(:resource_state_event, issue: original_issue, state: 'opened') }
    let!(:event2) { create(:resource_state_event, issue: original_issue, state: 'closed') }
    let!(:event3) { create(:resource_state_event, issue: original_issue, state: 'reopened') }

    it 'copies existing state events as expected' do
      subject.execute

      state_events = new_issue.reload.resource_state_events
      expect(state_events.size).to eq(3)

      expect_state_event(state_events.first, issue: new_issue, state: 'opened', namespace_id: new_issue.namespace_id)
      expect_state_event(state_events.second, issue: new_issue, state: 'closed', namespace_id: new_issue.namespace_id)
      expect_state_event(state_events.third, issue: new_issue, state: 'reopened', namespace_id: new_issue.namespace_id)
    end

    context 'when new entity is a work item', :aggregate_failures do
      let(:used_new_issue) { new_issue.becomes(::WorkItem) } # rubocop:disable Cop/AvoidBecomes -- Less expensive than creating a new entity

      it 'copies existing state events as expected' do
        subject.execute

        state_events = used_new_issue.reload.resource_state_events
        expect(state_events.size).to eq(3)
        expect(state_events.pluck(:namespace_id)).to all(eq(project2.project_namespace_id))
      end

      context 'when it is a group level work item' do
        let(:used_new_issue) { create(:work_item, :group_level, namespace: group) }

        it 'copies existing state events as expected' do
          subject.execute

          state_events = used_new_issue.reload.resource_state_events
          expect(state_events.size).to eq(3)
          expect(state_events.pluck(:namespace_id)).to all(eq(group.id))
        end
      end
    end

    context 'when the new entity is not of a supported type' do
      let(:used_new_issue) { create(:merge_request, source_project: project2) }

      # No reason not to support merge requests other than it's not implemente yet. Should be fine to implement
      # if necessary, in the future
      it 'raises an unsupported type error' do
        expect do
          subject.execute
        end.to raise_error(StandardError, 'Copying resource events for MergeRequest is not supported yet')
      end
    end

    def expect_state_event(event, expected_attrs)
      expect(event.issue_id).to eq(expected_attrs[:issue]&.id)
      expect(event.state).to eq(expected_attrs[:state])
      expect(event.namespace_id).to eq(expected_attrs[:namespace_id])
    end
  end
end
