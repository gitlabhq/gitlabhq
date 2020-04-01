# frozen_string_literal: true

RSpec.shared_context 'IssuesFinder context' do
  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project1, reload: true) { create(:project, group: group) }
  let_it_be(:project2, reload: true) { create(:project) }
  let_it_be(:project3, reload: true) { create(:project, group: subgroup) }
  let_it_be(:milestone) { create(:milestone, project: project1) }
  let_it_be(:label) { create(:label, project: project2) }
  let_it_be(:label2) { create(:label, project: project2) }
  let_it_be(:issue1, reload: true) { create(:issue, author: user, assignees: [user], project: project1, milestone: milestone, title: 'gitlab', created_at: 1.week.ago, updated_at: 1.week.ago) }
  let_it_be(:issue2, reload: true) { create(:issue, author: user, assignees: [user], project: project2, description: 'gitlab', created_at: 1.week.from_now, updated_at: 1.week.from_now) }
  let_it_be(:issue3, reload: true) { create(:issue, author: user2, assignees: [user2], project: project2, title: 'tanuki', description: 'tanuki', created_at: 2.weeks.from_now, updated_at: 2.weeks.from_now) }
  let_it_be(:issue4, reload: true) { create(:issue, project: project3) }
  let_it_be(:award_emoji1) { create(:award_emoji, name: 'thumbsup', user: user, awardable: issue1) }
  let_it_be(:award_emoji2) { create(:award_emoji, name: 'thumbsup', user: user2, awardable: issue2) }
  let_it_be(:award_emoji3) { create(:award_emoji, name: 'thumbsdown', user: user, awardable: issue3) }
end

RSpec.shared_context 'IssuesFinder#execute context' do
  let!(:closed_issue) { create(:issue, author: user2, assignees: [user2], project: project2, state: 'closed') }
  let!(:label_link) { create(:label_link, label: label, target: issue2) }
  let!(:label_link2) { create(:label_link, label: label2, target: issue3) }
  let(:search_user) { user }
  let(:params) { {} }
  let(:issues) { described_class.new(search_user, params.reverse_merge(scope: scope, state: 'opened')).execute }

  before_all do
    project1.add_maintainer(user)
    project2.add_developer(user)
    project2.add_developer(user2)
    project3.add_developer(user)
  end
end
