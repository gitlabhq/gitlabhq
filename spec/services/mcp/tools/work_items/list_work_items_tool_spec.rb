# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::WorkItems::ListWorkItemsTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:label) { create(:label, project: project, title: 'bug') }
  let_it_be(:author) { create(:user) }

  let_it_be(:issue_work_item) do
    create(:work_item, project: project, title: 'An issue', labels: [label], author: author)
  end

  let_it_be(:task_work_item) { create(:work_item, :task, project: project, title: 'A task') }
  let_it_be(:closed_work_item) { create(:work_item, :closed, project: project, title: 'A closed issue') }

  let(:arguments) { {} }
  let(:tool) { described_class.new(current_user: user, params: arguments, version: '0.1.0') }

  before_all do
    project.add_developer(user)
  end

  describe '#build_variables' do
    context 'with project_id' do
      let(:arguments) { { project_id: project.id.to_s } }

      it 'scopes to the project full path with defaults' do
        expect(tool.build_variables).to include(fullPath: project.full_path, firstPageSize: 20)
      end
    end

    context 'with group_id' do
      let(:arguments) { { group_id: group.id.to_s } }

      it 'scopes to the group full path' do
        expect(tool.build_variables).to include(fullPath: group.full_path)
      end
    end

    context 'with a project work items URL' do
      let(:arguments) { { url: "#{Gitlab.config.gitlab.url}/#{project.full_path}/-/work_items/1" } }

      it 'scopes to the project full path' do
        expect(tool.build_variables).to include(fullPath: project.full_path)
      end
    end

    context 'with no identification' do
      let(:arguments) { { state: 'opened' } }

      it 'raises an ArgumentError' do
        expect { tool.build_variables }.to raise_error(ArgumentError, /project_id or group_id/)
      end
    end

    context 'with every CE filter set' do
      let(:arguments) do
        {
          project_id: project.id.to_s,
          state: 'opened',
          search: 'text',
          author_username: 'jane',
          assignee_usernames: %w[jo],
          label_name: %w[bug],
          milestone_title: %w[17.0],
          types: %w[ISSUE],
          created_after: '2026-01-01T00:00:00Z',
          created_before: '2026-02-01T00:00:00Z',
          updated_after: '2026-03-01T00:00:00Z',
          updated_before: '2026-04-01T00:00:00Z',
          due_after: '2026-05-01T00:00:00Z',
          due_before: '2026-06-01T00:00:00Z',
          sort: 'UPDATED_DESC',
          first: 5,
          after: 'cursor123'
        }
      end

      it 'maps each parameter onto its GraphQL variable' do
        expect(tool.build_variables).to eq(
          fullPath: project.full_path,
          state: 'opened',
          search: 'text',
          authorUsername: 'jane',
          assigneeUsernames: %w[jo],
          labelName: %w[bug],
          milestoneTitle: %w[17.0],
          types: %w[ISSUE],
          createdAfter: '2026-01-01T00:00:00Z',
          createdBefore: '2026-02-01T00:00:00Z',
          updatedAfter: '2026-03-01T00:00:00Z',
          updatedBefore: '2026-04-01T00:00:00Z',
          dueAfter: '2026-05-01T00:00:00Z',
          dueBefore: '2026-06-01T00:00:00Z',
          sort: 'UPDATED_DESC',
          includeDescendants: true,
          excludeProjects: false,
          excludeGroupWorkItems: false,
          firstPageSize: 5,
          afterCursor: 'cursor123'
        )
      end
    end

    context 'with a milestone wildcard' do
      let(:arguments) { { project_id: project.id.to_s, milestone_wildcard_id: 'NONE' } }

      it 'maps it onto milestoneWildcardId' do
        expect(tool.build_variables).to include(milestoneWildcardId: 'NONE')
      end
    end
  end

  describe '#execute' do
    subject(:result) { tool.execute }

    context 'when listing project work items' do
      let(:arguments) { { project_id: project.id.to_s } }

      it 'returns compact rows and pagination info', :aggregate_failures do
        expect(result[:isError]).to be(false)

        rows = result[:structuredContent]['work_items']
        expect(rows.pluck('title')).to include('An issue', 'A task', 'A closed issue')

        row = rows.find { |r| r['title'] == 'An issue' }
        expect(row.keys).to match_array(%w[id iid title state webUrl reference createdAt updatedAt workItemType])
        expect(row['workItemType'].keys).to match_array(%w[id name])
        expect(result[:structuredContent]['pageInfo'].keys).to contain_exactly('endCursor', 'hasNextPage')
      end
    end

    context 'when listing through the group with descendants' do
      let(:arguments) { { group_id: group.id.to_s } }

      it 'includes work items of descendant projects' do
        titles = result[:structuredContent]['work_items'].pluck('title')

        expect(titles).to include('An issue')
      end
    end

    context 'with a state filter' do
      let(:arguments) { { project_id: project.id.to_s, state: 'closed' } }

      it 'narrows the result' do
        titles = result[:structuredContent]['work_items'].pluck('title')

        expect(titles).to contain_exactly('A closed issue')
      end
    end

    context 'with label and author filters' do
      let(:arguments) do
        { project_id: project.id.to_s, label_name: %w[bug], author_username: author.username }
      end

      it 'narrows the result' do
        titles = result[:structuredContent]['work_items'].pluck('title')

        expect(titles).to contain_exactly('An issue')
      end
    end

    context 'with a types filter' do
      let(:arguments) { { project_id: project.id.to_s, types: %w[TASK] } }

      it 'narrows the result' do
        titles = result[:structuredContent]['work_items'].pluck('title')

        expect(titles).to contain_exactly('A task')
      end
    end

    context 'with cursor pagination' do
      let(:arguments) { { project_id: project.id.to_s, first: 2 } }

      it 'pages through without overlap', :aggregate_failures do
        first_page = result[:structuredContent]
        expect(first_page['work_items'].size).to eq(2)
        expect(first_page['pageInfo']['hasNextPage']).to be(true)

        second_tool = described_class.new(
          current_user: user,
          params: { project_id: project.id.to_s, first: 2, after: first_page['pageInfo']['endCursor'] },
          version: '0.1.0'
        )
        second_page = second_tool.execute[:structuredContent]

        expect(second_page['work_items'].pluck('iid') & first_page['work_items'].pluck('iid')).to be_empty
      end
    end

    context 'when the namespace does not exist' do
      let(:arguments) { { project_id: non_existing_record_id.to_s } }

      it 'raises a not-found error' do
        expect { result }.to raise_error(StandardError, /not found or inaccessible/)
      end
    end

    context 'when more than one of url, project_id, and group_id is supplied' do
      let(:arguments) { { project_id: project.id.to_s, group_id: group.full_path } }

      it 'rejects the call instead of silently picking one' do
        expect { result }.to raise_error(ArgumentError, /Provide exactly one of url, project_id, or group_id/)
      end
    end

    context 'when the namespace exists but the caller cannot read it' do
      let_it_be(:private_project) { create(:project, :private) }
      let_it_be(:non_member_user) { create(:user) }

      let(:arguments) { { project_id: private_project.id.to_s } }
      let(:tool) { described_class.new(current_user: non_member_user, params: arguments, version: '0.1.0') }

      it 'denies access' do
        expect { result }.to raise_error(ArgumentError, /Access denied/)
      end
    end

    context 'when a confidential work item is invisible to the caller' do
      let_it_be(:confidential_work_item) do
        create(:work_item, :confidential, project: project, title: 'A secret issue')
      end

      let_it_be(:non_member_user) { create(:user) }

      let(:arguments) { { project_id: project.id.to_s } }
      let(:tool) { described_class.new(current_user: non_member_user, params: arguments, version: '0.1.0') }

      it 'omits it from the result' do
        titles = result[:structuredContent]['work_items'].pluck('title')

        expect(titles).not_to include('A secret issue')
      end
    end
  end
end
