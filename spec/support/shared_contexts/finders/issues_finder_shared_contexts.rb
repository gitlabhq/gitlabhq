# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_context 'IssuesFinder context' do
  set(:user) { create(:user) }
  set(:user2) { create(:user) }
  set(:group) { create(:group) }
  set(:subgroup) { create(:group, parent: group) }
  set(:project1) { create(:project, group: group) }
  set(:project2) { create(:project) }
  set(:project3) { create(:project, group: subgroup) }
  set(:milestone) { create(:milestone, project: project1) }
  set(:label) { create(:label, project: project2) }
  set(:issue1) { create(:issue, author: user, assignees: [user], project: project1, milestone: milestone, title: 'gitlab', created_at: 1.week.ago, updated_at: 1.week.ago) }
  set(:issue2) { create(:issue, author: user, assignees: [user], project: project2, description: 'gitlab', created_at: 1.week.from_now, updated_at: 1.week.from_now) }
  set(:issue3) { create(:issue, author: user2, assignees: [user2], project: project2, title: 'tanuki', description: 'tanuki', created_at: 2.weeks.from_now, updated_at: 2.weeks.from_now) }
  set(:issue4) { create(:issue, project: project3) }
  set(:award_emoji1) { create(:award_emoji, name: 'thumbsup', user: user, awardable: issue1) }
  set(:award_emoji2) { create(:award_emoji, name: 'thumbsup', user: user2, awardable: issue2) }
  set(:award_emoji3) { create(:award_emoji, name: 'thumbsdown', user: user, awardable: issue3) }
end

RSpec.shared_context 'IssuesFinder#execute context' do
  let!(:closed_issue) { create(:issue, author: user2, assignees: [user2], project: project2, state: 'closed') }
  let!(:label_link) { create(:label_link, label: label, target: issue2) }
  let(:search_user) { user }
  let(:params) { {} }
  let(:issues) { described_class.new(search_user, params.reverse_merge(scope: scope, state: 'opened')).execute }

  before(:context) do
    project1.add_maintainer(user)
    project2.add_developer(user)
    project2.add_developer(user2)
    project3.add_developer(user)

    issue1
    issue2
    issue3
    issue4

    award_emoji1
    award_emoji2
    award_emoji3
  end
end
