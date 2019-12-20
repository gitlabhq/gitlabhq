# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Timelog do
  subject { build(:timelog) }

  let(:issue) { create(:issue) }
  let(:merge_request) { create(:merge_request) }

  it { is_expected.to belong_to(:issue).touch(true) }
  it { is_expected.to belong_to(:merge_request).touch(true) }

  it { is_expected.to be_valid }

  it { is_expected.to validate_presence_of(:time_spent) }
  it { is_expected.to validate_presence_of(:user) }

  describe 'Issuable validation' do
    it 'is invalid if issue_id and merge_request_id are missing' do
      subject.attributes = { issue: nil, merge_request: nil }

      expect(subject).to be_invalid
    end

    it 'is invalid if issue_id and merge_request_id are set' do
      subject.attributes = { issue: issue, merge_request: merge_request }

      expect(subject).to be_invalid
    end

    it 'is valid if only issue_id is set' do
      subject.attributes = { issue: issue, merge_request: nil }

      expect(subject).to be_valid
    end

    it 'is valid if only merge_request_id is set' do
      subject.attributes = { merge_request: merge_request, issue: nil }

      expect(subject).to be_valid
    end
  end

  describe 'scopes' do
    describe 'for_issues_in_group' do
      it 'return timelogs created for group issues' do
        group = create(:group)
        subgroup = create(:group, parent: group)

        create(:timelog, issue: create(:issue, project: create(:project)))
        timelog1 = create(:timelog, issue: create(:issue, project: create(:project, group: group)))
        timelog2 = create(:timelog, issue: create(:issue, project: create(:project, group: subgroup)))

        expect(described_class.for_issues_in_group(group)).to contain_exactly(timelog1, timelog2)
      end
    end

    describe 'between_dates' do
      it 'returns collection of timelogs within given dates' do
        create(:timelog, spent_at: 65.days.ago)
        timelog1 = create(:timelog, spent_at: 15.days.ago)
        timelog2 = create(:timelog, spent_at: 5.days.ago)
        timelogs = described_class.between_dates(20.days.ago, 1.day.ago)

        expect(timelogs).to contain_exactly(timelog1, timelog2)
      end
    end
  end
end
