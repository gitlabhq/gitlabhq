# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::WorkItems::CreateWorkItemNoteTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:group) { create(:group) }
  let_it_be(:work_item) { create(:work_item, :issue, project: project, iid: 42) }
  let_it_be(:group_work_item) { create(:work_item, :epic, namespace: group, iid: 123) }
  let_it_be(:discussion) { create(:discussion_note_on_issue, project: project, noteable: work_item).discussion }

  let(:params) { { project_id: project.id.to_s, work_item_iid: work_item.iid, body: 'Test comment' } }
  let(:tool) { described_class.new(current_user: user, params: params) }

  before_all do
    project.add_developer(user)
    group.add_developer(user)
  end

  describe 'class methods' do
    describe '.build_mutation' do
      it 'returns the GraphQL mutation string' do
        mutation = described_class.build_mutation

        expect(mutation).to include('mutation CreateNote($input: CreateNoteInput!)')
        expect(mutation).to include('createNote(input: $input)')
        expect(mutation).to include('note {')
        expect(mutation).to include('id')
        expect(mutation).to include('body')
        expect(mutation).to include('internal')
        expect(mutation).to include('createdAt')
        expect(mutation).to include('updatedAt')
        expect(mutation).to include('author {')
        expect(mutation).to include('discussion {')
        expect(mutation).to include('errors')
      end

      it 'includes author fields' do
        mutation = described_class.build_mutation

        expect(mutation).to include('name')
        expect(mutation).to include('username')
        expect(mutation).to include('avatarUrl')
        expect(mutation).to include('webUrl')
      end
    end
  end

  describe 'versioning' do
    it 'registers version using VERSIONS constant' do
      expect(tool.version).to eq(Mcp::Tools::Concerns::Constants::VERSIONS[:v0_1_0])
    end

    it 'has correct operation name for version 0.1.0' do
      expect(tool.operation_name).to eq('createNote')
    end

    it 'has correct GraphQL operation for version 0.1.0' do
      operation = tool.graphql_operation

      expect(operation).to include('mutation CreateNote')
      expect(operation).to include('createNote(input: $input)')
    end
  end

  describe '#build_variables' do
    context 'with valid params' do
      it 'builds variables with work item ID and body' do
        variables = tool.build_variables

        expect(variables[:input]).to include(
          noteableId: work_item.to_global_id.to_s,
          body: 'Test comment'
        )
      end

      it 'includes internal flag when provided' do
        params[:internal] = true
        variables = tool.build_variables

        expect(variables[:input][:internal]).to be true
      end

      it 'includes discussion_id when provided' do
        params[:discussion_id] = discussion.to_global_id.to_s
        variables = tool.build_variables

        expect(variables[:input][:discussionId]).to eq(discussion.to_global_id.to_s)
      end

      it 'omits optional fields when not provided' do
        variables = tool.build_variables

        expect(variables[:input]).not_to have_key(:internal)
        expect(variables[:input]).not_to have_key(:discussionId)
      end
    end

    context 'with URL-based identification' do
      let(:params) do
        {
          url: "https://gitlab.com/#{project.full_path}/-/work_items/#{work_item.iid}",
          body: 'Test comment'
        }
      end

      it 'resolves work item from URL' do
        variables = tool.build_variables

        expect(variables[:input][:noteableId]).to eq(work_item.to_global_id.to_s)
      end
    end

    context 'with group work item' do
      let(:params) do
        {
          group_id: group.id.to_s,
          work_item_iid: group_work_item.iid,
          body: 'Test comment on epic'
        }
      end

      it 'resolves group work item' do
        stub_licensed_features(epics: true)

        variables = tool.build_variables

        expect(variables[:input][:noteableId]).to eq(group_work_item.to_global_id.to_s)
      end
    end

    context 'with quick actions validation' do
      where(:body_text, :should_raise) do
        [
          ['/close', true],
          ['/assign @user', true],
          ["This is a comment\n/assign @user\nMore text", true],
          ['  /approve', true],
          ['This is a comment with /slash in the middle', false]
        ]
      end

      with_them do
        let(:params) do
          {
            project_id: project.id.to_s,
            work_item_iid: work_item.iid,
            body: body_text
          }
        end

        it 'validates quick actions correctly' do
          if should_raise
            expect { tool.build_variables }
              .to raise_error(ArgumentError, 'Quick actions (commands starting with /) are not allowed in note body')
          else
            expect { tool.build_variables }.not_to raise_error
          end
        end
      end
    end

    context 'when work item does not exist' do
      let(:params) do
        {
          project_id: project.id.to_s,
          work_item_iid: 99999,
          body: 'Test comment'
        }
      end

      it 'raises ArgumentError' do
        expect { tool.build_variables }
          .to raise_error(ArgumentError, 'Work item #99999 not found')
      end
    end

    context 'when user lacks access to work item' do
      let_it_be(:private_project) { create(:project, :private) }
      let(:params) do
        {
          project_id: private_project.id.to_s,
          work_item_iid: 1,
          body: 'Test comment'
        }
      end

      it 'raises ArgumentError' do
        expect { tool.build_variables }
          .to raise_error(ArgumentError, /Access denied to project/)
      end
    end
  end

  describe 'edge cases' do
    context 'with very long body' do
      let(:params) do
        {
          project_id: project.id.to_s,
          work_item_iid: work_item.iid,
          body: 'a' * 1_048_576
        }
      end

      it 'accepts body up to max length' do
        expect { tool.build_variables }.not_to raise_error
      end
    end

    context 'with special characters in body' do
      let(:params) do
        {
          project_id: project.id.to_s,
          work_item_iid: work_item.iid,
          body: "Test with special chars: @user #123 `code` **bold**"
        }
      end

      it 'preserves special characters' do
        variables = tool.build_variables

        expect(variables[:input][:body]).to eq("Test with special chars: @user #123 `code` **bold**")
      end
    end

    context 'with empty body' do
      let(:params) do
        {
          project_id: project.id.to_s,
          work_item_iid: work_item.iid,
          body: ''
        }
      end

      it 'builds variables with empty body' do
        variables = tool.build_variables

        expect(variables[:input][:body]).to eq('')
      end
    end

    context 'with nil internal flag' do
      let(:params) do
        {
          project_id: project.id.to_s,
          work_item_iid: work_item.iid,
          body: 'Test',
          internal: nil
        }
      end

      it 'omits internal from input' do
        variables = tool.build_variables

        expect(variables[:input]).not_to have_key(:internal)
      end
    end
  end

  describe 'integration' do
    it 'executes mutation with correct variables' do
      allow(GitlabSchema).to receive(:execute).and_call_original

      tool.execute

      expect(GitlabSchema).to have_received(:execute).with(
        anything,
        variables: hash_including(
          input: hash_including(
            noteableId: work_item.to_global_id.to_s,
            body: 'Test comment'
          )
        ),
        context: hash_including(current_user: user)
      )
    end

    it 'returns note data' do
      result = tool.execute

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]['note']).to be_a(Hash)
      expect(result[:structuredContent]['note']['id']).to be_present
      expect(result[:structuredContent]['note']['body']).to eq('Test comment')
    end

    context 'with optional parameters' do
      let(:params) do
        {
          project_id: project.id.to_s,
          work_item_iid: work_item.iid,
          body: 'Internal comment',
          internal: true,
          discussion_id: discussion.to_global_id.to_s
        }
      end

      it 'includes optional parameters in variables' do
        allow(GitlabSchema).to receive(:execute).and_call_original

        tool.execute

        expect(GitlabSchema).to have_received(:execute).with(
          anything,
          variables: hash_including(
            input: hash_including(
              internal: true,
              discussionId: discussion.to_global_id.to_s
            )
          ),
          context: anything
        )
      end
    end

    context 'when work item does not exist' do
      let(:params) { { project_id: project.id.to_s, work_item_iid: 99999, body: 'Test' } }

      it 'raises error before executing GraphQL' do
        expect { tool.execute }.to raise_error(ArgumentError, 'Work item #99999 not found')
      end
    end

    context 'when user lacks permission' do
      let_it_be(:private_project) { create(:project, :private) }
      let_it_be(:private_work_item) { create(:work_item, :issue, project: private_project, iid: 1) }
      let(:params) { { project_id: private_project.id.to_s, work_item_iid: private_work_item.iid, body: 'Test' } }

      it 'raises error before executing GraphQL' do
        expect { tool.execute }.to raise_error(ArgumentError, /Access denied to project/)
      end
    end
  end
end
