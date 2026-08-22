# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::WorkItems::GetWorkItemTool, feature_category: :mcp_server do
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

      it 'enables only the requested facet' do
        expect(tool.build_variables).to include(includeNotes: true, includeRelatedMergeRequests: false)
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
        expect { result }.to raise_error(ArgumentError, /not found/)
      end
    end

    context 'when the work item is confidential and the caller cannot read it' do
      let_it_be(:confidential_work_item) { create(:work_item, :confidential, project: project) }
      let_it_be(:non_member) { create(:user) }

      let(:arguments) { { project_id: project.id.to_s, work_item_iid: confidential_work_item.iid } }
      let(:tool) { described_class.new(current_user: non_member, params: arguments, version: '0.1.0') }

      it 'raises the same not-found error as a nonexistent work item' do
        expect { result }.to raise_error(ArgumentError, /not found/)
      end
    end
  end
end
