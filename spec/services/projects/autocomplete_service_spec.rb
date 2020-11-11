# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::AutocompleteService do
  describe '#issues' do
    describe 'confidential issues' do
      let(:author) { create(:user) }
      let(:assignee) { create(:user) }
      let(:non_member) { create(:user) }
      let(:member) { create(:user) }
      let(:admin) { create(:admin) }
      let(:project) { create(:project, :public) }
      let!(:issue) { create(:issue, project: project, title: 'Issue 1') }
      let!(:security_issue_1) { create(:issue, :confidential, project: project, title: 'Security issue 1', author: author) }
      let!(:security_issue_2) { create(:issue, :confidential, title: 'Security issue 2', project: project, assignees: [assignee]) }

      it 'does not list project confidential issues for guests' do
        autocomplete = described_class.new(project, nil)
        issues = autocomplete.issues.map(&:iid)

        expect(issues).to include issue.iid
        expect(issues).not_to include security_issue_1.iid
        expect(issues).not_to include security_issue_2.iid
        expect(issues.count).to eq 1
      end

      it 'does not list project confidential issues for non project members' do
        autocomplete = described_class.new(project, non_member)
        issues = autocomplete.issues.map(&:iid)

        expect(issues).to include issue.iid
        expect(issues).not_to include security_issue_1.iid
        expect(issues).not_to include security_issue_2.iid
        expect(issues.count).to eq 1
      end

      it 'does not list project confidential issues for project members with guest role' do
        project.add_guest(member)

        autocomplete = described_class.new(project, non_member)
        issues = autocomplete.issues.map(&:iid)

        expect(issues).to include issue.iid
        expect(issues).not_to include security_issue_1.iid
        expect(issues).not_to include security_issue_2.iid
        expect(issues.count).to eq 1
      end

      it 'lists project confidential issues for author' do
        autocomplete = described_class.new(project, author)
        issues = autocomplete.issues.map(&:iid)

        expect(issues).to include issue.iid
        expect(issues).to include security_issue_1.iid
        expect(issues).not_to include security_issue_2.iid
        expect(issues.count).to eq 2
      end

      it 'lists project confidential issues for assignee' do
        autocomplete = described_class.new(project, assignee)
        issues = autocomplete.issues.map(&:iid)

        expect(issues).to include issue.iid
        expect(issues).not_to include security_issue_1.iid
        expect(issues).to include security_issue_2.iid
        expect(issues.count).to eq 2
      end

      it 'lists project confidential issues for project members' do
        project.add_developer(member)

        autocomplete = described_class.new(project, member)
        issues = autocomplete.issues.map(&:iid)

        expect(issues).to include issue.iid
        expect(issues).to include security_issue_1.iid
        expect(issues).to include security_issue_2.iid
        expect(issues.count).to eq 3
      end

      context 'when admin mode is enabled', :enable_admin_mode do
        it 'lists all project issues for admin', :enable_admin_mode do
          autocomplete = described_class.new(project, admin)
          issues = autocomplete.issues.map(&:iid)

          expect(issues).to include issue.iid
          expect(issues).to include security_issue_1.iid
          expect(issues).to include security_issue_2.iid
          expect(issues.count).to eq 3
        end
      end

      context 'when admin mode is disabled' do
        it 'does not list project confidential issues for admin' do
          autocomplete = described_class.new(project, admin)
          issues = autocomplete.issues.map(&:iid)

          expect(issues).to include issue.iid
          expect(issues).not_to include security_issue_1.iid
          expect(issues).not_to include security_issue_2.iid
          expect(issues.count).to eq 1
        end
      end
    end
  end

  describe '#milestones' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:project) { create(:project, group: group) }
    let!(:group_milestone1) { create(:milestone, group: group, due_date: '2017-01-01', title: 'Second Title') }
    let!(:group_milestone2) { create(:milestone, group: group, due_date: '2017-01-01', title: 'First Title') }
    let!(:project_milestone) { create(:milestone, project: project, due_date: '2016-01-01') }

    let(:milestone_titles) { described_class.new(project, user).milestones.map(&:title) }

    it 'includes project and group milestones and sorts them correctly' do
      expect(milestone_titles).to eq([project_milestone.title, group_milestone2.title, group_milestone1.title])
    end

    it 'does not include closed milestones' do
      group_milestone1.close

      expect(milestone_titles).to eq([project_milestone.title, group_milestone2.title])
    end

    it 'does not include milestones from other projects in the group' do
      other_project = create(:project, group: group)
      project_milestone.update!(project: other_project)

      expect(milestone_titles).to eq([group_milestone2.title, group_milestone1.title])
    end

    context 'with nested groups' do
      let(:subgroup) { create(:group, :public, parent: group) }
      let!(:subgroup_milestone) { create(:milestone, group: subgroup) }

      before do
        project.update!(namespace: subgroup)
      end

      it 'includes project milestones and all acestors milestones' do
        expect(milestone_titles).to match_array(
          [project_milestone.title, group_milestone2.title, group_milestone1.title, subgroup_milestone.title]
        )
      end
    end
  end

  describe '#labels_as_hash' do
    def expect_labels_to_equal(labels, expected_labels)
      expect(labels.size).to eq(expected_labels.size)
      extract_title = lambda { |label| label['title'] }
      expect(labels.map(&extract_title)).to match_array(expected_labels.map(&extract_title))
    end

    let(:user) { create(:user) }
    let(:group) { create(:group, :nested) }
    let!(:sub_group) { create(:group, parent: group) }
    let(:project) { create(:project, :public, group: group) }
    let(:issue) { create(:issue, project: project) }

    let!(:label1) { create(:label, project: project) }
    let!(:label2) { create(:label, project: project) }
    let!(:sub_group_label) { create(:group_label, group: sub_group) }
    let!(:parent_group_label) { create(:group_label, group: group.parent, group_id: group.id) }

    before do
      create(:group_member, group: group, user: user)
    end

    it 'returns labels from project and ancestor groups' do
      service = described_class.new(project, user)
      results = service.labels_as_hash(nil)
      expected_labels = [label1, label2, parent_group_label]

      expect_labels_to_equal(results, expected_labels)
    end

    context 'some labels are already assigned' do
      before do
        issue.labels << label1
      end

      it 'marks already assigned as set' do
        service = described_class.new(project, user)
        results = service.labels_as_hash(issue)
        expected_labels = [label1, label2, parent_group_label]

        expect_labels_to_equal(results, expected_labels)

        assigned_label_titles = issue.labels.map(&:title)
        results.each do |hash|
          if assigned_label_titles.include?(hash['title'])
            expect(hash[:set]).to eq(true)
          else
            expect(hash.key?(:set)).to eq(false)
          end
        end
      end
    end
  end
end
