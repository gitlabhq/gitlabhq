# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GroupSearchResults, feature_category: :global_search do
  # group creation calls GroupFinder, so need to create the group
  # before so expect(GroupsFinder) check works
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, group: group) }

  let(:filters) { {} }
  let(:limit_projects) { Project.all }
  let(:query) { 'gob' }

  subject(:results) { described_class.new(user, query, limit_projects, group: group, filters: filters) }

  describe 'issues search' do
    let_it_be(:opened_result) { create(:issue, :opened, project: project, title: 'foo opened') }
    let_it_be(:closed_result) { create(:issue, :closed, project: project, title: 'foo closed') }
    let_it_be(:confidential_result) { create(:issue, :confidential, project: project, title: 'foo confidential') }

    let(:query) { 'foo' }
    let(:scope) { 'issues' }

    before_all do
      project.add_developer(user)
    end

    include_examples 'search results filtered by state'
    include_examples 'search results filtered by confidential'
  end

  describe 'merge_requests search' do
    let_it_be(:unarchived_project) { create(:project, :public, group: group) }
    let_it_be(:archived_project) { create(:project, :public, :archived, group: group) }
    let(:opened_result) { create(:merge_request, :opened, source_project: project, title: 'foo opened') }
    let(:closed_result) { create(:merge_request, :closed, source_project: project, title: 'foo closed') }
    let_it_be(:unarchived_result) { create(:merge_request, source_project: unarchived_project, title: 'foo') }
    let_it_be(:archived_result) { create(:merge_request, source_project: archived_project, title: 'foo') }
    let(:query) { 'foo' }
    let(:scope) { 'merge_requests' }

    before do
      # we're creating those instances in before block because otherwise factory for MRs will fail on after(:build)
      opened_result
      closed_result
    end

    include_examples 'search results filtered by state'
    include_examples 'search results filtered by archived'
  end

  describe 'milestones search' do
    let!(:unarchived_project) { create(:project, :public, group: group) }
    let!(:archived_project) { create(:project, :public, :archived, group: group) }
    let!(:unarchived_result) { create(:milestone, project: unarchived_project, title: 'foo') }
    let!(:archived_result) { create(:milestone, project: archived_project, title: 'foo') }
    let(:query) { 'foo' }
    let(:scope) { 'milestones' }

    include_examples 'search results filtered by archived'

    context 'when user cannot read milestones on the group' do
      let_it_be(:private_group) { create(:group, :private) }
      let_it_be(:private_project) { create(:project, :private, group: private_group) }
      let!(:milestone) { create(:milestone, project: private_project, title: 'foo secret') }
      let(:query) { 'foo' }
      let(:limit_projects) do
        projects = ::ProjectsFinder.new(current_user: user).execute.preload(:topics, :project_topics, :route)
        projects.for_group_and_its_subgroups(private_group)
      end

      it 'returns no milestones' do
        results = described_class.new(user, query, limit_projects, group: private_group, filters: filters)

        expect(results.objects('milestones')).to be_empty
      end
    end

    context 'with group milestones' do
      let!(:group_milestone) { create(:milestone, group: group, title: 'foo group milestone') }
      let(:query) { 'foo' }

      it 'includes group milestones in search results' do
        expect(results.objects('milestones')).to include(group_milestone)
      end

      it 'includes both project and group milestones' do
        objects = results.objects('milestones')

        expect(objects).to include(unarchived_result, group_milestone)
      end
    end

    context 'with ancestor group milestones' do
      let_it_be(:parent_group) { create(:group) }
      let_it_be(:child_group) { create(:group, parent: parent_group) }
      let_it_be(:child_project) { create(:project, :public, group: child_group) }
      let!(:parent_milestone) { create(:milestone, group: parent_group, title: 'foo parent') }
      let!(:child_milestone) { create(:milestone, group: child_group, title: 'foo child') }
      let!(:project_milestone) { create(:milestone, project: child_project, title: 'foo project') }
      let(:query) { 'foo' }

      subject(:results) { described_class.new(user, query, Project.all, group: child_group, filters: filters) }

      it 'includes milestones from ancestor groups' do
        objects = results.objects('milestones')

        expect(objects).to include(parent_milestone, child_milestone, project_milestone)
      end
    end
  end

  describe '#projects' do
    let(:scope) { 'projects' }
    let(:query) { 'Test' }

    describe 'filtering' do
      let_it_be(:group) { create(:group) }
      let_it_be(:unarchived_result) { create(:project, :public, group: group, name: 'Test1') }
      let_it_be(:archived_result) { create(:project, :archived, :public, group: group, name: 'Test2') }

      it_behaves_like 'search results filtered by archived'
    end
  end

  describe 'user search' do
    subject(:objects) { results.objects('users') }

    it 'returns the users belonging to the group matching the search query' do
      user1 = create(:user, username: 'gob_bluth')
      create(:group_member, :developer, user: user1, group: group)

      user2 = create(:user, username: 'michael_bluth')
      create(:group_member, :developer, user: user2, group: group)

      create(:user, username: 'gob_2018')

      is_expected.to eq [user1]
    end

    it 'returns the user belonging to the subgroup matching the search query' do
      user1 = create(:user, username: 'gob_bluth')
      subgroup = create(:group, parent: group)
      create(:group_member, :developer, user: user1, group: subgroup)

      create(:user, username: 'gob_2018')

      is_expected.to eq [user1]
    end

    it 'returns the user belonging to the parent group matching the search query' do
      user1 = create(:user, username: 'gob_bluth')
      parent_group = create(:group, children: [group])
      create(:group_member, :developer, user: user1, group: parent_group)

      create(:user, username: 'gob_2018')

      is_expected.to eq [user1]
    end

    it 'does not return the user belonging to the private subgroup' do
      user1 = create(:user, username: 'gob_bluth')
      subgroup = create(:group, :private, parent: group)
      create(:group_member, :developer, user: user1, group: subgroup)

      create(:user, username: 'gob_2018')

      is_expected.to be_empty
    end

    it 'does not return the user belonging to an unrelated group' do
      user = create(:user, username: 'gob_bluth')
      unrelated_group = create(:group)
      create(:group_member, :developer, user: user, group: unrelated_group)

      is_expected.to be_empty
    end

    it 'does not return the user invited to the group' do
      user = create(:user, username: 'gob_bluth')
      create(:group_member, :invited, :developer, user: user, group: group)

      is_expected.to be_empty
    end

    it 'calls GroupFinder during execution' do
      expect(GroupsFinder).to receive(:new).with(user).and_call_original

      objects
    end

    context 'when private project member searches for user in private group' do
      let_it_be(:private_group) { create(:group, :private) }
      let_it_be(:private_project) { create(:project, :private, group: private_group) }
      let_it_be(:user2) { create(:user, username: 'gob_bluth') }

      let(:private_results) { described_class.new(user, query, limit_projects, group: private_group, filters: filters) }

      before_all do
        private_group.add_guest(user2)
        private_project.add_guest(user)
      end

      it 'returns empty when user does not have read_group_member permission' do
        expect(private_results.objects('users')).to be_empty
      end
    end
  end

  describe "#issuable_params" do
    it 'sets include_subgroups flag by default' do
      expect(results.issuable_params[:include_subgroups]).to be(true)
    end
  end

  describe '#work_items', unless: Gitlab.ee? do
    it 'returns issues when searching for work items' do
      issue = create(:issue, project: project, title: 'test issue')
      project.add_developer(user)

      results_query = described_class.new(user, 'test', limit_projects, group: group)
      work_items_results = results_query.work_items

      expect(work_items_results).to include(issue)
    end

    it 'passes finder params to underlying issues search' do
      closed_issue = create(:issue, :closed, project: project, title: 'test closed')
      opened_issue = create(:issue, :opened, project: project, title: 'test opened')
      project.add_developer(user)

      results_query = described_class.new(user, 'test', limit_projects, group: group)
      work_items_results = results_query.work_items(state: 'closed')

      expect(work_items_results).to include(closed_issue)
      expect(work_items_results).not_to include(opened_issue)
    end

    context 'when filtering by work_item_type_ids' do
      let(:task_type) { WorkItems::TypesFramework::Provider.new.find_by_base_type(:task) }

      let!(:task_work_item) { create(:work_item, :task, project: project, title: 'test task') }
      let!(:issue_work_item) { create(:work_item, project: project, title: 'test issue wi') }

      before_all do
        project.add_developer(user)
      end

      it 'filters by work_item_type_ids when present in filters' do
        filtered_results = described_class.new(
          user, 'test', limit_projects, group: group,
          filters: { work_item_type_ids: [task_type.id] }
        )

        expect(filtered_results.objects('work_items')).to include(task_work_item)
        expect(filtered_results.objects('work_items')).not_to include(issue_work_item)
      end

      it 'returns all work items when work_item_type_ids filter is empty' do
        filtered_results = described_class.new(
          user, 'test', limit_projects, group: group,
          filters: {}
        )

        expect(filtered_results.objects('work_items')).to include(task_work_item, issue_work_item)
      end
    end
  end
end
