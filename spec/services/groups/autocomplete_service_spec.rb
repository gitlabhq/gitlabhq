# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::AutocompleteService, feature_category: :groups_and_projects do
  let_it_be(:group, refind: true) { create(:group, :nested, :private, avatar: fixture_file_upload('spec/fixtures/dk.png')) }
  let_it_be(:sub_group) { create(:group, :private, parent: group) }

  let(:user) { create(:user) }

  subject { described_class.new(group, user) }

  before do
    group.add_developer(user)
  end

  def expect_labels_to_equal(labels, expected_labels)
    extract_title = ->(label) { label['title'] }
    expect(labels.map(&extract_title)).to match_array(expected_labels.map(&extract_title))
  end

  describe '#labels_as_hash' do
    let!(:label1) { create(:group_label, group: group) }
    let!(:label2) { create(:group_label, group: group) }
    let!(:sub_group_label) { create(:group_label, group: sub_group) }
    let!(:parent_group_label) { create(:group_label, group: group.parent) }

    it 'returns labels from own group and ancestor groups' do
      results = subject.labels_as_hash(nil)

      expected_labels = [label1, label2, parent_group_label]

      expect_labels_to_equal(results, expected_labels)
    end
  end

  describe '#issues' do
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:sub_group_project) { create(:project, group: sub_group) }

    let_it_be(:group_issue) { create(:work_item, :group_level, namespace: group) }
    let_it_be(:project_issue) { create(:issue, project: project) }
    let_it_be(:sub_group_issue) { create(:work_item, :group_level, namespace: sub_group) }
    let_it_be(:sub_group_project_issue) { create(:issue, confidential: true, project: sub_group_project) }

    it 'returns issues in group and subgroups' do
      issues = subject.issues

      expect(issues.map(&:iid)).to contain_exactly(
        project_issue.iid, sub_group_project_issue.iid, group_issue.iid, sub_group_issue.iid
      )
      expect(issues.map(&:title)).to contain_exactly(
        project_issue.title, sub_group_project_issue.title, group_issue.title, sub_group_issue.title
      )
      expect(issues.map(&:icon_name).uniq).to contain_exactly('issue-type-issue')
    end

    it 'returns only confidential issues if confidential_only is true' do
      issues = subject.issues(confidential_only: true)

      expect(issues.map(&:iid)).to contain_exactly(sub_group_project_issue.iid)
      expect(issues.map(&:title)).to contain_exactly(sub_group_project_issue.title)
    end

    context 'when namespace_level_work_items feature flag is disabled' do
      before do
        stub_feature_flags(namespace_level_work_items: false)
      end

      it 'returns issues in projects only' do
        issues = subject.issues

        expect(issues.map(&:iid)).to contain_exactly(project_issue.iid, sub_group_project_issue.iid)
        expect(issues.map(&:title)).to contain_exactly(project_issue.title, sub_group_project_issue.title)
      end
    end

    context 'when search param is given' do
      let_it_be(:issue_8) { create(:issue, project: project, iid: 8) }
      let_it_be(:issue_80) { create(:work_item, :group_level, namespace: group, iid: 80) }
      let_it_be(:issue_800) { create(:work_item, :group_level, namespace: sub_group, iid: 800) }
      let_it_be(:issue_8000) { create(:issue, project: sub_group_project, iid: 8000) }
      let_it_be(:issue_80000) { create(:issue, project: sub_group_project, iid: 80000) }
      let_it_be(:issue_90000) { create(:issue, project: project, title: 'gitlab issue 8', iid: 90000) }

      it 'returns limited list of matching issues' do
        autocomplete = described_class.new(group, user, { search: '8' })

        issue_iids = autocomplete.issues.map(&:iid)

        expect(issue_iids).to eq([90000, 80000, 8000, 800, 80])
      end
    end
  end

  describe '#merge_requests' do
    let(:project) { create(:project, :repository, group: group) }
    let(:sub_group_project) { create(:project, :repository, group: sub_group) }

    let!(:project_mr) { create(:merge_request, source_project: project) }
    let!(:sub_group_project_mr) { create(:merge_request, source_project: sub_group_project) }

    it 'returns merge requests in group and subgroups' do
      expect(subject.merge_requests.map(&:iid)).to contain_exactly(project_mr.iid, sub_group_project_mr.iid)
      expect(subject.merge_requests.map(&:title)).to contain_exactly(project_mr.title, sub_group_project_mr.title)
    end
  end

  describe '#milestones' do
    let!(:group_milestone) { create(:milestone, group: group) }
    let!(:subgroup_milestone) { create(:milestone, group: sub_group) }

    before do
      sub_group.add_maintainer(user)
    end

    context 'when group is public' do
      let(:public_group) { create(:group, :public) }
      let(:public_subgroup) { create(:group, :public, parent: public_group) }

      before do
        group_milestone.update!(group: public_group)
        subgroup_milestone.update!(group: public_subgroup)
      end

      it 'returns milestones from groups and subgroups' do
        subject = described_class.new(public_subgroup, user)

        expect(subject.milestones.map(&:iid)).to contain_exactly(group_milestone.iid, subgroup_milestone.iid)
        expect(subject.milestones.map(&:title)).to contain_exactly(group_milestone.title, subgroup_milestone.title)
      end
    end

    it 'returns milestones from group' do
      expect(subject.milestones.map(&:iid)).to contain_exactly(group_milestone.iid)
      expect(subject.milestones.map(&:title)).to contain_exactly(group_milestone.title)
    end

    it 'returns milestones from groups and subgroups' do
      milestones = described_class.new(sub_group, user).milestones

      expect(milestones.map(&:iid)).to contain_exactly(group_milestone.iid, subgroup_milestone.iid)
      expect(milestones.map(&:title)).to contain_exactly(group_milestone.title, subgroup_milestone.title)
    end

    it 'returns only milestones that user can read' do
      user = create(:user)
      sub_group.add_guest(user)

      milestones = described_class.new(sub_group, user).milestones

      expect(milestones.map(&:iid)).to contain_exactly(subgroup_milestone.iid)
      expect(milestones.map(&:title)).to contain_exactly(subgroup_milestone.title)
    end
  end
end
