# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::MergeRequests::CreateMergeRequestNoteTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:discussion, freeze: false) do
    create(:discussion_note_on_merge_request, project: project, noteable: merge_request).discussion
  end

  let(:params) do
    { project_id: project.id.to_s, merge_request_iid: merge_request.iid, body: 'Test comment' }
  end

  let(:tool) { described_class.new(current_user: user, params: params) }

  before_all do
    project.add_developer(user)
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

      expect(operation).to include('mutation createMergeRequestNote')
      expect(operation).to include('createNote(input: $input)')
    end
  end

  describe '#build_variables' do
    context 'with valid params' do
      it 'builds variables with merge request global ID and body' do
        variables = tool.build_variables

        expect(variables[:input]).to include(
          noteableId: merge_request.to_global_id.to_s,
          body: 'Test comment'
        )
      end

      it 'includes discussion_id when provided' do
        params[:discussion_id] = discussion.to_global_id.to_s
        variables = tool.build_variables

        expect(variables[:input][:discussionId]).to eq(discussion.to_global_id.to_s)
      end

      it 'omits optional fields when not provided' do
        variables = tool.build_variables

        expect(variables[:input]).not_to have_key(:discussionId)
      end
    end

    context 'with quick actions validation' do
      using RSpec::Parameterized::TableSyntax

      where(:body_text, :should_raise) do
        [
          ['/merge', true],
          ['/close', true],
          ["This is a comment\n/assign @user\nMore text", true],
          ['  /approve', true],
          ['This is a comment with /slash in the middle', false]
        ]
      end

      with_them do
        let(:params) do
          { project_id: project.id.to_s, merge_request_iid: merge_request.iid, body: body_text }
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

    context 'with a merge request URL' do
      let(:params) { { url: Gitlab::UrlBuilder.build(merge_request), body: 'Test comment' } }

      it 'resolves the merge request from the URL' do
        variables = tool.build_variables

        expect(variables[:input][:noteableId]).to eq(merge_request.to_global_id.to_s)
      end
    end

    context 'with a merge request URL in a nested subgroup' do
      let_it_be(:subgroup) { create(:group, :nested) }
      let_it_be(:nested_project) { create(:project, :public, group: subgroup) }
      let_it_be(:nested_merge_request) { create(:merge_request, source_project: nested_project) }

      let(:params) { { url: Gitlab::UrlBuilder.build(nested_merge_request), body: 'Test comment' } }

      before_all do
        nested_project.add_developer(user)
      end

      it 'reconstructs the full namespace path and resolves the merge request' do
        expect(nested_project.full_path.count('/')).to be >= 2 # group/subgroup/project

        variables = tool.build_variables

        expect(variables[:input][:noteableId]).to eq(nested_merge_request.to_global_id.to_s)
      end
    end

    context 'when the URL is not a valid merge request URL' do
      let(:params) { { url: 'https://gitlab.com/not/a/merge/request', body: 'Test comment' } }

      it 'raises ArgumentError' do
        expect { tool.build_variables }
          .to raise_error(ArgumentError, /Invalid merge request URL/)
      end
    end

    context 'when neither url nor merge_request_iid is provided' do
      let(:params) { { project_id: project.id.to_s, body: 'Test comment' } }

      it 'raises ArgumentError' do
        expect { tool.build_variables }
          .to raise_error(ArgumentError, 'Provide either url, or project_id and merge_request_iid')
      end
    end

    context 'when merge_request_iid is provided without project_id' do
      let(:params) { { merge_request_iid: merge_request.iid, body: 'Test comment' } }

      it 'raises ArgumentError' do
        expect { tool.build_variables }
          .to raise_error(ArgumentError, 'Provide either url, or project_id and merge_request_iid')
      end
    end

    context 'when merge request does not exist' do
      let(:params) { { project_id: project.id.to_s, merge_request_iid: non_existing_record_iid, body: 'Test comment' } }

      it 'raises ArgumentError' do
        expect { tool.build_variables }
          .to raise_error(ArgumentError, 'Merge request not found: it does not exist or you do not have access to it.')
      end
    end

    context 'when user lacks access to the merge request' do
      let_it_be(:private_project) { create(:project, :private) }
      let_it_be(:private_merge_request) { create(:merge_request, source_project: private_project) }

      let(:params) do
        { project_id: private_project.id.to_s, merge_request_iid: private_merge_request.iid, body: 'Test comment' }
      end

      it 'raises ArgumentError' do
        expect { tool.build_variables }
          .to raise_error(ArgumentError, 'Merge request not found: it does not exist or you do not have access to it.')
      end
    end
  end

  describe '#execute' do
    it 'executes mutation with correct variables' do
      allow(GitlabSchema).to receive(:execute).and_call_original

      tool.execute

      expect(GitlabSchema).to have_received(:execute).with(
        anything,
        variables: hash_including(
          input: hash_including(
            noteableId: merge_request.to_global_id.to_s,
            body: 'Test comment'
          )
        ),
        context: hash_including(current_user: user)
      )
    end

    it 'returns note data', :aggregate_failures do
      result = tool.execute

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]['note']).to be_a(Hash)
      expect(result[:structuredContent]['note']['id']).to be_present
      expect(result[:structuredContent]['note']['body']).to eq('Test comment')
    end

    context 'when replying to a discussion' do
      let(:params) do
        {
          project_id: project.id.to_s,
          merge_request_iid: merge_request.iid,
          body: 'Reply comment',
          discussion_id: discussion.to_global_id.to_s
        }
      end

      it 'creates a reply in the discussion' do
        result = tool.execute

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['note']['discussion']['id']).to eq(discussion.to_global_id.to_s)
      end
    end

    context 'when merge request does not exist' do
      let(:params) { { project_id: project.id.to_s, merge_request_iid: non_existing_record_iid, body: 'Test' } }

      it 'raises error before executing GraphQL' do
        expect { tool.execute }.to raise_error(ArgumentError,
          'Merge request not found: it does not exist or you do not have access to it.')
      end
    end
  end
end
