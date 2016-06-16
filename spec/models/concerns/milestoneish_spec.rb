require 'spec_helper'

describe Milestone, 'Milestoneish' do
  let(:author) { create(:user) }
  let(:assignee) { create(:user) }
  let(:non_member) { create(:user) }
  let(:member) { create(:user) }
  let(:admin) { create(:admin) }
  let(:project) { create(:project, :public) }
  let(:milestone) { create(:milestone, project: project) }
  let!(:issue) { create(:issue, project: project, milestone: milestone) }
  let!(:security_issue_1) { create(:issue, :confidential, project: project, author: author, milestone: milestone) }
  let!(:security_issue_2) { create(:issue, :confidential, project: project, assignee: assignee, milestone: milestone) }
  let!(:closed_issue_1) { create(:issue, :closed, project: project, milestone: milestone) }
  let!(:closed_issue_2) { create(:issue, :closed, project: project, milestone: milestone) }
  let!(:closed_security_issue_1) { create(:issue, :confidential, :closed, project: project, author: author, milestone: milestone) }
  let!(:closed_security_issue_2) { create(:issue, :confidential, :closed, project: project, assignee: assignee, milestone: milestone) }
  let!(:closed_security_issue_3) { create(:issue, :confidential, :closed, project: project, author: author, milestone: milestone) }
  let!(:closed_security_issue_4) { create(:issue, :confidential, :closed, project: project, assignee: assignee, milestone: milestone) }
  let!(:merge_request) { create(:merge_request, source_project: project, target_project: project, milestone: milestone) }

  before do
    project.team << [member, :developer]
  end

  describe '#closed_items_count' do
    it 'should not count confidential issues for non project members' do
      expect(milestone.closed_items_count(non_member)).to eq 2
    end

    it 'should count confidential issues for author' do
      expect(milestone.closed_items_count(author)).to eq 4
    end

    it 'should count confidential issues for assignee' do
      expect(milestone.closed_items_count(assignee)).to eq 4
    end

    it 'should count confidential issues for project members' do
      expect(milestone.closed_items_count(member)).to eq 6
    end

    it 'should count all issues for admin' do
      expect(milestone.closed_items_count(admin)).to eq 6
    end
  end

  describe '#total_items_count' do
    it 'should not count confidential issues for non project members' do
      expect(milestone.total_items_count(non_member)).to eq 4
    end

    it 'should count confidential issues for author' do
      expect(milestone.total_items_count(author)).to eq 7
    end

    it 'should count confidential issues for assignee' do
      expect(milestone.total_items_count(assignee)).to eq 7
    end

    it 'should count confidential issues for project members' do
      expect(milestone.total_items_count(member)).to eq 10
    end

    it 'should count all issues for admin' do
      expect(milestone.total_items_count(admin)).to eq 10
    end
  end

  describe '#complete?' do
    it 'returns false when has items opened' do
      expect(milestone.complete?(non_member)).to eq false
    end

    it 'returns true when all items are closed' do
      issue.close
      merge_request.close

      expect(milestone.complete?(non_member)).to eq true
    end
  end

  describe '#percent_complete' do
    it 'should not count confidential issues for non project members' do
      expect(milestone.percent_complete(non_member)).to eq 50
    end

    it 'should count confidential issues for author' do
      expect(milestone.percent_complete(author)).to eq 57
    end

    it 'should count confidential issues for assignee' do
      expect(milestone.percent_complete(assignee)).to eq 57
    end

    it 'should count confidential issues for project members' do
      expect(milestone.percent_complete(member)).to eq 60
    end

    it 'should count confidential issues for admin' do
      expect(milestone.percent_complete(admin)).to eq 60
    end
  end
end
