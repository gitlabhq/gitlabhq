# frozen_string_literal: true

RSpec.shared_context 'WorkItemsFinder context' do
  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project1, reload: true) { create(:project, group: group) }
  let_it_be(:project2, reload: true) { create(:project) }
  let_it_be(:project3, reload: true) { create(:project, group: subgroup) }
  let_it_be(:release) { create(:release, project: project1, tag: 'v1.0.0') }
  let_it_be(:milestone) { create(:milestone, project: project1, releases: [release]) }
  let_it_be(:label) { create(:label, project: project2) }
  let_it_be(:label2) { create(:label, project: project2) }
  let_it_be_with_reload(:item1) do
    create(
      :work_item,
      author: user,
      assignees: [user],
      project: project1,
      milestone: milestone,
      title: 'gitlab',
      created_at: 1.week.ago,
      updated_at: 1.week.ago
    )
  end

  let_it_be_with_reload(:item2) do
    create(
      :work_item,
      author: user,
      assignees: [user],
      project: project2,
      description: 'gitlab',
      created_at: 1.week.from_now,
      updated_at: 1.week.from_now
    )
  end

  let_it_be_with_reload(:item3) do
    create(
      :work_item,
      author: user2,
      assignees: [user2],
      project: project2,
      title: 'tanuki',
      description: 'tanuki',
      created_at: 2.weeks.from_now,
      updated_at: 2.weeks.from_now
    )
  end

  let_it_be_with_reload(:item4) { create(:work_item, project: project3) }
  let_it_be_with_reload(:item5) do
    create(
      :work_item,
      author: user,
      assignees: [user],
      project: project1,
      title: 'wotnot',
      created_at: 3.days.ago,
      updated_at: 3.days.ago
    )
  end

  let_it_be(:group_level_item) do
    create(
      :work_item,
      namespace: group,
      author: user
    )
  end

  let_it_be(:group_level_confidential_item) do
    create(
      :work_item,
      :confidential,
      namespace: group,
      author: user2
    )
  end

  let_it_be(:award_emoji1) { create(:award_emoji, name: AwardEmoji::THUMBS_UP, user: user, awardable: item1) }
  let_it_be(:award_emoji2) { create(:award_emoji, name: AwardEmoji::THUMBS_UP, user: user2, awardable: item2) }
  let_it_be(:award_emoji3) { create(:award_emoji, name: AwardEmoji::THUMBS_DOWN, user: user, awardable: item3) }

  let(:items_model) { WorkItem }
end

RSpec.shared_context 'WorkItemsFinder#execute context' do
  let!(:closed_item) { create(:work_item, author: user2, assignees: [user2], project: project2, state: 'closed') }
  let!(:label_link) { create(:label_link, label: label, target: item2) }
  let!(:label_link2) { create(:label_link, label: label2, target: item3) }
  let(:search_user) { user }
  let(:params) { {} }
  let(:items) { described_class.new(search_user, params.reverse_merge(scope: scope, state: 'opened')).execute }

  before_all do
    project1.add_maintainer(user)
    project2.add_developer(user)
    project2.add_developer(user2)
    project3.add_developer(user)
  end
end
