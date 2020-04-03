# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::JiraImport::IssueSerializer do
  describe '#execute' do
    let_it_be(:project) { create(:project) }

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
    let(:issue_type_field) { { 'name' => 'Task' } }
    let(:fix_versions_field) { [{ 'name' => '1.0' }, { 'name' => '1.1' }] }
    let(:priority_field) { { 'name' => 'Medium' } }
    let(:labels_field) { %w(bug backend) }
    let(:environment_field) { 'staging' }
    let(:duedate_field) { '2020-03-01' }

    let(:fields) do
      {
        'parent' => parent_field,
        'issuetype' => issue_type_field,
        'fixVersions' => fix_versions_field,
        'priority' => priority_field,
        'labels' => labels_field,
        'environment' => environment_field,
        'duedate' => duedate_field
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

        - Issue type: Task
        - Priority: Medium
        - Labels: bug, backend
        - Environment: staging
        - Due date: 2020-03-01
        - Parent issue: [FOO-2] parent issue FOO
        - Fix versions: 1.0, 1.1
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
          author_id: project.creator_id
        )
      end

      context 'when some metadata fields are missing' do
        let(:assignee) { nil }
        let(:parent_field) { nil }
        let(:fix_versions_field) { [] }
        let(:labels_field) { [] }
        let(:environment_field) { nil }
        let(:duedate_field) { '2020-03-01' }

        it 'skips the missing fields' do
          expected_description = <<~MD
            *Created by: Reporter*

            basic description

            ---

            **Issue metadata**

            - Issue type: Task
            - Priority: Medium
            - Due date: 2020-03-01
          MD

          expect(subject[:description]).to eq(expected_description.strip)
        end
      end

      context 'when all metadata fields are missing' do
        let(:assignee) { nil }
        let(:parent_field) { nil }
        let(:issue_type_field) { nil }
        let(:fix_versions_field) { [] }
        let(:priority_field) { nil }
        let(:labels_field) { [] }
        let(:environment_field) { nil }
        let(:duedate_field) { nil }

        it 'skips the whole metadata secction' do
          expected_description = <<~MD
            *Created by: Reporter*

            basic description
          MD

          expect(subject[:description]).to eq(expected_description.strip)
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
