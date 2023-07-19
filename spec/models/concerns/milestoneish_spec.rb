# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Milestone, 'Milestoneish', factory_default: :keep do
  let_it_be(:author) { create(:user) }
  let_it_be(:assignee) { create(:user) }
  let_it_be(:non_member) { create(:user) }
  let_it_be(:member) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:project, reload: true) { create_default(:project, :public, :empty_repo).freeze }
  let_it_be(:milestone, refind: true) { create_default(:milestone, project: project) }
  let_it_be(:label1) { create(:label) }
  let_it_be(:label2) { create(:label) }
  let_it_be(:issue, reload: true) { create(:issue, milestone: milestone, assignees: [member], labels: [label1]) }
  let_it_be(:security_issue_1, reload: true) { create(:issue, :confidential, author: author, milestone: milestone, labels: [label2]) }
  let_it_be(:security_issue_2, reload: true) { create(:issue, :confidential, assignees: [assignee], milestone: milestone) }
  let_it_be(:closed_issue_1, reload: true) { create(:issue, :closed, milestone: milestone) }
  let_it_be(:closed_issue_2, reload: true) { create(:issue, :closed, milestone: milestone) }
  let_it_be(:closed_security_issue_1, reload: true) { create(:issue, :confidential, :closed, author: author, milestone: milestone) }
  let_it_be(:closed_security_issue_2, reload: true) { create(:issue, :confidential, :closed, assignees: [assignee], milestone: milestone) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project, milestone: milestone) }
  let_it_be(:label_1) { create(:label, title: 'label_1', priority: 1) }
  let_it_be(:label_2) { create(:label, title: 'label_2', priority: 2) }
  let_it_be(:label_3) { create(:label, title: 'label_3') }

  before do
    project.add_developer(member)
    project.add_guest(guest)
  end

  describe '#sorted_issues' do
    before do
      issue.labels << label_1
      security_issue_1.labels << label_2
      closed_issue_1.labels << label_3
    end

    it 'sorts issues by label priority' do
      issues = milestone.sorted_issues(member)

      expect(issues.first).to eq(issue)
      expect(issues.second).to eq(security_issue_1)
      expect(issues.third).not_to eq(closed_issue_1)
    end

    it 'limits issue count and keeps the ordering' do
      stub_const('Milestoneish::DISPLAY_ISSUES_LIMIT', 4)

      issues = milestone.sorted_issues(member)
      # Cannot use issues.count here because it is sorting
      # by a virtual column 'highest_priority' and it will break
      # the query.
      total_issues_count = issues.opened.unassigned.length + issues.opened.assigned.length + issues.closed.length
      expect(issues.length).to eq(4)
      expect(total_issues_count).to eq(4)
      expect(issues.first).to eq(issue)
      expect(issues.second).to eq(security_issue_1)
      expect(issues.third).not_to eq(closed_issue_1)
    end
  end

  context 'with attributes visibility' do
    using RSpec::Parameterized::TableSyntax

    let(:users) do
      {
        anonymous: nil,
        non_member: non_member,
        guest: guest,
        member: member,
        assignee: assignee
      }
    end

    let(:project_visibility_levels) do
      {
        public: Gitlab::VisibilityLevel::PUBLIC,
        internal: Gitlab::VisibilityLevel::INTERNAL,
        private: Gitlab::VisibilityLevel::PRIVATE
      }
    end

    describe '#issue_participants_visible_by_user' do
      where(:visibility, :user_role, :result) do
        :public   | nil         | [:member]
        :public   | :non_member | [:member]
        :public   | :guest      | [:member]
        :public   | :member     | [:member, :assignee]
        :internal | nil         | []
        :internal | :non_member | [:member]
        :internal | :guest      | [:member]
        :internal | :member     | [:member, :assignee]
        :private  | nil         | []
        :private  | :non_member | []
        :private  | :guest      | [:member]
        :private  | :member     | [:member, :assignee]
      end

      with_them do
        before do
          project.update!(visibility_level: project_visibility_levels[visibility])
        end

        it 'returns the proper participants' do
          user = users[user_role]
          participants = result.map { |role| users[role] }

          expect(milestone.issue_participants_visible_by_user(user)).to match_array(participants)
        end
      end
    end

    describe '#issue_labels_visible_by_user' do
      let(:labels) do
        {
          label1: label1,
          label2: label2
        }
      end

      where(:visibility, :user_role, :result) do
        :public   | nil         | [:label1]
        :public   | :non_member | [:label1]
        :public   | :guest      | [:label1]
        :public   | :member     | [:label1, :label2]
        :internal | nil         | []
        :internal | :non_member | [:label1]
        :internal | :guest      | [:label1]
        :internal | :member     | [:label1, :label2]
        :private  | nil         | []
        :private  | :non_member | []
        :private  | :guest      | [:label1]
        :private  | :member     | [:label1, :label2]
      end

      with_them do
        before do
          project.update!(visibility_level: project_visibility_levels[visibility])
        end

        it 'returns the proper participants' do
          user = users[user_role]
          expected_labels = result.map { |label| labels[label] }

          expect(milestone.issue_labels_visible_by_user(user)).to match_array(expected_labels)
        end
      end
    end
  end

  describe '#sorted_merge_requests' do
    it 'sorts merge requests by label priority' do
      merge_request_1 = create(:labeled_merge_request, labels: [label_2], source_project: project, source_branch: 'branch_1', milestone: milestone)
      merge_request_2 = create(:labeled_merge_request, labels: [label_1], source_project: project, source_branch: 'branch_2', milestone: milestone)
      merge_request_3 = create(:labeled_merge_request, labels: [label_3], source_project: project, source_branch: 'branch_3', milestone: milestone)

      merge_requests = milestone.sorted_merge_requests(member)

      expect(merge_requests.first).to eq(merge_request_2)
      expect(merge_requests.second).to eq(merge_request_1)
      expect(merge_requests.third).to eq(merge_request_3)
    end
  end

  describe '#merge_requests_visible_to_user' do
    context 'when project is private' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it 'does not return any merge request for a non member' do
        merge_requests = milestone.merge_requests_visible_to_user(non_member)
        expect(merge_requests).to be_empty
      end

      it 'returns milestone merge requests for a member' do
        merge_requests = milestone.merge_requests_visible_to_user(member)
        expect(merge_requests).to contain_exactly(merge_request)
      end
    end

    context 'when project is public' do
      context 'when merge requests are available to anyone' do
        it 'returns milestone merge requests for a non member' do
          merge_requests = milestone.merge_requests_visible_to_user(non_member)
          expect(merge_requests).to contain_exactly(merge_request)
        end
      end

      context 'when merge requests are available to project members' do
        before do
          project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
        end

        it 'does not return any merge request for a non member' do
          merge_requests = milestone.merge_requests_visible_to_user(non_member)
          expect(merge_requests).to be_empty
        end

        it 'returns milestone merge requests for a member' do
          merge_requests = milestone.merge_requests_visible_to_user(member)
          expect(merge_requests).to contain_exactly(merge_request)
        end
      end
    end

    context 'when milestone is at parent level group' do
      let_it_be(:parent_group) { create(:group) }
      let_it_be(:group) { create(:group, parent: parent_group) }
      let_it_be(:project) { create(:project, :empty_repo, namespace: group) }
      let_it_be(:milestone) { create(:milestone, group: parent_group) }
      let_it_be(:merge_request) { create(:merge_request, source_project: project, milestone: milestone) }

      it 'does not return any merge request for a non member' do
        merge_requests = milestone.merge_requests_visible_to_user(non_member)
        expect(merge_requests).to be_empty
      end

      it 'returns milestone merge requests for a member' do
        merge_requests = milestone.merge_requests_visible_to_user(member)
        expect(merge_requests).to contain_exactly(merge_request)
      end
    end
  end

  describe '#complete?', :use_clean_rails_memory_store_caching do
    it 'returns false when has items opened' do
      expect(milestone.complete?).to eq false
    end

    it 'returns true when all items are closed' do
      issue.close
      security_issue_1.close
      security_issue_2.close

      expect(milestone.complete?).to eq true
    end
  end

  describe '#percent_complete', :use_clean_rails_memory_store_caching do
    context 'with division by zero' do
      let(:new_milestone) { build_stubbed(:milestone) }

      it { expect(new_milestone.percent_complete).to eq(0) }
    end
  end

  describe '#closed_issues_count' do
    it 'counts all closed issues including confidential' do
      expect(milestone.closed_issues_count).to eq 4
    end
  end

  describe '#total_issues_count' do
    it 'counts all issues including confidential' do
      expect(milestone.total_issues_count).to eq 7
    end
  end

  describe '#total_merge_requests_count' do
    it 'counts merge requests' do
      expect(milestone.total_merge_requests_count).to eq 1
    end
  end

  describe '#remaining_days' do
    it 'shows 0 if no due date' do
      milestone = build_stubbed(:milestone)

      expect(milestone.remaining_days).to eq(0)
    end

    it 'shows 0 if expired' do
      milestone = build_stubbed(:milestone, due_date: 2.days.ago)

      expect(milestone.remaining_days).to eq(0)
    end

    it 'shows correct remaining days' do
      milestone = build_stubbed(:milestone, due_date: 2.days.from_now)

      expect(milestone.remaining_days).to eq(2)
    end
  end

  describe '#elapsed_days' do
    it 'shows 0 if no start_date set' do
      milestone = build_stubbed(:milestone)

      expect(milestone.elapsed_days).to eq(0)
    end

    it 'shows 0 if start_date is a future' do
      milestone = build_stubbed(:milestone, start_date: Time.current + 2.days)

      expect(milestone.elapsed_days).to eq(0)
    end

    it 'shows correct amount of days' do
      milestone = build_stubbed(:milestone, start_date: Time.current - 2.days)

      expect(milestone.elapsed_days).to eq(2)
    end
  end

  describe '#total_time_spent' do
    it 'calculates total time spent' do
      closed_issue_1.spend_time(duration: 300, user_id: author.id)
      closed_issue_1.save!
      closed_issue_2.spend_time(duration: 600, user_id: assignee.id)
      closed_issue_2.save!

      expect(milestone.total_time_spent).to eq(900)
    end

    it 'includes merge request time spent' do
      closed_issue_1.spend_time(duration: 300, user_id: author.id)
      closed_issue_1.save!
      merge_request.spend_time(duration: 900, user_id: author.id)
      merge_request.save!

      expect(milestone.total_time_spent).to eq(1200)
    end
  end

  describe '#human_total_time_spent' do
    it 'returns nil if no time has been spent' do
      expect(milestone.human_total_time_spent).to be_nil
    end
  end

  describe '#total_time_estimate' do
    it 'calculates total estimate' do
      closed_issue_1.time_estimate = 300
      closed_issue_1.save!
      closed_issue_2.time_estimate = 600
      closed_issue_2.save!

      expect(milestone.total_time_estimate).to eq(900)
    end

    it 'includes merge request time estimate' do
      closed_issue_1.time_estimate = 300
      closed_issue_1.save!
      merge_request.time_estimate = 900
      merge_request.save!

      expect(milestone.total_time_estimate).to eq(1200)
    end
  end

  describe '#human_total_time_estimate' do
    it 'returns nil if no time has been spent' do
      expect(milestone.human_total_time_estimate).to be_nil
    end
  end

  describe '#expires_at' do
    it 'returns the date when milestone expires' do
      due_date = Date.today + 1.day
      milestone.due_date = due_date

      expect(milestone.expires_at).to eq("expires on #{due_date.to_fs(:medium)}")
    end

    it 'returns the date when milestone expires' do
      due_date = Date.today - 1.day
      milestone.due_date = due_date

      expect(milestone.expires_at).to eq("expired on #{due_date.to_fs(:medium)}")
    end
  end
end
