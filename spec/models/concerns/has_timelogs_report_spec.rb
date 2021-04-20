# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HasTimelogsReport do
  let(:user)      { create(:user) }
  let(:group)     { create(:group) }
  let(:issue)     { create(:issue, project: create(:project, :public, group: group)) }

  describe '#timelogs' do
    let!(:timelog1) { create_timelog(15.days.ago) }
    let!(:timelog2) { create_timelog(10.days.ago) }
    let!(:timelog3) { create_timelog(5.days.ago) }
    let(:start_time) { 20.days.ago }
    let(:end_time) { 8.days.ago }

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

  def create_timelog(time)
    create(:timelog, issue: issue, user: user, spent_at: time)
  end
end
