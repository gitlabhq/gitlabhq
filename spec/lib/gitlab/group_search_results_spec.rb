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

    before do
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

      subject
    end
  end

  describe "#issuable_params" do
    it 'sets include_subgroups flag by default' do
      expect(results.issuable_params[:include_subgroups]).to eq(true)
    end
  end
end
