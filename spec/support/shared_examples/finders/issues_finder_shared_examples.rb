# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'issues or work items finder' do |factory, execute_context|
  describe '#execute' do
    include_context execute_context, factory

    context 'scope: all' do
      let(:scope) { 'all' }

      it 'returns all items' do
        expect(items).to contain_exactly(item1, item2, item3, item4, item5)
      end

      context 'user does not have read permissions' do
        let(:search_user) { user2 }

        context 'when filtering by project id' do
          let(:params) { { project_id: project1.id } }

          it 'returns no items' do
            expect(items).to be_empty
          end
        end

        context 'when filtering by group id' do
          let(:params) { { group_id: subgroup.id } }

          it 'returns no items' do
            expect(items).to be_empty
          end
        end
      end

      context 'assignee filtering' do
        let(:issuables) { items }

        it_behaves_like 'assignee ID filter' do
          let(:params) { { assignee_id: user.id } }
          let(:expected_issuables) { [item1, item2, item5] }
        end

        it_behaves_like 'assignee NOT ID filter' do
          let(:params) { { not: { assignee_id: user.id } } }
          let(:expected_issuables) { [item3, item4] }
        end

        it_behaves_like 'assignee OR filter' do
          let(:params) { { or: { assignee_id: [user.id, user2.id] } } }
          let(:expected_issuables) { [item1, item2, item3, item5] }
        end

        context 'when assignee_id does not exist' do
          it_behaves_like 'assignee NOT ID filter' do
            let(:params) { { not: { assignee_id: -100 } } }
            let(:expected_issuables) { [item1, item2, item3, item4, item5] }
          end
        end

        context 'filter by username' do
          let_it_be(:user3) { create(:user) }

          before do
            project2.add_developer(user3)
            item2.assignees = [user2]
            item3.assignees = [user3]
          end

          it_behaves_like 'assignee username filter' do
            let(:params) { { assignee_username: [user2.username] } }
            let(:expected_issuables) { [item2] }
          end

          it_behaves_like 'assignee NOT username filter' do
            before do
              item2.assignees = [user2]
            end

            let(:params) { { not: { assignee_username: [user.username, user2.username] } } }
            let(:expected_issuables) { [item3, item4] }
          end

          it_behaves_like 'assignee OR filter' do
            let(:params) { { or: { assignee_username: [user2.username, user3.username] } } }
            let(:expected_issuables) { [item2, item3] }
          end

          context 'when assignee_username does not exist' do
            it_behaves_like 'assignee NOT username filter' do
              before do
                item2.assignees = [user2]
              end

              let(:params) { { not: { assignee_username: 'non_existent_username' } } }
              let(:expected_issuables) { [item1, item2, item3, item4, item5] }
            end
          end
        end

        it_behaves_like 'no assignee filter' do
          let_it_be(:user3) { create(:user) }
          let(:expected_issuables) { [item4] }
        end

        it_behaves_like 'any assignee filter' do
          let(:expected_issuables) { [item1, item2, item3, item5] }
        end
      end

      context 'filtering by release' do
        context 'when filter by none' do
          let(:params) { { release_tag: 'none' } }

          it 'returns items without releases' do
            expect(items).to contain_exactly(item2, item3, item4, item5)
          end

          context 'when sort by milestone' do
            let(:params) { { release_tag: 'none', sort: 'milestone_due_desc' } }

            it 'returns items without any releases' do
              expect(items).to contain_exactly(item2, item3, item4, item5)
            end
          end
        end

        context 'when filter by any' do
          let(:params) { { release_tag: 'any' } }

          it 'returns items with any releases' do
            expect(items).to contain_exactly(item1)
          end

          context 'when sort by milestone' do
            let(:params) { { release_tag: 'any', sort: 'milestone_due_desc' } }

            it 'returns items without any releases' do
              expect(items).to contain_exactly(item1)
            end
          end
        end

        context 'when filter by a release_tag' do
          let(:params) { { project_id: project1.id, release_tag: release.tag } }

          it 'returns the items associated with the release tag' do
            expect(items).to contain_exactly(item1)
          end

          context 'when sort by milestone' do
            let(:params) { { project_id: project1.id, release_tag: release.tag, sort: 'milestone_due_desc' } }

            it 'returns the items associated with the release tag' do
              expect(items).to contain_exactly(item1)
            end
          end
        end

        context 'when filter by a negated release_tag' do
          let_it_be(:another_release) { create(:release, project: project1, tag: 'v2.0.0') }
          let_it_be(:another_milestone) { create(:milestone, project: project1, releases: [another_release]) }
          let_it_be(:another_item) do
            create(
              factory,
              project: project1,
              milestone: another_milestone,
              title: 'another item'
            )
          end

          let(:params) { { not: { release_tag: release.tag, project_id: project1.id } } }

          it 'returns the items not associated with the release' do
            expect(items).to contain_exactly(another_item)
          end

          context 'when sort by milestone' do
            let(:params) { { not: { release_tag: release.tag, project_id: project1.id }, sort: 'milestone_due_desc' } }

            it 'returns the items not associated with the release' do
              expect(items).to contain_exactly(another_item)
            end
          end
        end
      end

      context 'filtering by projects' do
        context 'when projects are passed in a list of ids' do
          let(:params) { { projects: [project1.id] } }

          it 'returns the item belonging to the projects' do
            expect(items).to contain_exactly(item1, item5)
          end
        end

        context 'when projects are passed in a subquery' do
          let(:params) { { projects: Project.id_in(project1.id) } }

          it 'returns the item belonging to the projects' do
            expect(items).to contain_exactly(item1, item5)
          end
        end
      end

      context 'filtering by author' do
        context 'by author ID' do
          let(:params) { { author_id: user2.id } }

          it 'returns items created by that user' do
            expect(items).to contain_exactly(item3)
          end
        end

        context 'using OR' do
          let(:item6) { create(factory, project: project2) }
          let(:params) { { or: { author_username: [item3.author.username, item6.author.username] } } }

          it 'returns items created by any of the given users' do
            expect(items).to contain_exactly(item3, item6)
          end
        end

        context 'filtering by NOT author ID' do
          let(:params) { { not: { author_id: user2.id } } }

          it 'returns items not created by that user' do
            expect(items).to contain_exactly(item1, item2, item4, item5)
          end
        end

        context 'filtering by nonexistent author ID and issue term using CTE for search' do
          let(:params) do
            {
              author_id: 'does-not-exist',
              search: 'git',
              attempt_group_search_optimizations: true
            }
          end

          it 'returns no results' do
            expect(items).to be_empty
          end
        end
      end

      # Querying Service Desk issues uses `support-bot` `author_username`.
      # This is a workaround that selects both legacy Service Desk issues and ticket work items
      # until we migrated Service Desk issues to work items of type ticket.
      # Will be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/505024
      context 'when filtering by Service Desk issues/tickets' do
        # Use items only for this context because it's temporary. This way we don't need to modify other examples.
        let_it_be_with_reload(:service_desk_issue) do
          create(
            :issue, # legacy Service Desk issues are always of type issue
            author: Users::Internal.support_bot,
            external_author: 'user@example.com',
            project: project2,
            description: 'Service Desk issue'
          )
        end

        let_it_be_with_reload(:ticket) do
          create(
            :work_item,
            :ticket,
            author: user2, # don't use support bot because this isn't a req for ticket WIT
            project: project2,
            description: 'Ticket'
          )
        end

        let(:params) { { author_username: 'support-bot' } }

        it 'returns Service Desk issues and work items of type ticket' do
          # Use the ids here because work item finder and issue finder return different types of objects.
          expect(items.map(&:id)).to contain_exactly(service_desk_issue.id, ticket.id)
        end
      end

      context 'filtering by milestone' do
        let(:params) { { milestone_title: milestone.title } }

        it 'returns items assigned to that milestone' do
          expect(items).to contain_exactly(item1)
        end
      end

      context 'filtering by not milestone' do
        let(:params) { { not: { milestone_title: milestone.title } } }

        it 'returns items not assigned to that milestone' do
          expect(items).to contain_exactly(item2, item3, item4, item5)
        end

        context 'with multiple milestones' do
          let(:milestone2) { create(:milestone, project: project2) }
          let(:params) { { not: { milestone_title: [milestone.title, milestone2.title] } } }

          it 'returns items not assigned to both milestones' do
            item2.update!(milestone: milestone2)

            expect(items).to contain_exactly(item3, item4, item5)
          end
        end
      end

      context 'filtering by group milestone' do
        let!(:group) { create(:group, :public) }
        let(:group_milestone) { create(:milestone, group: group) }
        let!(:group_member) { create(:group_member, group: group, user: user) }
        let(:params) { { milestone_title: group_milestone.title } }

        before do
          project2.update!(namespace: group)
          item2.update!(milestone: group_milestone)
          item3.update!(milestone: group_milestone)
        end

        it 'returns items assigned to that group milestone' do
          expect(items).to contain_exactly(item2, item3)
        end

        context 'using NOT' do
          let(:params) { { not: { milestone_title: group_milestone.title } } }

          it 'returns items not assigned to that group milestone' do
            expect(items).to contain_exactly(item1, item4, item5)
          end
        end
      end

      context 'filtering by no milestone' do
        let(:params) { { milestone_title: 'None' } }

        it 'returns items with no milestone' do
          expect(items).to contain_exactly(item2, item3, item4, item5)
        end

        it 'returns items with no milestone (deprecated)' do
          params[:milestone_title] = Milestone::None.title

          expect(items).to contain_exactly(item2, item3, item4, item5)
        end
      end

      context 'filtering by any milestone' do
        let(:params) { { milestone_title: 'Any' } }

        it 'returns items with any assigned milestone' do
          expect(items).to contain_exactly(item1)
        end

        it 'returns items with any assigned milestone (deprecated)' do
          params[:milestone_title] = Milestone::Any.title

          expect(items).to contain_exactly(item1)
        end
      end

      context 'filtering by upcoming milestone' do
        let(:params) { { milestone_title: Milestone::Upcoming.name } }

        let!(:group) { create(:group, :public) }
        let!(:group_member) { create(:group_member, group: group, user: user) }

        let(:project_no_upcoming_milestones) { create(:project, :public) }
        let(:project_next_1_1) { create(:project, :public) }
        let(:project_next_8_8) { create(:project, :public) }
        let(:project_in_group) { create(:project, :public, namespace: group) }

        let(:yesterday) { Date.current - 1.day }
        let(:tomorrow) { Date.current + 1.day }
        let(:two_days_from_now) { Date.current + 2.days }
        let(:ten_days_from_now) { Date.current + 10.days }

        let(:milestones) do
          [
            create(:milestone, :closed, project: project_no_upcoming_milestones),
            create(:milestone, project: project_next_1_1, title: '1.1', due_date: two_days_from_now),
            create(:milestone, project: project_next_1_1, title: '8.9', due_date: ten_days_from_now),
            create(:milestone, project: project_next_8_8, title: '1.2', due_date: yesterday),
            create(:milestone, project: project_next_8_8, title: '8.8', due_date: tomorrow),
            create(:milestone, group: group, title: '9.9', due_date: tomorrow)
          ]
        end

        let!(:created_items) do
          milestones.map do |milestone|
            create(
              factory,
              project: milestone.project || project_in_group,
              milestone: milestone, author: user, assignees: [user]
            )
          end
        end

        it 'returns items in the upcoming milestone for each project or group' do
          expect(items.map { |item| item.milestone.title })
            .to contain_exactly('1.1', '8.8', '9.9')
          expect(items.map { |item| item.milestone.due_date })
            .to contain_exactly(tomorrow, two_days_from_now, tomorrow)
        end

        context 'using NOT' do
          let(:params) { { not: { milestone_title: Milestone::Upcoming.name } } }

          it 'returns items not in upcoming milestones for each project or group, but must have a due date' do
            target_items = created_items.select do |item|
              item.milestone&.due_date && item.milestone.due_date <= Date.current
            end

            expect(items).to contain_exactly(*target_items)
          end
        end
      end

      context 'filtering by started milestone' do
        let(:params) { { milestone_title: Milestone::Started.name } }

        let(:project_no_started_milestones) { create(:project, :public) }
        let(:project_started_1_and_2) { create(:project, :public) }
        let(:project_started_8) { create(:project, :public) }

        let(:yesterday) { Date.current - 1.day }
        let(:tomorrow) { Date.current + 1.day }
        let(:two_days_ago) { Date.current - 2.days }
        let(:three_days_ago) { Date.current - 3.days }

        let(:milestones) do
          [
            create(:milestone, project: project_no_started_milestones, start_date: tomorrow),
            create(:milestone, project: project_started_1_and_2, title: '1.0', start_date: two_days_ago),
            create(:milestone, project: project_started_1_and_2, title: '2.0', start_date: yesterday),
            create(:milestone, project: project_started_1_and_2, title: '3.0', start_date: tomorrow),
            create(:milestone, :closed, project: project_started_1_and_2, title: '4.0', start_date: three_days_ago),
            create(:milestone, :closed, project: project_started_8, title: '6.0', start_date: three_days_ago),
            create(:milestone, project: project_started_8, title: '7.0'),
            create(:milestone, project: project_started_8, title: '8.0', start_date: yesterday),
            create(:milestone, project: project_started_8, title: '9.0', start_date: tomorrow)
          ]
        end

        before do
          milestones.each do |milestone|
            create(factory, project: milestone.project, milestone: milestone, author: user, assignees: [user])
          end
        end

        it 'returns items in the started milestones for each project' do
          expect(items.map { |item| item.milestone.title })
            .to contain_exactly('1.0', '2.0', '8.0')
          expect(items.map { |item| item.milestone.start_date })
            .to contain_exactly(two_days_ago, yesterday, yesterday)
        end

        context 'using NOT' do
          let(:params) { { not: { milestone_title: Milestone::Started.name } } }

          it 'returns items not in the started milestones for each project' do
            target_items = items_model.where(milestone: Milestone.not_started)

            expect(items).to contain_exactly(*target_items)
          end
        end
      end

      context 'filtering by label' do
        let(:params) { { label_name: label.title } }

        it 'returns items with that label' do
          expect(items).to contain_exactly(item2)
        end

        context 'using NOT' do
          let(:params) { { not: { label_name: label.title } } }

          it 'returns items that do not have that label' do
            expect(items).to contain_exactly(item1, item3, item4, item5)
          end

          # IssuableFinder first filters using the outer params (the ones not inside the `not` key.)
          # Afterwards, it applies the `not` params to that resultset. This means that things inside the `not` param
          # do not take precedence over the outer params with the same name.
          context 'shadowing the same outside param' do
            let(:params) { { label_name: label2.title, not: { label_name: label.title } } }

            it 'does not take precedence over labels outside NOT' do
              expect(items).to contain_exactly(item3)
            end
          end

          context 'further filtering outside params' do
            let(:params) { { label_name: label2.title, not: { assignee_username: user2.username } } }

            it 'further filters on the returned resultset' do
              expect(items).to be_empty
            end
          end
        end
      end

      context 'filtering by multiple labels' do
        let(:params) { { label_name: [label.title, label2.title].join(',') } }
        let(:label2) { create(:label, project: project2) }

        before do
          create(:label_link, label: label2, target: item2)
        end

        it 'returns the unique items with all those labels' do
          expect(items).to contain_exactly(item2)
        end

        context 'using NOT' do
          let(:params) { { not: { label_name: [label.title, label2.title].join(',') } } }

          it 'returns items that do not have any of the labels provided' do
            expect(items).to contain_exactly(item1, item4, item5)
          end
        end

        context 'using OR' do
          let(:params) { { or: { label_name: [label.title, label2.title].join(',') } } }

          it 'returns items that have at least one of the given labels' do
            expect(items).to contain_exactly(item2, item3)
          end
        end
      end

      context 'filtering by a label that includes any or none in the title' do
        let(:params) { { label_name: [label.title, label2.title].join(',') } }
        let(:label) { create(:label, title: 'any foo', project: project2) }
        let(:label2) { create(:label, title: 'bar none', project: project2) }

        before do
          create(:label_link, label: label2, target: item2)
        end

        it 'returns the unique items with all those labels' do
          expect(items).to contain_exactly(item2)
        end

        context 'using NOT' do
          let(:params) { { not: { label_name: [label.title, label2.title].join(',') } } }

          it 'returns items that do not have ANY ONE of the labels provided' do
            expect(items).to contain_exactly(item1, item4, item5)
          end
        end
      end

      context 'filtering by no label' do
        let(:params) { { label_name: IssuableFinder::Params::FILTER_NONE } }

        it 'returns items with no labels' do
          expect(items).to contain_exactly(item1, item4, item5)
        end
      end

      context 'filtering by any label' do
        let(:params) { { label_name: IssuableFinder::Params::FILTER_ANY } }

        it 'returns items that have one or more label' do
          create_list(:label_link, 2, label: create(:label, project: project2), target: item3)

          expect(items).to contain_exactly(item2, item3)
        end
      end

      context 'when the same label exists on project and group levels' do
        let(:item1) { create(factory, project: project1) }
        let(:item2) { create(factory, project: project1) }

        # Skipping validation to reproduce a "real-word" scenario.
        # We still have legacy labels on PRD that have the same title on the group and project levels, example: `bug`
        let(:project_label) do
          build(:label, title: 'somelabel', project: project1).tap { |r| r.save!(validate: false) }
        end

        let(:group_label) { create(:group_label, title: 'somelabel', group: project1.group) }

        let(:params) { { label_name: 'somelabel' } }

        before do
          create(:label_link, label: group_label, target: item1)
          create(:label_link, label: project_label, target: item2)
        end

        it 'finds both item records' do
          expect(items).to contain_exactly(item1, item2)
        end
      end

      context 'filtering by item term' do
        let(:params) { { search: search_term } }

        let_it_be(:english) { create(factory, project: project1, title: 'title', description: 'something english') }

        let_it_be(:japanese) do
          create(factory, project: project1, title: '日本語 title', description: 'another english description')
        end

        context 'with latin search term' do
          let(:search_term) { 'title english' }

          it 'returns matching items' do
            expect(items).to contain_exactly(english, japanese)
          end
        end

        context 'with non-latin search term' do
          let(:search_term) { '日本語' }

          it 'returns matching items' do
            expect(items).to contain_exactly(japanese)
          end
        end
      end

      context 'filtering by item term in title' do
        let(:params) { { search: 'git', in: 'title' } }

        it 'returns items with title match for search term' do
          expect(items).to contain_exactly(item1)
        end
      end

      context 'filtering by items iids' do
        let(:params) { { iids: [item3.iid] } }

        it 'returns items where iids match' do
          expect(items).to contain_exactly(item3, item5)
        end

        context 'using NOT' do
          let(:params) { { not: { iids: [item3.iid] } } }

          it 'returns items with no iids match' do
            expect(items).to contain_exactly(item1, item2, item4)
          end
        end
      end

      context 'filtering by state' do
        context 'with opened' do
          let(:params) { { state: 'opened' } }

          it 'returns only opened items' do
            expect(items).to contain_exactly(item1, item2, item3, item4, item5)
          end
        end

        context 'with closed' do
          let(:params) { { state: 'closed' } }

          it 'returns only closed items' do
            expect(items).to contain_exactly(closed_item)
          end
        end

        context 'with all' do
          let(:params) { { state: 'all' } }

          it 'returns all items' do
            expect(items).to contain_exactly(item1, item2, item3, closed_item, item4, item5)
          end
        end

        context 'with invalid state' do
          let(:params) { { state: 'invalid_state' } }

          it 'returns all items' do
            expect(items).to contain_exactly(item1, item2, item3, closed_item, item4, item5)
          end
        end
      end

      context 'filtering by created_at' do
        context 'through created_after' do
          let(:params) { { created_after: item3.created_at } }

          it 'returns items created on or after the given date' do
            expect(items).to contain_exactly(item3)
          end
        end

        context 'through created_before' do
          let(:params) { { created_before: item1.created_at } }

          it 'returns items created on or before the given date' do
            expect(items).to contain_exactly(item1)
          end
        end

        context 'through created_after and created_before' do
          let(:params) { { created_after: item2.created_at, created_before: item3.created_at } }

          it 'returns items created between the given dates' do
            expect(items).to contain_exactly(item2, item3)
          end
        end
      end

      context 'filtering by updated_at' do
        context 'through updated_after' do
          let(:params) { { updated_after: item3.updated_at } }

          it 'returns items updated on or after the given date' do
            expect(items).to contain_exactly(item3)
          end
        end

        context 'through updated_before' do
          let(:params) { { updated_before: item1.updated_at } }

          it 'returns items updated on or before the given date' do
            expect(items).to contain_exactly(item1)
          end
        end

        context 'through updated_after and updated_before' do
          let(:params) { { updated_after: item2.updated_at, updated_before: item3.updated_at } }

          it 'returns items updated between the given dates' do
            expect(items).to contain_exactly(item2, item3)
          end
        end
      end

      context 'filtering by closed_at' do
        let!(:closed_item1) { create(factory, project: project1, state: :closed, closed_at: 1.week.ago) }
        let!(:closed_item2) { create(factory, project: project2, state: :closed, closed_at: 1.week.from_now) }
        let!(:closed_item3) { create(factory, project: project2, state: :closed, closed_at: 2.weeks.from_now) }

        context 'through closed_after' do
          let(:params) { { state: :closed, closed_after: closed_item3.closed_at } }

          it 'returns items closed on or after the given date' do
            expect(items).to contain_exactly(closed_item3)
          end
        end

        context 'through closed_before' do
          let(:params) { { state: :closed, closed_before: closed_item1.closed_at } }

          it 'returns items closed on or before the given date' do
            expect(items).to contain_exactly(closed_item1)
          end
        end

        context 'through closed_after and closed_before' do
          let(:params) do
            { state: :closed, closed_after: closed_item2.closed_at, closed_before: closed_item3.closed_at }
          end

          it 'returns items closed between the given dates' do
            expect(items).to contain_exactly(closed_item2, closed_item3)
          end
        end
      end

      context 'filtering by reaction name' do
        context 'user searches by no reaction' do
          let(:params) { { my_reaction_emoji: 'None' } }

          it 'returns items that the user did not react to' do
            expect(items).to contain_exactly(item2, item4, item5)
          end
        end

        context 'user searches by any reaction' do
          let(:params) { { my_reaction_emoji: 'Any' } }

          it 'returns items that the user reacted to' do
            expect(items).to contain_exactly(item1, item3)
          end
        end

        context 'user searches by "thumbsup" reaction' do
          let(:params) { { my_reaction_emoji: AwardEmoji::THUMBS_UP } }

          it 'returns items that the user thumbsup to' do
            expect(items).to contain_exactly(item1)
          end

          context 'using NOT' do
            let(:params) { { not: { my_reaction_emoji: AwardEmoji::THUMBS_UP } } }

            it 'returns items that the user did not thumbsup to' do
              expect(items).to contain_exactly(item2, item3, item4, item5)
            end
          end
        end

        context 'user2 searches by "thumbsup" reaction' do
          let(:search_user) { user2 }

          let(:params) { { my_reaction_emoji: AwardEmoji::THUMBS_UP } }

          it 'returns items that the user2 thumbsup to' do
            expect(items).to contain_exactly(item2)
          end

          context 'using NOT' do
            let(:params) { { not: { my_reaction_emoji: AwardEmoji::THUMBS_UP } } }

            it 'returns items that the user2 thumbsup to' do
              expect(items).to contain_exactly(item3)
            end
          end
        end

        context 'user searches by "thumbsdown" reaction' do
          let(:params) { { my_reaction_emoji: AwardEmoji::THUMBS_DOWN } }

          it 'returns items that the user thumbsdown to' do
            expect(items).to contain_exactly(item3)
          end

          context 'using NOT' do
            let(:params) { { not: { my_reaction_emoji: AwardEmoji::THUMBS_DOWN } } }

            it 'returns items that the user thumbsdown to' do
              expect(items).to contain_exactly(item1, item2, item4, item5)
            end
          end
        end
      end

      context 'filtering by confidential' do
        let_it_be(:confidential_item) { create(factory, project: project1, confidential: true) }

        context 'no filtering' do
          it 'returns all items' do
            expect(items).to contain_exactly(item1, item2, item3, item4, item5, confidential_item)
          end
        end

        context 'user filters confidential items' do
          let(:params) { { confidential: true } }

          it 'returns only confidential items' do
            expect(items).to contain_exactly(confidential_item)
          end
        end

        context 'user filters only public items' do
          let(:params) { { confidential: false } }

          it 'returns only public items' do
            expect(items).to contain_exactly(item1, item2, item3, item4, item5)
          end
        end
      end

      context 'filtering by subscribed' do
        let_it_be(:subscribed_item) { create(factory, project: project1) }
        let_it_be(:unsubscribed_item) { create(factory, project: project1) }
        let_it_be(:regular_item) { create(factory, project: project1) }
        let_it_be(:subscription) { create(:subscription, subscribable: subscribed_item, user: user, subscribed: true) }
        let_it_be(:unsubscription) do
          create(:subscription, subscribable: unsubscribed_item, user: user, subscribed: false)
        end

        context 'no filtering' do
          it 'returns all items' do
            expect(items)
              .to contain_exactly(item1, item2, item3, item4, item5, subscribed_item, unsubscribed_item, regular_item)
          end
        end

        context 'user filters for subscribed items' do
          let(:params) { { subscribed: :explicitly_subscribed } }

          it 'returns only subscribed items' do
            expect(items).to contain_exactly(subscribed_item)
          end
        end

        context 'user filters out subscribed items' do
          let(:params) { { subscribed: :explicitly_unsubscribed } }

          it 'returns only unsubscribed items' do
            expect(items).to contain_exactly(unsubscribed_item)
          end
        end
      end

      context 'filtering by item type' do
        let_it_be(:incident_item) { create(factory, :incident, project: project1) }
        let_it_be(:objective) { create(factory, :objective, project: project1) }
        let_it_be(:key_result) { create(factory, :key_result, project: project1) }

        context 'no type given' do
          let(:params) { { issue_types: [] } }

          it 'returns all items' do
            expect(items)
              .to contain_exactly(incident_item, item1, item2, item3, item4, item5, objective, key_result)
          end
        end

        context 'incident type' do
          let(:params) { { issue_types: ['incident'] } }

          it 'returns incident items' do
            expect(items).to contain_exactly(incident_item)
          end
        end

        context 'objective type' do
          let(:params) { { issue_types: ['objective'] } }

          it 'returns incident items' do
            expect(items).to contain_exactly(objective)
          end
        end

        context 'key_result type' do
          let(:params) { { issue_types: ['key_result'] } }

          it 'returns incident items' do
            expect(items).to contain_exactly(key_result)
          end
        end

        context 'item type' do
          let(:params) { { issue_types: ['issue'] } }

          it 'returns all items with type issue' do
            expect(items).to contain_exactly(item1, item2, item3, item4, item5)
          end
        end

        context 'multiple params' do
          let(:params) { { issue_types: %w[issue incident] } }

          it 'returns all items' do
            expect(items).to contain_exactly(incident_item, item1, item2, item3, item4, item5)
          end
        end

        context 'without array' do
          let(:params) { { issue_types: 'incident' } }

          it 'returns incident items' do
            expect(items).to contain_exactly(incident_item)
          end
        end

        context 'invalid params' do
          let(:params) { { issue_types: ['nonsense'] } }

          it 'returns no items' do
            expect(items.none?).to eq(true)
          end
        end
      end

      context 'crm filtering' do
        let_it_be(:root_group) { create(:group) }
        let_it_be(:group) { create(:group, parent: root_group) }
        let_it_be(:project_crm) { create(:project, :public, group: group) }
        let_it_be(:crm_organization) { create(:crm_organization, group: root_group) }
        let_it_be(:contact1) { create(:contact, group: root_group, organization: crm_organization) }
        let_it_be(:contact2) { create(:contact, group: root_group, organization: crm_organization) }

        let_it_be(:contact1_item1) { create(factory, project: project_crm) }
        let_it_be(:contact1_item2) { create(factory, project: project_crm) }
        let_it_be(:contact2_item1) { create(factory, project: project_crm) }
        let_it_be(:item_no_contact) { create(factory, project: project_crm) }

        let_it_be(:all_project_issues) do
          [contact1_item1, contact1_item2, contact2_item1, item_no_contact]
        end

        before do
          create(:crm_settings, group: root_group, enabled: true)

          create(:issue_customer_relations_contact, issue: contact1_item1, contact: contact1)
          create(:issue_customer_relations_contact, issue: contact1_item2, contact: contact1)
          create(:issue_customer_relations_contact, issue: contact2_item1, contact: contact2)
        end

        context 'filtering by crm contact' do
          let(:params) { { project_id: project_crm.id, crm_contact_id: contact1.id } }

          context 'when the user can read crm contacts' do
            it 'returns for that contact' do
              root_group.add_reporter(user)

              expect(items).to contain_exactly(contact1_item1, contact1_item2)
            end
          end

          context 'when the user can not read crm contacts' do
            it 'does not filter by contact' do
              expect(items).to match_array(all_project_issues)
            end
          end
        end

        context 'filtering by crm organization' do
          let(:params) { { project_id: project_crm.id, crm_organization_id: crm_organization.id } }

          context 'when the user can read crm organization' do
            it 'returns for that crm organization' do
              root_group.add_reporter(user)

              expect(items).to contain_exactly(contact1_item1, contact1_item2, contact2_item1)
            end
          end

          context 'when the user can not read crm organization' do
            it 'does not filter by crm organization' do
              expect(items).to match_array(all_project_issues)
            end
          end
        end
      end

      context 'when the user is unauthorized' do
        let(:search_user) { nil }

        it 'returns no results' do
          expect(items).to be_empty
        end
      end

      context 'when the user can see some, but not all, items' do
        let(:search_user) { user2 }

        it 'returns only items they can see' do
          expect(items).to contain_exactly(item2, item3)
        end
      end

      it 'finds items user can access due to group' do
        group = create(:group)
        project = create(:project, group: group)
        item = create(factory, project: project)
        group.add_member(user, :owner)

        expect(items).to include(item)
      end
    end

    context 'personal scope' do
      let(:scope) { 'assigned_to_me' }

      it 'returns item assigned to the user' do
        expect(items).to contain_exactly(item1, item2, item5)
      end

      context 'filtering by project' do
        let(:params) { { project_id: project1.id } }

        it 'returns items assigned to the user in that project' do
          expect(items).to contain_exactly(item1, item5)
        end
      end
    end

    context 'when project restricts items' do
      let(:scope) { nil }

      it "doesn't return team-only items to non team members" do
        project = create(:project, :public, :issues_private)
        item = create(factory, project: project)

        expect(items).not_to include(item)
      end

      it "doesn't return items if feature disabled" do
        [project1, project2, project3].each do |project|
          project.project_feature.update!(issues_access_level: ProjectFeature::DISABLED)
        end

        expect(items.count).to eq 0
      end
    end

    context 'external authorization' do
      it_behaves_like 'a finder with external authorization service' do
        let!(:subject) { create(factory, project: project) }
        let(:project_params) { { project_id: project.id } }
      end
    end

    context 'filtering by due date' do
      let_it_be(:item_due_today) { create(factory, project: project1, due_date: Date.current) }
      let_it_be(:item_due_tomorrow) { create(factory, project: project1, due_date: 1.day.from_now) }
      let_it_be(:item_overdue) { create(factory, project: project1, due_date: 2.days.ago) }
      let_it_be(:item_due_soon) { create(factory, project: project1, due_date: 2.days.from_now) }

      let(:scope) { 'all' }
      let(:base_params) { { project_id: project1.id } }

      context 'with param set to no due date' do
        let(:params) { base_params.merge(due_date: items_model::NoDueDate.name) }

        it 'returns items with no due date' do
          expect(items).to contain_exactly(item1, item5)
        end
      end

      context 'with param set to any due date' do
        let(:params) { base_params.merge(due_date: items_model::AnyDueDate.name) }

        it 'returns items with any due date' do
          expect(items).to contain_exactly(item_due_today, item_due_tomorrow, item_overdue, item_due_soon)
        end
      end

      context 'with param set to due today' do
        let(:params) { base_params.merge(due_date: items_model::DueToday.name) }

        it 'returns items due today' do
          expect(items).to contain_exactly(item_due_today)
        end
      end

      context 'with param set to due tomorrow' do
        let(:params) { base_params.merge(due_date: items_model::DueTomorrow.name) }

        it 'returns items due today' do
          expect(items).to contain_exactly(item_due_tomorrow)
        end
      end

      context 'with param set to overdue' do
        let(:params) { base_params.merge(due_date: items_model::Overdue.name) }

        it 'returns overdue items' do
          expect(items).to contain_exactly(item_overdue)
        end
      end

      context 'with param set to next month and previous two weeks' do
        let(:params) { base_params.merge(due_date: items_model::DueNextMonthAndPreviousTwoWeeks.name) }

        it 'returns items due in the previous two weeks and next month' do
          expect(items).to contain_exactly(item_due_today, item_due_tomorrow, item_overdue, item_due_soon)
        end
      end

      context 'with invalid param' do
        let(:params) { base_params.merge(due_date: 'foo') }

        it 'returns no items' do
          expect(items).to be_empty
        end
      end
    end
  end

  describe '#row_count', :request_store do
    let_it_be(:admin) { create(:admin) }

    context 'when admin mode is enabled', :enable_admin_mode do
      it 'returns the number of rows for the default state' do
        finder = described_class.new(admin)

        expect(finder.row_count).to eq(5)
      end

      it 'returns the number of rows for a given state' do
        finder = described_class.new(admin, state: 'closed')

        expect(finder.row_count).to be_zero
      end
    end

    context 'when admin mode is disabled' do
      it 'returns no rows' do
        finder = described_class.new(admin)

        expect(finder.row_count).to be_zero
      end
    end

    it 'returns -1 if the query times out' do
      finder = described_class.new(admin)

      expect_next_instance_of(described_class) do |subfinder|
        expect(subfinder).to receive(:execute).and_raise(ActiveRecord::QueryCanceled)
      end

      expect(finder.row_count).to eq(-1)
    end
  end

  describe 'confidentiality access check' do
    let(:guest) { create(:user) }

    let_it_be(:authorized_user) { create(:user) }
    let_it_be(:banned_user) { create(:user, :banned) }
    let_it_be(:project) { create(:project, :public, namespace: authorized_user.namespace) }
    let_it_be(:public_item) { create(factory, project: project) }
    let_it_be(:confidential_item) { create(factory, project: project, confidential: true) }
    let_it_be(:hidden_item) { create(factory, project: project, author: banned_user) }

    shared_examples 'returns public, does not return hidden or confidential' do
      it 'returns only public items' do
        expect(subject).to include(public_item)
        expect(subject).not_to include(confidential_item, hidden_item)
      end
    end

    shared_examples 'returns public and confidential, does not return hidden' do
      it 'returns only public and confidential items' do
        expect(subject).to include(public_item, confidential_item)
        expect(subject).not_to include(hidden_item)
      end
    end

    shared_examples 'returns public and hidden, does not return confidential' do
      it 'returns only public and hidden items' do
        expect(subject).to include(public_item, hidden_item)
        expect(subject).not_to include(confidential_item)
      end
    end

    shared_examples 'returns public, confidential, and hidden' do
      it 'returns all items' do
        expect(subject).to include(public_item, confidential_item, hidden_item)
      end
    end

    context 'when no project filter is given' do
      let(:params) { {} }

      context 'for a user without project membership' do
        subject { described_class.new(user, params).execute }

        it_behaves_like 'returns public, does not return hidden or confidential'
      end

      context 'for a guest user' do
        subject { described_class.new(guest, params).execute }

        before do
          project.add_guest(guest)
        end

        it_behaves_like 'returns public, does not return hidden or confidential'
      end

      context 'for a project member with access to view confidential items' do
        subject { described_class.new(authorized_user, params).execute }

        it_behaves_like 'returns public and confidential, does not return hidden'
      end

      context 'for an admin' do
        let(:admin_user) { create(:user, :admin) }

        subject { described_class.new(admin_user, params).execute }

        context 'when admin mode is enabled', :enable_admin_mode do
          it_behaves_like 'returns public, confidential, and hidden'
        end

        context 'when admin mode is disabled' do
          it_behaves_like 'returns public, does not return hidden or confidential'
        end
      end
    end

    context 'when searching within a specific project' do
      let(:params) { { project_id: project.id } }

      context 'for an anonymous user' do
        subject { described_class.new(nil, params).execute }

        it_behaves_like 'returns public, does not return hidden or confidential'

        it 'does not filter by confidentiality' do
          expect(items_model).not_to receive(:where).with(a_string_matching('confidential'), anything)
          subject
        end
      end

      context 'for a user without project membership' do
        subject { described_class.new(user, params).execute }

        it_behaves_like 'returns public, does not return hidden or confidential'

        it 'filters by confidentiality' do
          expect(subject.to_sql).to match('"issues"."confidential"')
        end
      end

      context 'for a guest user' do
        subject { described_class.new(guest, params).execute }

        before do
          project.add_guest(guest)
        end

        it_behaves_like 'returns public, does not return hidden or confidential'

        it 'filters by confidentiality' do
          expect(subject.to_sql).to match('"issues"."confidential"')
        end
      end

      context 'for a project member with access to view confidential items' do
        subject { described_class.new(authorized_user, params).execute }

        it_behaves_like 'returns public and confidential, does not return hidden'

        it 'does not filter by confidentiality' do
          expect(items_model).not_to receive(:where).with(a_string_matching('confidential'), anything)

          subject
        end
      end

      context 'for an admin' do
        let(:admin_user) { create(:user, :admin) }

        subject { described_class.new(admin_user, params).execute }

        context 'when admin mode is enabled', :enable_admin_mode do
          it_behaves_like 'returns public, confidential, and hidden'

          it 'does not filter by confidentiality' do
            expect(items_model).not_to receive(:where).with(a_string_matching('confidential'), anything)

            subject
          end
        end

        context 'when admin mode is disabled' do
          it_behaves_like 'returns public, does not return hidden or confidential'

          it 'filters by confidentiality' do
            expect(subject.to_sql).to match('"issues"."confidential"')
          end
        end
      end

      context 'when filtering items assigned to the current user' do
        let_it_be(:assigned_user) { create(:user) }
        let_it_be(:assigned_public_item) { create(factory, project: project, assignees: [assigned_user]) }
        let_it_be(:assigned_confidential_item) do
          create(factory, project: project, confidential: true, assignees: [assigned_user])
        end

        let(:params) { { assignee_id: assigned_user.id } }

        subject { described_class.new(assigned_user, params).execute }

        it 'returns items assigned to the user' do
          expect(subject).to contain_exactly(assigned_public_item, assigned_confidential_item)
        end

        it 'does not filter by confidentiality' do
          expect(items_model).not_to receive(:where).with(a_string_matching('confidential'), anything)

          subject
        end
      end
    end

    context 'when both assignee_id and assignee_username are provided' do
      let(:params) { { assignee_id: 'NONE', assignee_username: user.username } }

      subject { described_class.new(user, params).execute }

      it_behaves_like 'returns public, does not return hidden or confidential'
    end
  end

  describe '#use_cte_for_search?' do
    let(:finder) { described_class.new(nil, params) }

    context 'when there is no search param' do
      let(:params) { { attempt_group_search_optimizations: true } }

      it 'returns false' do
        expect(finder.use_cte_for_search?).to be_falsey
      end
    end

    context 'when the force_cte param is falsey' do
      let(:params) { { search: '日本語' } }

      it 'returns false' do
        expect(finder.use_cte_for_search?).to be_falsey
      end
    end

    context 'when a non-simple sort is given' do
      let(:params) { { search: '日本語', attempt_project_search_optimizations: true, sort: 'popularity' } }

      it 'returns false' do
        expect(finder.use_cte_for_search?).to be_falsey
      end
    end

    context 'when all conditions are met' do
      context "uses group search optimization" do
        let(:params) { { search: '日本語', attempt_group_search_optimizations: true } }

        it 'returns true' do
          expect(finder.use_cte_for_search?).to be_truthy
          expect(finder.execute.to_sql)
            .to match(/^WITH "issues" AS MATERIALIZED/)
        end
      end

      context "uses project search optimization" do
        let(:params) { { search: '日本語', attempt_project_search_optimizations: true } }

        it 'returns true' do
          expect(finder.use_cte_for_search?).to be_truthy
          expect(finder.execute.to_sql)
            .to match(/^WITH "issues" AS MATERIALIZED/)
        end
      end

      context 'with simple sort' do
        let(:params) { { search: '日本語', attempt_project_search_optimizations: true, sort: 'updated_desc' } }

        it 'returns true' do
          expect(finder.use_cte_for_search?).to be_truthy
          expect(finder.execute.to_sql)
            .to match(/^WITH "issues" AS MATERIALIZED/)
        end
      end

      context 'with simple sort as a symbol' do
        let(:params) { { search: '日本語', attempt_project_search_optimizations: true, sort: :updated_desc } }

        it 'returns true' do
          expect(finder.use_cte_for_search?).to be_truthy
          expect(finder.execute.to_sql)
            .to match(/^WITH "issues" AS MATERIALIZED/)
        end
      end
    end
  end

  describe '#parent_param=' do
    using RSpec::Parameterized::TableSyntax

    let(:finder) { described_class.new(nil) }

    subject { finder.parent_param = obj }

    where(:klass, :param) do
      :Project | :project_id
      :Group   | :group_id
    end

    with_them do
      let(:obj) { Object.const_get(klass, false).new }

      it 'sets the params' do
        subject

        expect(finder.params[param]).to eq(obj)
      end
    end

    context 'unexpected parent' do
      let(:obj) { MergeRequest.new }

      it 'raises an error' do
        expect { subject }.to raise_error('Unexpected parent: MergeRequest')
      end
    end
  end
end
