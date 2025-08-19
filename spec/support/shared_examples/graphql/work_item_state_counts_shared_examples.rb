# frozen_string_literal: true

require 'spec_helper'

# Context / examples shared between groups and projects
RSpec.shared_context 'with work item state count shared context' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }

  let(:params) { {} }
  subject(:query_counts) { post_graphql(query, current_user: current_user) }
end

RSpec.shared_examples 'shared work item state count functionality' do
  it_behaves_like 'a working graphql query' do
    before do
      query_counts
    end
  end

  context 'when filters are provided' do
    context 'when filtering by author username' do
      let(:params) { { 'authorUsername' => current_user.username } }

      it 'returns the correct counts for each state' do
        query_counts

        expect(work_item_counts).to eq('all' => 1, 'opened' => 1, 'closed' => 0)
      end
    end

    context 'when searching by text' do
      let(:params) { { search: 'Foo' } }

      it 'returns the correct counts for each status' do
        query_counts

        expect(work_item_counts).to eq('all' => 1, 'opened' => 1, 'closed' => 0)
      end
    end

    context 'when searching in title' do
      let(:params) { { search: 'Foo', in: [:TITLE] } }

      it 'returns the correct counts for each status' do
        query_counts

        expect(work_item_counts).to eq('all' => 1, 'opened' => 1, 'closed' => 0)
      end
    end

    context 'when searching in description' do
      let(:params) { { search: 'Bar', in: [:DESCRIPTION] } }

      it 'returns the correct counts for each status' do
        query_counts

        expect(work_item_counts).to eq('all' => 1, 'opened' => 0, 'closed' => 1)
      end
    end

    context 'when filtering by label name' do
      let(:params) { { 'labelName' => [label.name] } }

      it 'returns the correct counts for each state' do
        query_counts

        expect(work_item_counts).to eq('all' => 2, 'opened' => 1, 'closed' => 1)
      end
    end
  end
end

RSpec.shared_examples 'resolves work item state counts in a group' do |query_type|
  include_context 'with work item state count shared context'

  let_it_be(:milestone) { create(:milestone, group: group) }
  let_it_be(:label) { create(:group_label, group: group) }
  let_it_be(:work_item_opened1) do
    create(:work_item, namespace: group, milestone_id: milestone.id, labels: [label], title: 'Foo')
  end

  let_it_be(:work_item_opened2) { create(:work_item, :confidential, namespace: group, author: current_user) }
  let_it_be(:work_item_closed1) do
    create(:work_item, :closed, :confidential, namespace: group, milestone_id: milestone.id)
  end

  let_it_be(:work_item_closed2) do
    create(:work_item, :epic, :closed, namespace: group, assignees: [current_user], labels: [label], description: 'Bar')
  end

  before do
    stub_licensed_features(epics: true)
  end

  context 'with work items count data' do
    let(:work_item_counts) { graphql_data.dig(query_type.to_s, 'workItemStateCounts') }

    context 'with group permissions' do
      before_all do
        group.add_developer(current_user)
      end

      it 'returns the correct counts for each state' do
        query_counts

        expect(work_item_counts).to eq('all' => 4, 'opened' => 2, 'closed' => 2)
      end

      it_behaves_like 'shared work item state count functionality' do
        let(:query_type) { query_type }
      end

      context 'when filters are provided' do
        context 'when filtering by assignee usernames' do
          let(:params) { { 'assigneeUsernames' => [current_user.username] } }

          it 'returns the correct counts for each state' do
            query_counts

            expect(work_item_counts).to eq('all' => 1, 'opened' => 0, 'closed' => 1)
          end
        end

        context 'when filtering by confidential' do
          let(:params) { { 'confidential' => true } }

          it 'returns the correct counts for each state' do
            query_counts

            expect(work_item_counts).to eq('all' => 2, 'opened' => 1, 'closed' => 1)
          end
        end

        context 'when filtering by milestone title' do
          let(:params) { { 'milestoneTitle' => [milestone.title] } }

          it 'returns the correct counts for each state' do
            query_counts

            expect(work_item_counts).to eq('all' => 2, 'opened' => 1, 'closed' => 1)
          end
        end

        context 'when filtering by type' do
          let(:params) { { 'types' => [:ISSUE] } }

          it 'returns the correct counts for each state' do
            query_counts

            expect(work_item_counts).to eq('all' => 3, 'opened' => 2, 'closed' => 1)
          end
        end
      end
    end

    context "without group permissions" do
      it 'does not return work item counts' do
        query_counts

        expect_graphql_errors_to_be_empty
        expect(work_item_counts).to be_nil
      end
    end
  end
end

RSpec.shared_examples 'resolves work item state counts in a project' do |query_type|
  include_context 'with work item state count shared context'

  let_it_be(:project) { create(:project, :repository, :private, group: group) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:label) { create(:label, project: project) }
  let_it_be(:work_item_opened1) do
    create(:work_item, project: project, milestone_id: milestone.id, title: 'Foo', labels: [label])
  end

  let_it_be(:work_item_opened2) do
    create(:work_item, project: project, author: current_user, assignees: [current_user], milestone_id: milestone.id)
  end

  let_it_be(:work_item_closed) do
    create(:work_item, :closed, :confidential, project: project, description: 'Bar', labels: [label])
  end

  context 'with work items count data' do
    let(:work_item_counts) { graphql_data.dig(query_type.to_s, 'workItemStateCounts') }

    context 'with project permissions' do
      before_all do
        group.add_developer(current_user)
      end

      it 'returns the correct counts for each state' do
        query_counts

        expect(work_item_counts).to eq('all' => 3, 'opened' => 2, 'closed' => 1)
      end

      context 'when other work items are present in the group' do
        it 'only returns counts for work items in the current project' do
          other_project = create(:project, :repository, group: group)
          create(:work_item, project: other_project)
          query_counts

          expect(work_item_counts).to eq('all' => 3, 'opened' => 2, 'closed' => 1)
        end
      end

      it_behaves_like 'shared work item state count functionality' do
        let(:query_type) { query_type }
      end

      context 'when filters are provided' do
        context 'when filtering by assignee usernames' do
          let(:params) { { 'assigneeUsernames' => [current_user.username] } }

          it 'returns the correct counts for each state' do
            query_counts

            expect(work_item_counts).to eq('all' => 1, 'opened' => 1, 'closed' => 0)
          end
        end

        context 'when filtering by confidential' do
          let(:params) { { 'confidential' => true } }

          it 'returns the correct counts for each state' do
            query_counts

            expect(work_item_counts).to eq('all' => 1, 'opened' => 0, 'closed' => 1)
          end
        end

        context 'when filtering by milestone title' do
          let(:params) { { 'milestoneTitle' => [milestone.title] } }

          it 'returns the correct counts for each state' do
            query_counts

            expect(work_item_counts).to eq('all' => 2, 'opened' => 2, 'closed' => 0)
          end
        end

        context 'when filtering by reaction emoji' do
          before_all do
            create(:award_emoji, :upvote, user: current_user, awardable: work_item_opened1)
            create(:award_emoji, :upvote, user: current_user, awardable: work_item_closed)
          end

          let(:params) { { 'myReactionEmoji' => AwardEmoji::THUMBS_UP } }

          it 'returns the correct counts for each state' do
            query_counts

            expect(work_item_counts).to eq('all' => 2, 'opened' => 1, 'closed' => 1)
          end
        end
      end
    end

    context "without project permissions" do
      it 'does not return work item counts' do
        query_counts

        expect_graphql_errors_to_be_empty
        expect(work_item_counts).to be_nil
      end
    end
  end
end
