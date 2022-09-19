# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::JiraImport::MetadataCollector do
  describe '#execute' do
    let(:key) { 'PROJECT-5' }
    let(:summary) { 'some title' }
    let(:description) { 'basic description' }
    let(:created_at) { '2020-01-01 20:00:00' }
    let(:updated_at) { '2020-01-10 20:00:00' }
    let(:jira_status) { 'new' }

    let(:parent_field) do
      { 'key' => 'FOO-2', 'id' => '1050', 'fields' => { 'summary' => 'parent issue FOO' } }
    end

    let(:issue_type_field) { { 'name' => 'Task' } }
    let(:fix_versions_field) { [{ 'name' => '1.0' }, { 'name' => '1.1' }] }
    let(:priority_field) { { 'name' => 'Medium' } }
    let(:environment_field) { 'staging' }
    let(:duedate_field) { '2020-03-01' }

    let(:fields) do
      {
        'parent' => parent_field,
        'issuetype' => issue_type_field,
        'fixVersions' => fix_versions_field,
        'priority' => priority_field,
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
        status: double(statusCategory: { 'key' => jira_status }),
        fields: fields
      )
    end

    subject { described_class.new(jira_issue).execute }

    context 'when all metadata fields are present' do
      it 'writes all fields' do
        expected_result = <<~MD
          ---

          **Issue metadata**

          - Issue type: Task
          - Priority: Medium
          - Environment: staging
          - Due date: 2020-03-01
          - Parent issue: [FOO-2] parent issue FOO
          - Fix versions: 1.0, 1.1
        MD

        expect(subject.strip).to eq(expected_result.strip)
      end
    end

    context 'when some fields are in incorrect format' do
      let(:parent_field) { nil }
      let(:fix_versions_field) { [] }
      let(:priority_field) { nil }
      let(:environment_field) { nil }
      let(:duedate_field) { nil }

      context 'when fixVersions field is not an array' do
        let(:fix_versions_field) { { 'title' => '1.0', 'name' => '1.1' } }

        it 'skips these fields' do
          expected_result = <<~MD
            ---

            **Issue metadata**

            - Issue type: Task
          MD

          expect(subject.strip).to eq(expected_result.strip)
        end
      end

      context 'when a fixVersions element is in incorrect format' do
        let(:fix_versions_field) { [{ 'title' => '1.0' }, { 'name' => '1.1' }] }

        it 'skips the element' do
          expected_result = <<~MD
            ---

            **Issue metadata**

            - Issue type: Task
            - Fix versions: 1.1
          MD

          expect(subject.strip).to eq(expected_result.strip)
        end
      end

      context 'when a parent field has incorrectly formatted summary' do
        let(:parent_field) do
          { 'key' => 'FOO-2', 'id' => '1050', 'other_field' => { 'summary' => 'parent issue FOO' } }
        end

        it 'skips the summary' do
          expected_result = <<~MD
            ---

            **Issue metadata**

            - Issue type: Task
            - Parent issue: [FOO-2]
          MD

          expect(subject.strip).to eq(expected_result.strip)
        end
      end

      context 'when a parent field is missing the key' do
        let(:parent_field) do
          { 'not_key' => 'FOO-2', 'id' => '1050', 'other_field' => { 'summary' => 'parent issue FOO' } }
        end

        it 'skips the field' do
          expected_result = <<~MD
            ---

            **Issue metadata**

            - Issue type: Task
          MD

          expect(subject.strip).to eq(expected_result.strip)
        end
      end
    end

    context 'when some metadata fields are missing' do
      let(:parent_field) { nil }
      let(:fix_versions_field) { [] }
      let(:environment_field) { nil }

      it 'skips the missing fields' do
        expected_result = <<~MD
          ---

          **Issue metadata**

          - Issue type: Task
          - Priority: Medium
          - Due date: 2020-03-01
        MD

        expect(subject.strip).to eq(expected_result.strip)
      end
    end

    context 'when all metadata fields are missing' do
      let(:parent_field) { nil }
      let(:issue_type_field) { nil }
      let(:fix_versions_field) { [] }
      let(:priority_field) { nil }
      let(:environment_field) { nil }
      let(:duedate_field) { nil }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
