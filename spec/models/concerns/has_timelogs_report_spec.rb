# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HasTimelogsReport do
  let_it_be(:user) { create(:user) }

  let(:group)     { create(:group) }
  let(:project)   { create(:project, :public, group: group) }
  let(:issue1)    { create(:issue, project: project) }
  let(:merge_request1) { create(:merge_request, source_project: project) }

  describe '#timelogs' do
    let_it_be(:start_time) { 20.days.ago }
    let_it_be(:end_time) { 8.days.ago }

    let!(:timelog1) { create_timelog(15.days.ago, issue: issue1) }
    let!(:timelog2) { create_timelog(10.days.ago, merge_request: merge_request1) }
    let!(:timelog3) { create_timelog(5.days.ago, issue: issue1) }

    before do
      group.add_developer(user)
    end

    it 'returns collection of timelogs between given times' do
      expect(group.timelogs(start_time, end_time).to_a).to match_array([timelog1, timelog2])
    end

    it 'returns empty collection if times are not present' do
      expect(group.timelogs(nil, nil)).to be_empty
    end

    it 'returns empty collection if time range is invalid' do
      expect(group.timelogs(end_time, start_time)).to be_empty
    end
  end

  describe '#user_can_access_group_timelogs?' do
    it 'returns true if user can access group timelogs' do
      group.add_developer(user)

      expect(group).to be_user_can_access_group_timelogs(user)
    end

    it 'returns false if user has insufficient permissions' do
      group.add_guest(user)

      expect(group).not_to be_user_can_access_group_timelogs(user)
    end
  end

  def create_timelog(time, issue: nil, merge_request: nil)
    create(:timelog, issue: issue, merge_request: merge_request, user: user, spent_at: time)
  end
end
