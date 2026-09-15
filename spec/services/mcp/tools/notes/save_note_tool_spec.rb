# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Notes::SaveNoteTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:work_item) { create(:work_item, :issue, project: project, iid: 42) }
  let_it_be(:mr_discussion, freeze: false) do
    create(:discussion_note_on_merge_request, project: project, noteable: merge_request).discussion
  end

  let_it_be_with_reload(:work_item_discussion) do
    create(:discussion_note_on_issue, project: project, noteable: work_item).discussion
  end

  let(:params) { { project_id: project.id.to_s, merge_request_iid: merge_request.iid, body: 'Test comment' } }
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

      expect(operation).to include('mutation createNote')
      expect(operation).to include('createNote(input: $input)')
    end
  end

  describe '#build_variables' do
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

    context 'when neither url nor an iid is provided' do
      let(:params) { { project_id: project.id.to_s, body: 'Test comment' } }

      it 'raises ArgumentError' do
        expect { tool.build_variables }.to raise_error(
          ArgumentError,
          'Provide url, or merge_request_iid with project_id, or work_item_iid with project_id or group_id'
        )
      end
    end

    context 'when both merge_request_iid and work_item_iid are provided' do
      let(:params) do
        {
          project_id: project.id.to_s,
          merge_request_iid: merge_request.iid,
          work_item_iid: work_item.iid,
          body: 'Test comment'
        }
      end

      it 'raises ArgumentError' do
        expect { tool.build_variables }
          .to raise_error(ArgumentError, 'Provide only one of merge_request_iid or work_item_iid')
      end
    end

    context 'with a merge request target' do
      it 'builds variables with the merge request global ID and body' do
        variables = tool.build_variables

        expect(variables[:input]).to include(
          noteableId: merge_request.to_global_id.to_s,
          body: 'Test comment'
        )
      end

      it 'includes discussion_id when provided' do
        params[:discussion_id] = mr_discussion.to_global_id.to_s
        variables = tool.build_variables

        expect(variables[:input][:discussionId]).to eq(mr_discussion.to_global_id.to_s)
      end

      it 'resolves the merge request from a URL' do
        params.delete(:merge_request_iid)
        params[:url] = Gitlab::UrlBuilder.build(merge_request)
        variables = tool.build_variables

        expect(variables[:input][:noteableId]).to eq(merge_request.to_global_id.to_s)
      end

      context 'when the url is neither a merge request nor a work item url' do
        let(:params) { { url: "https://gitlab.com/#{project.full_path}/-/wikis/home", body: 'Test comment' } }

        it 'raises an ArgumentError mentioning both url formats' do
          expect { tool.build_variables }.to raise_error(
            ArgumentError,
            'URL must be a merge request URL (.../-/merge_requests/<iid>) or a work item URL ' \
              '(.../-/work_items/<iid>). For issues, pass project_id and work_item_iid instead'
          )
        end
      end

      context 'when merge_request_iid is provided without project_id' do
        let(:params) { { merge_request_iid: merge_request.iid, body: 'Test comment' } }

        it 'raises ArgumentError' do
          expect { tool.build_variables }
            .to raise_error(ArgumentError, 'Provide either url, or project_id and merge_request_iid')
        end
      end

      context 'when the merge request does not exist' do
        let(:params) do
          { project_id: project.id.to_s, merge_request_iid: non_existing_record_iid, body: 'Test comment' }
        end

        it 'raises ArgumentError' do
          expect { tool.build_variables }
            .to raise_error(ArgumentError, 'Merge request not found or inaccessible')
        end
      end

      context 'when the url points at a merge request in a nested subgroup' do
        let_it_be(:subgroup) { create(:group, :nested) }
        let_it_be(:nested_project) { create(:project, :public, group: subgroup) }
        let_it_be(:nested_merge_request) { create(:merge_request, source_project: nested_project) }

        let(:params) { { url: Gitlab::UrlBuilder.build(nested_merge_request), body: 'Test comment' } }

        before_all do
          nested_project.add_developer(user)
        end

        it 'reconstructs the full namespace path and resolves the merge request' do
          expect(nested_project.full_path.count('/')).to be >= 2

          variables = tool.build_variables

          expect(variables[:input][:noteableId]).to eq(nested_merge_request.to_global_id.to_s)
        end
      end

      context 'when the user lacks access to the merge request' do
        let_it_be(:private_project) { create(:project, :private) }
        let_it_be(:private_merge_request) { create(:merge_request, source_project: private_project) }

        let(:params) do
          { project_id: private_project.id.to_s, merge_request_iid: private_merge_request.iid, body: 'Test comment' }
        end

        it 'raises the same not-found error as a nonexistent merge request' do
          expect { tool.build_variables }
            .to raise_error(ArgumentError, 'Merge request not found or inaccessible')
        end
      end

      it 'includes the internal flag when provided' do
        params[:internal] = true
        variables = tool.build_variables

        expect(variables[:input][:internal]).to be true
      end
    end

    context 'with a work item target' do
      let(:params) { { project_id: project.id.to_s, work_item_iid: work_item.iid, body: 'Test comment' } }

      it 'builds variables with the work item global ID and body' do
        variables = tool.build_variables

        expect(variables[:input]).to include(
          noteableId: work_item.to_global_id.to_s,
          body: 'Test comment'
        )
      end

      it 'includes the internal flag when provided' do
        params[:internal] = true
        variables = tool.build_variables

        expect(variables[:input][:internal]).to be true
      end

      it 'includes discussion_id when provided' do
        params[:discussion_id] = work_item_discussion.to_global_id.to_s
        variables = tool.build_variables

        expect(variables[:input][:discussionId]).to eq(work_item_discussion.to_global_id.to_s)
      end

      it 'omits optional fields when not provided' do
        variables = tool.build_variables

        expect(variables[:input]).not_to have_key(:internal)
        expect(variables[:input]).not_to have_key(:discussionId)
      end

      it 'resolves the work item from a URL' do
        params.delete(:project_id)
        params[:url] = "https://gitlab.com/#{project.full_path}/-/work_items/#{work_item.iid}"
        variables = tool.build_variables

        expect(variables[:input][:noteableId]).to eq(work_item.to_global_id.to_s)
      end

      context 'when work_item_iid is provided without project_id or group_id' do
        let(:params) { { work_item_iid: work_item.iid, body: 'Test comment' } }

        it 'raises ArgumentError' do
          expect { tool.build_variables }
            .to raise_error(ArgumentError, 'Provide project_id or group_id with work_item_iid')
        end
      end

      context 'when project_id is an empty string' do
        let(:params) do
          {
            project_id: '', group_id: non_existing_record_id.to_s, work_item_iid: work_item.iid,
            body: 'Test comment'
          }
        end

        it 'falls back to group_id instead of treating the blank string as present' do
          expect { tool.build_variables }
            .to raise_error(StandardError, "Group '#{non_existing_record_id}' not found or inaccessible")
        end
      end

      context 'when the work item does not exist' do
        let(:params) { { project_id: project.id.to_s, work_item_iid: non_existing_record_iid, body: 'Test comment' } }

        it 'raises ArgumentError' do
          expect { tool.build_variables }
            .to raise_error(ArgumentError, "Work item ##{non_existing_record_iid} not found or inaccessible")
        end
      end

      context 'when user lacks access to the parent project' do
        let_it_be(:private_project) { create(:project, :private) }

        let(:params) { { project_id: private_project.id.to_s, work_item_iid: 1, body: 'Test comment' } }

        it 'raises the uniform not-found error' do
          expect { tool.build_variables }
            .to raise_error(StandardError, /not found or inaccessible/)
        end
      end
    end
  end

  describe '#execute' do
    it 'creates a comment on a merge request', :aggregate_failures do
      result = tool.execute

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]['note']['body']).to eq('Test comment')
    end

    it 'creates a comment on a work item', :aggregate_failures do
      params = { project_id: project.id.to_s, work_item_iid: work_item.iid, body: 'Test comment' }
      result = described_class.new(current_user: user, params: params).execute

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]['note']['body']).to eq('Test comment')
    end

    it 'returns the full payload shape the tool promises', :aggregate_failures do
      result = tool.execute

      expect(result[:structuredContent].keys).to match_array(%w[note errors])

      note = result[:structuredContent]['note']
      expect(note.keys).to match_array(%w[id body internal createdAt updatedAt url author discussion])
      expect(note['author'].keys).to match_array(%w[id name username])
      expect(note['author']['username']).to eq(user.username)
      expect(note['discussion'].keys).to match_array(%w[id])
    end

    it 'creates an internal comment on a merge request', :aggregate_failures do
      params[:internal] = true
      result = tool.execute

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]['note']['internal']).to be(true)
    end

    context 'when replying to a merge request discussion' do
      let(:params) do
        {
          project_id: project.id.to_s,
          merge_request_iid: merge_request.iid,
          body: 'Reply comment',
          discussion_id: mr_discussion.to_global_id.to_s
        }
      end

      it 'creates a reply in the discussion' do
        result = tool.execute

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['note']['discussion']['id']).to eq(mr_discussion.to_global_id.to_s)
      end
    end
  end
end
