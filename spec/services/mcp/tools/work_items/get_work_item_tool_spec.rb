# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::WorkItems::GetWorkItemTool, feature_category: :mcp_server do
  let(:not_found_error) { ::Mcp::Tools::Concerns::ResourceFinder::ResourceNotFoundError }
  let(:forbidden_error) { ::Mcp::Tools::Concerns::ResourceFinder::ResourceForbiddenError }

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:work_item) { create(:work_item, project: project, title: 'An issue', description: 'Body') }

  let(:arguments) { {} }
  let(:tool) { described_class.new(current_user: user, params: arguments, version: '0.1.0') }

  before_all do
    project.add_developer(user)
  end

  describe '#build_variables' do
    context 'with project_id and work_item_iid' do
      let(:arguments) { { project_id: project.id.to_s, work_item_iid: work_item.iid } }

      it 'resolves the work item global ID with facet defaults' do
        expect(tool.build_variables).to eq(
          id: work_item.to_global_id.to_s,
          includeNotes: false,
          includeDiscussions: false,
          includeRelatedMergeRequests: false,
          relatedMergeRequestsFirst: 20
        )
      end
    end

    context 'with a work item URL' do
      let(:arguments) { { url: "#{Gitlab.config.gitlab.url}/#{project.full_path}/-/work_items/#{work_item.iid}" } }

      it 'resolves the work item global ID' do
        expect(tool.build_variables[:id]).to eq(work_item.to_global_id.to_s)
      end
    end

    context 'with facets' do
      let(:arguments) do
        { project_id: project.id.to_s, work_item_iid: work_item.iid, include: %w[notes] }
      end

      it 'enables only the requested facet with the notes page default' do
        expect(tool.build_variables).to include(
          includeNotes: true, includeRelatedMergeRequests: false, notesFirst: 100
        )
      end
    end

    context 'with the discussions facet' do
      let(:arguments) do
        { project_id: project.id.to_s, work_item_iid: work_item.iid, include: %w[discussions] }
      end

      it 'enables only the discussions facet with the page default', :aggregate_failures do
        variables = tool.build_variables

        expect(variables).to include(
          includeNotes: false, includeDiscussions: true, includeRelatedMergeRequests: false, discussionsFirst: 20
        )
        expect(variables).not_to include(:discussionsAfter, :discussionsFilter)
      end

      context 'with pagination and a filter' do
        let(:arguments) do
          super().merge(discussions_first: 5, discussions_after: 'abc', discussions_filter: 'only_comments')
        end

        it 'passes them to the query' do
          expect(tool.build_variables).to include(
            discussionsFirst: 5, discussionsAfter: 'abc', discussionsFilter: 'ONLY_COMMENTS'
          )
        end
      end
    end

    context 'with discussions parameters but without the discussions facet' do
      let(:arguments) do
        {
          project_id: project.id.to_s,
          work_item_iid: work_item.iid,
          discussions_first: 5,
          discussions_filter: 'only_comments'
        }
      end

      it 'ignores them' do
        expect(tool.build_variables).not_to include(:discussionsFirst, :discussionsAfter, :discussionsFilter)
      end
    end

    context 'with related merge request pagination' do
      where(:pagination_arguments, :expected_first, :expected_after) do
        [
          [{ related_merge_requests_first: 5, related_merge_requests_after: 'abc' }, 5, 'abc'],
          [{ mr_page_size: 7, mr_pagination_cursor: 'xyz' }, 7, 'xyz'],
          [{ related_merge_requests_first: 5, mr_page_size: 7 }, 5, nil],
          [{ related_merge_requests_after: 'abc', mr_pagination_cursor: 'xyz' }, 20, 'abc'],
          [{}, 20, nil]
        ]
      end

      with_them do
        let(:arguments) do
          { project_id: project.id.to_s, work_item_iid: work_item.iid }.merge(pagination_arguments)
        end

        it 'prefers the canonical parameters over the deprecated aliases', :aggregate_failures do
          variables = tool.build_variables

          expect(variables[:relatedMergeRequestsFirst]).to eq(expected_first)
          expect(variables[:relatedMergeRequestsAfter]).to eq(expected_after)
        end
      end
    end

    context 'without work_item_iid' do
      let(:arguments) { { project_id: project.id.to_s } }

      it 'raises an ArgumentError' do
        expect { tool.build_variables }.to raise_error(ArgumentError, /work_item_iid/)
      end
    end
  end

  describe '#execute' do
    subject(:result) { tool.execute }

    context 'with the base fetch' do
      let(:arguments) { { project_id: project.id.to_s, work_item_iid: work_item.iid } }

      it 'returns the work item without facet payloads', :aggregate_failures do
        expect(result[:isError]).to be(false)

        work_item_data = result[:structuredContent]
        expect(work_item_data['iid']).to eq(work_item.iid.to_s)
        expect(work_item_data['title']).to eq('An issue')
        expect(work_item_data['workItemType']['name']).to eq('Issue')

        notes_widget = work_item_data['widgets'].find { |widget| widget['type'] == 'NOTES' }
        expect(notes_widget).not_to have_key('notes')
      end
    end

    context 'with the notes facet' do
      let_it_be(:note) { create(:note, project: project, noteable: work_item, note: 'A comment') }

      let(:arguments) do
        { project_id: project.id.to_s, work_item_iid: work_item.iid, include: %w[notes] }
      end

      it 'returns the notes payload', :aggregate_failures do
        notes_widget = result[:structuredContent]['widgets'].find { |widget| widget['type'] == 'NOTES' }

        expect(notes_widget['notes']['nodes'].pluck('body')).to include('A comment')
        expect(notes_widget['notes']['pageInfo']).to include('endCursor', 'hasNextPage')
      end
    end

    context 'with the notes facet and a commit cross-reference system note', :request_store do
      let_it_be(:repo_project) { create(:project, :public, :repository, group: group, developers: user) }
      let_it_be(:repo_work_item) { create(:work_item, project: repo_project) }
      let_it_be_with_reload(:system_note) do
        create(:note, :system, project: repo_project, noteable: repo_work_item,
          note: "mentioned in commit #{repo_project.commit.sha}").tap do |note|
          create(:system_note_metadata, note: note, action: 'cross_reference')
        end
      end

      let(:arguments) do
        { project_id: repo_project.id.to_s, work_item_iid: repo_work_item.iid, include: %w[notes] }
      end

      before do
        # Cold markdown cache: note redaction re-renders the note, loading the commit from Gitaly
        system_note.update_columns(note_html: nil, cached_markdown_version: nil)
      end

      it 'returns the notes payload when redaction calls Gitaly mid-execution', :aggregate_failures do
        expect(result[:isError]).to be(false)

        notes_widget = result[:structuredContent]['widgets'].find { |widget| widget['type'] == 'NOTES' }
        expect(notes_widget['notes']['nodes'].pluck('body')).to include(system_note.note)
      end
    end

    context 'with the discussions facet' do
      let_it_be(:discussion_work_item) { create(:work_item, project: project) }
      let_it_be(:thread_start) do
        create(:discussion_note_on_work_item, project: project, noteable: discussion_work_item, note: 'Thread start')
      end

      let_it_be(:thread_reply) do
        create(:discussion_note_on_work_item, project: project, noteable: discussion_work_item,
          note: 'Thread reply', in_reply_to: thread_start)
      end

      let_it_be(:resolved_thread) do
        create(:discussion_note_on_work_item, :resolved, project: project, noteable: discussion_work_item,
          note: 'Resolved thread')
      end

      let_it_be(:single_note) do
        create(:note, project: project, noteable: discussion_work_item, note: 'A single comment')
      end

      let_it_be(:system_note) do
        create(:note, :system, project: project, noteable: discussion_work_item, note: 'changed the description')
      end

      let_it_be(:internal_note) do
        create(:note, :confidential, project: project, noteable: discussion_work_item, note: 'An internal comment')
      end

      let(:arguments) do
        { project_id: project.id.to_s, work_item_iid: discussion_work_item.iid, include: %w[discussions] }
      end

      def discussions_connection
        result[:structuredContent]['widgets'].find { |widget| widget['type'] == 'NOTES' }['discussions']
      end

      def discussions_by_first_note
        discussions_connection['nodes'].index_by { |discussion| discussion['notes']['nodes'].first['body'] }
      end

      def note_bodies
        discussions_connection['nodes'].flat_map { |discussion| discussion['notes']['nodes'].pluck('body') }
      end

      it 'returns each thread with its resolution state and its notes', :aggregate_failures do
        expect(result[:isError]).to be(false)
        expect(discussions_connection['pageInfo']).to include('endCursor', 'hasNextPage')

        threads = discussions_by_first_note

        expect(threads['Thread start']).to include('id' => be_present, 'resolvable' => true, 'resolved' => false)
        expect(threads['Thread start']['notes']['nodes'].pluck('body')).to eq(['Thread start', 'Thread reply'])
        expect(threads['Resolved thread']).to include('resolvable' => true, 'resolved' => true)
        expect(threads['A single comment']['notes']['nodes'].size).to eq(1)
        expect(threads['changed the description']).to include('resolvable' => false)
        expect(threads['changed the description']['notes']['nodes'].first['system']).to be(true)
        expect(threads['An internal comment']['notes']['nodes'].first['internal']).to be(true)
      end

      it 'does not return the notes facet' do
        notes_widget = result[:structuredContent]['widgets'].find { |widget| widget['type'] == 'NOTES' }

        expect(notes_widget).not_to have_key('notes')
      end

      context 'with discussions_filter only_comments' do
        let(:arguments) { super().merge(discussions_filter: 'only_comments') }

        it 'leaves out system notes', :aggregate_failures do
          expect(note_bodies).to include('Thread start', 'A single comment')
          expect(note_bodies).not_to include('changed the description')
        end
      end

      context 'with discussions_filter only_activity' do
        let(:arguments) { super().merge(discussions_filter: 'only_activity') }

        it 'returns only system notes' do
          expect(note_bodies).to contain_exactly('changed the description')
        end
      end

      context 'when the caller cannot read internal notes' do
        let_it_be(:non_member) { create(:user) }

        let(:tool) { described_class.new(current_user: non_member, params: arguments, version: '0.1.0') }

        it 'leaves out internal notes', :aggregate_failures do
          expect(note_bodies).to include('Thread start', 'A single comment')
          expect(note_bodies).not_to include('An internal comment')
        end
      end

      context 'when the work item has no notes' do
        let(:arguments) do
          { project_id: project.id.to_s, work_item_iid: work_item.iid, include: %w[discussions] }
        end

        it 'returns an empty connection', :aggregate_failures do
          expect(discussions_connection['nodes']).to be_empty
          expect(discussions_connection['pageInfo']['hasNextPage']).to be(false)
        end
      end
    end

    context 'with the related_merge_requests facet' do
      let(:arguments) do
        {
          project_id: project.id.to_s,
          work_item_iid: work_item.iid,
          include: %w[related_merge_requests]
        }
      end

      it 'returns the related merge requests connection', :aggregate_failures do
        development_widget = result[:structuredContent]['widgets']
          .find { |widget| widget['type'] == 'DEVELOPMENT' }

        expect(development_widget['relatedMergeRequests']['nodes']).to be_an(Array)
        expect(development_widget['relatedMergeRequests']['pageInfo']).to include('endCursor', 'hasNextPage')
      end
    end

    context 'when the work item does not exist' do
      let(:arguments) { { project_id: project.id.to_s, work_item_iid: non_existing_record_iid } }

      it 'raises the uniform not-found error' do
        expect { result }.to raise_error(not_found_error, /not found/)
      end
    end

    context 'when the work item is confidential and the caller cannot read it' do
      let_it_be(:confidential_work_item) { create(:work_item, :confidential, project: project) }
      let_it_be(:non_member) { create(:user) }

      let(:arguments) { { project_id: project.id.to_s, work_item_iid: confidential_work_item.iid } }
      let(:tool) { described_class.new(current_user: non_member, params: arguments, version: '0.1.0') }

      it 'raises with the same message as a nonexistent work item' do
        expect { result }.to raise_error(forbidden_error, /not found/)
      end
    end

    context 'when the query resolves but returns no work item' do
      let(:arguments) { { project_id: project.id.to_s, work_item_iid: work_item.iid } }

      before do
        allow(GitlabSchema).to receive(:execute).and_return({ 'data' => { 'workItem' => nil } })
      end

      it 'reports a not-found error without leaking whether the work item exists', :aggregate_failures do
        expect(result[:isError]).to be(true)
        expect(result[:reason]).to eq(:not_found)
        expect(result[:content].first[:text]).to eq('Work item not found or inaccessible.')
      end
    end
  end
end
