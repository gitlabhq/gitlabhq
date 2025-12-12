# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::JiraImport::IssueSerializer, feature_category: :team_planning do
  describe '#execute' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:project_label) { create(:label, project: project, title: 'bug') }
    let_it_be(:other_project_label) { create(:label, project: project, title: 'feature') }
    let_it_be(:group_label) { create(:group_label, group: group, title: 'dev') }
    let_it_be(:current_user) { create(:user) }
    let_it_be(:user) { create(:user) }
    let_it_be(:issue_type) { WorkItems::Type.default_issue_type }

    let(:iid) { 5 }
    let(:key) { 'PROJECT-5' }
    let(:summary) { 'some title' }
    let(:description) { 'basic description' }
    let(:description_field) { description }
    let(:created_at) { '2020-01-01 20:00:00' }
    let(:updated_at) { '2020-01-10 20:00:00' }
    let(:assignee) { nil }
    let(:reporter) { nil }
    let(:jira_status) { 'new' }

    let(:parent_field) do
      { 'key' => 'FOO-2', 'id' => '1050', 'fields' => { 'summary' => 'parent issue FOO' } }
    end

    let(:priority_field) { { 'name' => 'Medium' } }
    let(:labels_field) { %w[bug dev backend frontend] }

    let(:fields) do
      {
        'parent' => parent_field,
        'priority' => priority_field,
        'labels' => labels_field,
        'description' => description_field
      }
    end

    let(:jira_issue) do
      double(
        id: '1234',
        key: key,
        summary: summary,
        created: created_at,
        updated: updated_at,
        assignee: assignee,
        reporter: reporter,
        status: double(statusCategory: { 'key' => jira_status }),
        fields: fields
      )
    end

    let(:params) { { iid: iid } }

    let(:expected_description) do
      <<~MD
        basic description

        ---

        **Issue metadata**

        - Priority: Medium
        - Parent issue: [FOO-2] parent issue FOO
      MD
    end

    subject { described_class.new(project, jira_issue, current_user.id, issue_type, params).execute }

    context 'attributes setting' do
      it 'sets the basic attributes' do
        expect(subject).to eq(
          iid: iid,
          project_id: project.id,
          namespace_id: project.project_namespace_id,
          description: expected_description.strip,
          title: "[#{key}] #{summary}",
          state_id: 1,
          updated_at: updated_at,
          created_at: created_at,
          author_id: current_user.id,
          assignee_ids: nil,
          label_ids: [project_label.id, group_label.id] + Label.reorder(id: :asc).last(2).pluck(:id),
          work_item_type_id: issue_type.id,
          imported_from: Issue::IMPORT_SOURCES[:jira]
        )
      end

      it 'creates a hash for valid issue' do
        expect(Issue.new(subject)).to be_valid
      end

      context 'labels' do
        it 'creates all missing labels (on project level)' do
          expect { subject }.to change { Label.count }.from(3).to(5)

          expect(Label.find_by(title: 'frontend').project).to eq(project)
          expect(Label.find_by(title: 'backend').project).to eq(project)
        end

        context 'when there are no new labels' do
          let(:labels_field) { %w[bug dev] }

          it 'assigns the labels to the Issue hash' do
            expect(subject[:label_ids]).to match_array([project_label.id, group_label.id])
          end

          it 'does not create new labels' do
            expect { subject }.not_to change { Label.count }.from(3)
          end
        end
      end

      context 'author' do
        let(:reporter) { double(attrs: { 'displayName' => 'Solver', 'accountId' => 'abcd' }) }

        context 'when reporter maps to a valid GitLab user' do
          it 'sets the issue author to the mapped user' do
            expect(Gitlab::JiraImport).to receive(:get_user_mapping).with(project.id, 'abcd')
              .and_return(user.id)

            expect(subject[:author_id]).to eq(user.id)
          end
        end

        context 'when reporter does not map to a valid Gitlab user' do
          it 'defaults the issue author to project creator' do
            expect(Gitlab::JiraImport).to receive(:get_user_mapping).with(project.id, 'abcd')
              .and_return(nil)

            expect(subject[:author_id]).to eq(current_user.id)
          end
        end

        context 'when reporter field is empty' do
          let(:reporter) { nil }

          it 'defaults the issue author to project creator' do
            expect(Gitlab::JiraImport).not_to receive(:get_user_mapping)

            expect(subject[:author_id]).to eq(current_user.id)
          end
        end

        context 'when reporter field is missing accountId' do
          let(:reporter) { double(attrs: { 'displayName' => 'Reporter' }) }

          it 'defaults the issue author to project creator' do
            expect(Gitlab::JiraImport).not_to receive(:get_user_mapping)

            expect(subject[:author_id]).to eq(current_user.id)
          end
        end
      end

      context 'assignee' do
        let(:assignee) { double(attrs: { 'displayName' => 'Solver', 'accountId' => '1234' }) }

        context 'when assignee maps to a valid GitLab user' do
          it 'sets the issue assignees to the mapped user' do
            expect(Gitlab::JiraImport).to receive(:get_user_mapping).with(project.id, '1234')
              .and_return(user.id)

            expect(subject[:assignee_ids]).to eq([user.id])
          end
        end

        context 'when assignee does not map to a valid GitLab user' do
          it 'leaves the assignee empty' do
            expect(Gitlab::JiraImport).to receive(:get_user_mapping).with(project.id, '1234')
              .and_return(nil)

            expect(subject[:assignee_ids]).to be_nil
          end
        end

        context 'when assginee field is empty' do
          let(:assignee) { nil }

          it 'leaves the assignee empty' do
            expect(Gitlab::JiraImport).not_to receive(:get_user_mapping)

            expect(subject[:assignee_ids]).to be_nil
          end
        end

        context 'when assginee field is missing accountId' do
          let(:assignee) { double(attrs: { 'displayName' => 'Solver' }) }

          it 'leaves the assignee empty' do
            expect(Gitlab::JiraImport).not_to receive(:get_user_mapping)

            expect(subject[:assignee_ids]).to be_nil
          end
        end

        context 'with jira server response' do
          let(:assignee) { double(attrs: { 'displayName' => 'Solver', 'key' => '1234' }) }

          context 'when assignee maps to a valid GitLab user' do
            it 'sets the issue assignees to the mapped user' do
              expect(Gitlab::JiraImport).to receive(:get_user_mapping).with(project.id, '1234')
                                                                      .and_return(user.id)

              expect(subject[:assignee_ids]).to eq([user.id])
            end
          end
        end
      end
    end

    context 'description formatting' do
      context 'with plain text description' do
        let(:description_field) { 'plain text description' }

        it 'uses the plain text as-is' do
          expect(subject[:description]).to include('plain text description')
        end
      end

      context 'with ADF (Atlassian Document Format) description' do
        let(:description_field) do
          {
            'version' => 1,
            'type' => 'doc',
            'content' => [
              {
                'type' => 'paragraph',
                'content' => [
                  {
                    'type' => 'text',
                    'text' => 'This is ADF formatted text'
                  }
                ]
              }
            ]
          }
        end

        it 'converts ADF to markdown' do
          expect(subject[:description]).to include('This is ADF formatted text')
        end

        it 'includes metadata after converted content' do
          expect(subject[:description]).to include('**Issue metadata**')
        end
      end

      context 'with ADF missing content arrays' do
        let(:description_field) do
          {
            'version' => 1,
            'type' => 'doc'
          }
        end

        it 'sanitizes and converts ADF without errors' do
          expect { subject }.not_to raise_error
        end
      end

      context 'with invalid ADF that fails conversion' do
        let(:description_field) do
          {
            'type' => 'invalid',
            'malformed' => true
          }
        end

        before do
          allow_next_instance_of(Banzai::Filter::JiraImport::AdfToCommonmarkFilter) do |instance|
            allow(instance).to receive(:call).and_raise(StandardError.new('Conversion failed'))
          end
        end

        it 'falls back to text extraction' do
          expect { subject }.not_to raise_error
        end
      end

      context 'with empty ADF' do
        let(:description_field) { {} }

        it 'handles empty ADF gracefully' do
          expect(subject[:description]).to include('**Issue metadata**')
        end
      end

      context 'with nested ADF content' do
        let(:description_field) do
          {
            'type' => 'doc',
            'version' => 1,
            'content' => [
              {
                'type' => 'paragraph',
                'content' => [
                  { 'type' => 'text', 'text' => 'Line 1' },
                  { 'type' => 'text', 'text' => 'Line 2' }
                ]
              },
              {
                'type' => 'paragraph',
                'content' => [
                  { 'type' => 'text', 'text' => 'Line 3' }
                ]
              }
            ]
          }
        end

        it 'extracts text from nested ADF structures' do
          expect(subject[:description]).to include('Line 1')
          expect(subject[:description]).to include('Line 2')
          expect(subject[:description]).to include('Line 3')
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

  describe '#sanitize_adf' do
    let(:serializer) { described_class.new(project, jira_issue, current_user.id, issue_type) }
    let_it_be(:project) { create(:project) }
    let_it_be(:current_user) { create(:user) }
    let_it_be(:issue_type) { WorkItems::Type.default_issue_type }
    let(:jira_issue) { double(fields: {}) }

    context 'with non-Hash nodes' do
      it 'returns non-Hash nodes as-is' do
        expect(serializer.send(:sanitize_adf, 'string')).to eq('string')
        expect(serializer.send(:sanitize_adf, 123)).to eq(123)
        expect(serializer.send(:sanitize_adf, nil)).to be_nil
      end
    end

    context 'with Hash nodes' do
      it 'adds empty content array to nodes with type but no content' do
        node = { 'type' => 'paragraph' }
        result = serializer.send(:sanitize_adf, node)

        expect(result['content']).to eq([])
      end

      it 'preserves existing content and adds content to children' do
        node = { 'type' => 'paragraph', 'content' => [{ 'type' => 'text', 'text' => 'hello' }] }
        result = serializer.send(:sanitize_adf, node)

        # sanitize_adf recursively adds content to all typed children
        expect(result['content'][0]['type']).to eq('text')
        expect(result['content'][0]['text']).to eq('hello')
        expect(result['content'][0]['content']).to eq([])
      end

      it 'recursively sanitizes content array' do
        node = {
          'type' => 'doc',
          'content' => [
            { 'type' => 'paragraph' },
            { 'type' => 'paragraph', 'content' => [{ 'type' => 'text', 'text' => 'test' }] }
          ]
        }
        result = serializer.send(:sanitize_adf, node)

        expect(result['content'][0]['content']).to eq([])
        expect(result['content'][1]['content'][0]['type']).to eq('text')
        expect(result['content'][1]['content'][0]['text']).to eq('test')
      end

      it 'handles non-array content gracefully' do
        node = { 'type' => 'paragraph', 'content' => 'not an array' }
        result = serializer.send(:sanitize_adf, node)

        expect(result['content']).to eq('not an array')
      end

      it 'preserves nodes without type' do
        node = { 'content' => [{ 'type' => 'text', 'text' => 'hello' }] }
        result = serializer.send(:sanitize_adf, node)

        # Nodes without type don't get content added, but children are still sanitized
        expect(result['content'][0]['type']).to eq('text')
        expect(result['content'][0]['text']).to eq('hello')
        expect(result['content'][0]['content']).to eq([])
      end

      it 'handles deeply nested empty paragraphs' do
        node = {
          'type' => 'doc',
          'content' => [
            { 'type' => 'paragraph' },
            { 'type' => 'paragraph' },
            { 'type' => 'paragraph', 'content' => [{ 'type' => 'text', 'text' => 'Content' }] },
            { 'type' => 'paragraph' }
          ]
        }
        result = serializer.send(:sanitize_adf, node)

        expect(result['content'][0]['content']).to eq([])
        expect(result['content'][1]['content']).to eq([])
        expect(result['content'][2]['content'][0]['type']).to eq('text')
        expect(result['content'][2]['content'][0]['text']).to eq('Content')
        expect(result['content'][3]['content']).to eq([])
      end
    end
  end

  describe '#convert_adf_to_text' do
    let(:serializer) { described_class.new(project, jira_issue, current_user.id, issue_type) }
    let_it_be(:project) { create(:project) }
    let_it_be(:current_user) { create(:user) }
    let_it_be(:issue_type) { WorkItems::Type.default_issue_type }
    let(:jira_issue) { double(fields: {}) }

    context 'with blank ADF' do
      it 'returns empty string for nil' do
        expect(serializer.send(:convert_adf_to_text, nil)).to eq('')
      end

      it 'returns empty string for empty hash' do
        expect(serializer.send(:convert_adf_to_text, {})).to eq('')
      end
    end

    context 'with depth limit exceeded' do
      it 'returns empty string when depth exceeds MAX_ADF_DEPTH' do
        adf = { 'content' => [{ 'type' => 'text', 'text' => 'test' }] }
        result = serializer.send(:convert_adf_to_text, adf, described_class::MAX_ADF_DEPTH + 1)

        expect(result).to eq('')
      end
    end

    context 'with simple text content' do
      it 'extracts text from simple paragraph' do
        adf = {
          'type' => 'doc',
          'content' => [
            {
              'type' => 'paragraph',
              'content' => [
                { 'type' => 'text', 'text' => 'Hello world' }
              ]
            }
          ]
        }
        result = serializer.send(:convert_adf_to_text, adf)

        expect(result).to include('Hello world')
      end
    end

    context 'with multiple paragraphs' do
      it 'joins paragraphs with newlines' do
        adf = {
          'type' => 'doc',
          'content' => [
            {
              'type' => 'paragraph',
              'content' => [{ 'type' => 'text', 'text' => 'First paragraph' }]
            },
            {
              'type' => 'paragraph',
              'content' => [{ 'type' => 'text', 'text' => 'Second paragraph' }]
            }
          ]
        }
        result = serializer.send(:convert_adf_to_text, adf)

        expect(result).to include('First paragraph')
        expect(result).to include('Second paragraph')
      end
    end

    context 'with empty paragraphs' do
      it 'handles paragraphs without content' do
        adf = {
          'type' => 'doc',
          'content' => [
            { 'type' => 'paragraph' },
            { 'type' => 'paragraph', 'content' => [{ 'type' => 'text', 'text' => 'Text' }] },
            { 'type' => 'paragraph' }
          ]
        }
        result = serializer.send(:convert_adf_to_text, adf)

        expect(result).to include('Text')
      end
    end

    context 'with nested content' do
      it 'extracts text from nested structures' do
        adf = {
          'type' => 'doc',
          'content' => [
            {
              'type' => 'paragraph',
              'content' => [
                { 'type' => 'text', 'text' => 'Start ' },
                {
                  'type' => 'emphasis',
                  'content' => [{ 'type' => 'text', 'text' => 'emphasized' }]
                },
                { 'type' => 'text', 'text' => ' end' }
              ]
            }
          ]
        }
        result = serializer.send(:convert_adf_to_text, adf)

        expect(result).to include('Start')
        expect(result).to include('emphasized')
        expect(result).to include('end')
      end
    end
  end

  describe '#extract_text' do
    let(:serializer) { described_class.new(project, jira_issue, current_user.id, issue_type) }
    let_it_be(:project) { create(:project) }
    let_it_be(:current_user) { create(:user) }
    let_it_be(:issue_type) { WorkItems::Type.default_issue_type }
    let(:jira_issue) { double(fields: {}) }

    context 'with non-Hash nodes' do
      it 'returns empty string for non-Hash nodes' do
        expect(serializer.send(:extract_text, 'string')).to eq('')
        expect(serializer.send(:extract_text, 123)).to eq('')
        expect(serializer.send(:extract_text, nil)).to eq('')
      end
    end

    context 'with depth limit exceeded' do
      it 'returns empty string when depth exceeds MAX_ADF_DEPTH' do
        node = { 'type' => 'text', 'text' => 'test' }
        result = serializer.send(:extract_text, node, described_class::MAX_ADF_DEPTH + 1)

        expect(result).to eq('')
      end
    end

    context 'with text nodes' do
      it 'returns empty string for text node without content array' do
        node = { 'type' => 'text', 'text' => 'Hello' }
        result = serializer.send(:extract_text, node)

        expect(result).to eq('')
      end

      it 'returns empty string for text node without text field' do
        node = { 'type' => 'text' }
        result = serializer.send(:extract_text, node)

        expect(result).to eq('')
      end
    end

    context 'with container nodes' do
      it 'extracts text from container with multiple text nodes' do
        node = {
          'type' => 'paragraph',
          'content' => [
            { 'type' => 'text', 'text' => 'Hello' },
            { 'type' => 'text', 'text' => ' ' },
            { 'type' => 'text', 'text' => 'world' }
          ]
        }
        result = serializer.send(:extract_text, node)

        expect(result).to eq('Hello world')
      end

      it 'handles containers without content' do
        node = { 'type' => 'paragraph' }
        result = serializer.send(:extract_text, node)

        expect(result).to eq('')
      end
    end

    context 'with nested containers' do
      it 'recursively extracts text from nested structures' do
        node = {
          'type' => 'paragraph',
          'content' => [
            { 'type' => 'text', 'text' => 'Start ' },
            {
              'type' => 'emphasis',
              'content' => [
                { 'type' => 'text', 'text' => 'emphasized' }
              ]
            },
            { 'type' => 'text', 'text' => ' end' }
          ]
        }
        result = serializer.send(:extract_text, node)

        expect(result).to eq('Start emphasized end')
      end
    end

    context 'with mixed content' do
      it 'handles nodes with both text and content' do
        node = {
          'type' => 'paragraph',
          'content' => [
            { 'type' => 'text', 'text' => 'Direct text' },
            {
              'type' => 'strong',
              'content' => [{ 'type' => 'text', 'text' => 'bold' }]
            }
          ]
        }
        result = serializer.send(:extract_text, node)

        expect(result).to eq('Direct textbold')
      end
    end
  end
end
