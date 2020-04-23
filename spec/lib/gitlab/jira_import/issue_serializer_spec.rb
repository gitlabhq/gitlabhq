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
    let(:priority_field) { { 'name' => 'Medium' } }

    let(:fields) do
      {
        'parent' => parent_field,
        'priority' => priority_field
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
          author_id: project.creator_id
        )
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
