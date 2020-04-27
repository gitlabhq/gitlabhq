# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::JiraImport::IssueSerializer do
  describe '#execute' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:project_label) { create(:label, project: project, title: 'bug') }
    let_it_be(:other_project_label) { create(:label, project: project, title: 'feature') }
    let_it_be(:group_label) { create(:group_label, group: group, title: 'dev') }

    let(:iid) { 5 }
    let(:key) { 'PROJECT-5' }
    let(:summary) { 'some title' }
    let(:description) { 'basic description' }
    let(:created_at) { '2020-01-01 20:00:00' }
    let(:updated_at) { '2020-01-10 20:00:00' }
    let(:assignee) { double(displayName: 'Solver') }
    let(:jira_status) { 'new' }

    let(:parent_field) do
      { 'key' => 'FOO-2', 'id' => '1050', 'fields' => { 'summary' => 'parent issue FOO' } }
    end
    let(:priority_field) { { 'name' => 'Medium' } }
    let(:labels_field) { %w(bug dev backend frontend) }

    let(:fields) do
      {
        'parent' => parent_field,
        'priority' => priority_field,
        'labels' => labels_field
      }
    end

    let(:jira_issue) do
      double(
        id: '1234',
        key: key,
        summary: summary,
        description: description,
        created: created_at,
        updated: updated_at,
        assignee: assignee,
        reporter: double(displayName: 'Reporter'),
        status: double(statusCategory: { 'key' => jira_status }),
        fields: fields
      )
    end

    let(:params) { { iid: iid } }

    subject { described_class.new(project, jira_issue, params).execute }

    let(:expected_description) do
      <<~MD
        *Created by: Reporter*

        *Assigned to: Solver*

        basic description

        ---

        **Issue metadata**

        - Priority: Medium
        - Parent issue: [FOO-2] parent issue FOO
      MD
    end

    context 'attributes setting' do
      it 'sets the basic attributes' do
        expect(subject).to eq(
          iid: iid,
          project_id: project.id,
          description: expected_description.strip,
          title: "[#{key}] #{summary}",
          state_id: 1,
          updated_at: updated_at,
          created_at: created_at,
          author_id: project.creator_id,
          label_ids: [project_label.id, group_label.id] + Label.reorder(id: :asc).last(2).pluck(:id)
        )
      end

      it 'creates a hash for valid issue' do
        expect(Issue.new(subject)).to be_valid
      end

      it 'creates all missing labels (on project level)' do
        expect { subject }.to change { Label.count }.from(3).to(5)

        expect(Label.find_by(title: 'frontend').project).to eq(project)
        expect(Label.find_by(title: 'backend').project).to eq(project)
      end

      context 'when there are no new labels' do
        let(:labels_field) { %w(bug dev) }

        it 'assigns the labels to the Issue hash' do
          expect(subject[:label_ids]).to match_array([project_label.id, group_label.id])
        end

        it 'does not create new labels' do
          expect { subject }.not_to change { Label.count }.from(3)
        end
      end
    end

    context 'with done status' do
      let(:jira_status) { 'done' }

      it 'maps the status to closed' do
        expect(subject[:state_id]).to eq(2)
      end
    end

    context 'without the iid' do
      let(:params) { {} }

      it 'does not set the iid' do
        expect(subject[:iid]).to be_nil
      end
    end
  end
end
