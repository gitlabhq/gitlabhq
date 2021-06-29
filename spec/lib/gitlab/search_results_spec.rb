# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SearchResults do
  include ProjectForksHelper
  include SearchHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, name: 'foo') }
  let_it_be(:issue) { create(:issue, project: project, title: 'foo') }
  let_it_be(:milestone) { create(:milestone, project: project, title: 'foo') }

  let(:merge_request) { create(:merge_request, source_project: project, title: 'foo') }
  let(:query) { 'foo' }
  let(:filters) { {} }
  let(:sort) { nil }

  subject(:results) { described_class.new(user, query, Project.order(:id), sort: sort, filters: filters) }

  context 'as a user with access' do
    before do
      project.add_developer(user)
    end

    describe '#objects' do
      it 'returns without_counts collection by default' do
        expect(results.objects('projects')).to be_kind_of(Kaminari::PaginatableWithoutCount)
      end

      it 'returns with counts collection when requested' do
        expect(results.objects('projects', page: 1, per_page: 1, without_count: false)).not_to be_kind_of(Kaminari::PaginatableWithoutCount)
      end

      it 'uses page and per_page to paginate results' do
        project2 = create(:project, name: 'foo')

        expect(results.objects('projects', page: 1, per_page: 1).to_a).to eq([project])
        expect(results.objects('projects', page: 2, per_page: 1).to_a).to eq([project2])
        expect(results.objects('projects', page: 1, per_page: 2).count).to eq(2)
      end
    end

    describe '#formatted_count' do
      where(:scope, :count_method, :expected) do
        'projects'       | :limited_projects_count       | max_limited_count
        'issues'         | :limited_issues_count         | max_limited_count
        'merge_requests' | :limited_merge_requests_count | max_limited_count
        'milestones'     | :limited_milestones_count     | max_limited_count
        'users'          | :limited_users_count          | max_limited_count
        'unknown'        | nil                           | nil
      end

      with_them do
        it 'returns the expected formatted count' do
          expect(results).to receive(count_method).and_return(1234) if count_method
          expect(results.formatted_count(scope)).to eq(expected)
        end
      end
    end

    describe '#highlight_map' do
      where(:scope, :expected) do
        'projects'       | {}
        'issues'         | {}
        'merge_requests' | {}
        'milestones'     | {}
        'users'          | {}
        'unknown'        | {}
      end

      with_them do
        it 'returns the expected highlight_map' do
          expect(results.highlight_map(scope)).to eq(expected)
        end
      end
    end

    describe '#formatted_limited_count' do
      where(:count, :expected) do
        23   | '23'
        99   | '99'
        100  | max_limited_count
        1234 | max_limited_count
      end

      with_them do
        it 'returns the expected formatted limited count' do
          expect(results.formatted_limited_count(count)).to eq(expected)
        end
      end
    end

    context "when count_limit is lower than total amount" do
      before do
        allow(results).to receive(:count_limit).and_return(1)
      end

      describe '#limited_projects_count' do
        it 'returns the limited amount of projects' do
          create(:project, name: 'foo2')

          expect(results.limited_projects_count).to eq(1)
        end
      end

      describe '#limited_merge_requests_count' do
        it 'returns the limited amount of merge requests' do
          create(:merge_request, :simple, source_project: project, title: 'foo2')

          expect(results.limited_merge_requests_count).to eq(1)
        end
      end

      describe '#limited_milestones_count' do
        it 'returns the limited amount of milestones' do
          create(:milestone, project: project, title: 'foo2')

          expect(results.limited_milestones_count).to eq(1)
        end
      end

      describe '#limited_issues_count' do
        it 'runs single SQL query to get the limited amount of issues' do
          create(:issue, project: project, title: 'foo2')

          expect(results).to receive(:issues).with(public_only: true).and_call_original
          expect(results).not_to receive(:issues).with(no_args)

          expect(results.limited_issues_count).to eq(1)
        end
      end
    end

    context "when count_limit is higher than total amount" do
      describe '#limited_issues_count' do
        it 'runs multiple queries to get the limited amount of issues' do
          expect(results).to receive(:issues).with(public_only: true).and_call_original
          expect(results).to receive(:issues).with(no_args).and_call_original

          expect(results.limited_issues_count).to eq(1)
        end
      end
    end

    it 'includes merge requests from source and target projects' do
      forked_project = fork_project(project, user)
      merge_request_2 = create(:merge_request, target_project: project, source_project: forked_project, title: 'foo')

      results = described_class.new(user, 'foo', Project.where(id: forked_project.id))

      expect(results.objects('merge_requests')).to include merge_request_2
    end

    describe '#merge_requests' do
      let(:scope) { 'merge_requests' }

      it 'includes project filter by default' do
        expect(results).to receive(:project_ids_relation).and_call_original

        results.objects(scope)
      end

      it 'skips project filter if default project context is used' do
        allow(results).to receive(:default_project_filter).and_return(true)

        expect(results).not_to receive(:project_ids_relation)

        results.objects(scope)
      end

      context 'filtering' do
        let!(:opened_result) { create(:merge_request, :opened, source_project: project, title: 'foo opened') }
        let!(:closed_result) { create(:merge_request, :closed, source_project: project, title: 'foo closed') }
        let(:query) { 'foo' }

        include_examples 'search results filtered by state'
      end

      context 'ordering' do
        let!(:old_result) { create(:merge_request, :opened, source_project: project, source_branch: 'old-1', title: 'sorted old', created_at: 1.month.ago) }
        let!(:new_result) { create(:merge_request, :opened, source_project: project, source_branch: 'new-1', title: 'sorted recent', created_at: 1.day.ago) }
        let!(:very_old_result) { create(:merge_request, :opened, source_project: project, source_branch: 'very-old-1', title: 'sorted very old', created_at: 1.year.ago) }

        let!(:old_updated) { create(:merge_request, :opened, source_project: project, source_branch: 'updated-old-1', title: 'updated old', updated_at: 1.month.ago) }
        let!(:new_updated) { create(:merge_request, :opened, source_project: project, source_branch: 'updated-new-1', title: 'updated recent', updated_at: 1.day.ago) }
        let!(:very_old_updated) { create(:merge_request, :opened, source_project: project, source_branch: 'updated-very-old-1', title: 'updated very old', updated_at: 1.year.ago) }

        include_examples 'search results sorted' do
          let(:results_created) { described_class.new(user, 'sorted', Project.order(:id), sort: sort, filters: filters) }
          let(:results_updated) { described_class.new(user, 'updated', Project.order(:id), sort: sort, filters: filters) }
        end
      end
    end

    describe '#issues' do
      let(:scope) { 'issues' }

      it 'includes project filter by default' do
        expect(results).to receive(:project_ids_relation).and_call_original

        results.objects(scope)
      end

      it 'skips project filter if default project context is used' do
        allow(results).to receive(:default_project_filter).and_return(true)

        expect(results).not_to receive(:project_ids_relation)

        results.objects(scope)
      end

      context 'filtering' do
        let_it_be(:closed_result) { create(:issue, :closed, project: project, title: 'foo closed') }
        let_it_be(:opened_result) { create(:issue, :opened, project: project, title: 'foo open') }
        let_it_be(:confidential_result) { create(:issue, :confidential, project: project, title: 'foo confidential') }

        include_examples 'search results filtered by state'
        include_examples 'search results filtered by confidential'
      end

      context 'ordering' do
        let!(:old_result) { create(:issue, project: project, title: 'sorted old', created_at: 1.month.ago) }
        let!(:new_result) { create(:issue, project: project, title: 'sorted recent', created_at: 1.day.ago) }
        let!(:very_old_result) { create(:issue, project: project, title: 'sorted very old', created_at: 1.year.ago) }

        let!(:old_updated) { create(:issue, project: project, title: 'updated old', updated_at: 1.month.ago) }
        let!(:new_updated) { create(:issue, project: project, title: 'updated recent', updated_at: 1.day.ago) }
        let!(:very_old_updated) { create(:issue, project: project, title: 'updated very old', updated_at: 1.year.ago) }

        include_examples 'search results sorted' do
          let(:results_created) { described_class.new(user, 'sorted', Project.order(:id), sort: sort, filters: filters) }
          let(:results_updated) { described_class.new(user, 'updated', Project.order(:id), sort: sort, filters: filters) }
        end
      end
    end

    describe '#users' do
      it 'does not call the UsersFinder when the current_user is not allowed to read users list' do
        allow(Ability).to receive(:allowed?).and_return(false)

        expect(UsersFinder).not_to receive(:new).with(user, search: 'foo').and_call_original

        results.objects('users')
      end

      it 'calls the UsersFinder' do
        expect(UsersFinder).to receive(:new).with(user, search: 'foo').and_call_original

        results.objects('users')
      end
    end
  end

  it 'does not list issues on private projects' do
    private_project = create(:project, :private)
    issue = create(:issue, project: private_project, title: 'foo')

    expect(results.objects('issues')).not_to include issue
  end

  describe 'confidential issues' do
    let(:project_1) { create(:project, :internal) }
    let(:project_2) { create(:project, :internal) }
    let(:project_3) { create(:project, :internal) }
    let(:project_4) { create(:project, :internal) }
    let(:query) { 'issue' }
    let(:limit_projects) { Project.where(id: [project_1.id, project_2.id, project_3.id]) }
    let(:author) { create(:user) }
    let(:assignee) { create(:user) }
    let(:non_member) { create(:user) }
    let(:member) { create(:user) }
    let(:admin) { create(:admin) }
    let!(:issue) { create(:issue, project: project_1, title: 'Issue 1') }
    let!(:security_issue_1) { create(:issue, :confidential, project: project_1, title: 'Security issue 1', author: author) }
    let!(:security_issue_2) { create(:issue, :confidential, title: 'Security issue 2', project: project_1, assignees: [assignee]) }
    let!(:security_issue_3) { create(:issue, :confidential, project: project_2, title: 'Security issue 3', author: author) }
    let!(:security_issue_4) { create(:issue, :confidential, project: project_3, title: 'Security issue 4', assignees: [assignee]) }
    let!(:security_issue_5) { create(:issue, :confidential, project: project_4, title: 'Security issue 5') }

    it 'does not list confidential issues for non project members' do
      results = described_class.new(non_member, query, limit_projects)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).not_to include security_issue_1
      expect(issues).not_to include security_issue_2
      expect(issues).not_to include security_issue_3
      expect(issues).not_to include security_issue_4
      expect(issues).not_to include security_issue_5
      expect(results.limited_issues_count).to eq 1
    end

    it 'does not list confidential issues for project members with guest role' do
      project_1.add_guest(member)
      project_2.add_guest(member)

      results = described_class.new(member, query, limit_projects)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).not_to include security_issue_1
      expect(issues).not_to include security_issue_2
      expect(issues).not_to include security_issue_3
      expect(issues).not_to include security_issue_4
      expect(issues).not_to include security_issue_5
      expect(results.limited_issues_count).to eq 1
    end

    it 'lists confidential issues for author' do
      results = described_class.new(author, query, limit_projects)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).to include security_issue_1
      expect(issues).not_to include security_issue_2
      expect(issues).to include security_issue_3
      expect(issues).not_to include security_issue_4
      expect(issues).not_to include security_issue_5
      expect(results.limited_issues_count).to eq 3
    end

    it 'lists confidential issues for assignee' do
      results = described_class.new(assignee, query, limit_projects)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).not_to include security_issue_1
      expect(issues).to include security_issue_2
      expect(issues).not_to include security_issue_3
      expect(issues).to include security_issue_4
      expect(issues).not_to include security_issue_5
      expect(results.limited_issues_count).to eq 3
    end

    it 'lists confidential issues for project members' do
      project_1.add_developer(member)
      project_2.add_developer(member)

      results = described_class.new(member, query, limit_projects)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).to include security_issue_1
      expect(issues).to include security_issue_2
      expect(issues).to include security_issue_3
      expect(issues).not_to include security_issue_4
      expect(issues).not_to include security_issue_5
      expect(results.limited_issues_count).to eq 4
    end

    context 'with admin user' do
      context 'when admin mode enabled', :enable_admin_mode do
        it 'lists all issues' do
          results = described_class.new(admin, query, limit_projects)
          issues = results.objects('issues')

          expect(issues).to include issue
          expect(issues).to include security_issue_1
          expect(issues).to include security_issue_2
          expect(issues).to include security_issue_3
          expect(issues).to include security_issue_4
          expect(issues).not_to include security_issue_5
          expect(results.limited_issues_count).to eq 5
        end
      end

      context 'when admin mode disabled' do
        it 'does not list confidential issues' do
          results = described_class.new(admin, query, limit_projects)
          issues = results.objects('issues')

          expect(issues).to include issue
          expect(issues).not_to include security_issue_1
          expect(issues).not_to include security_issue_2
          expect(issues).not_to include security_issue_3
          expect(issues).not_to include security_issue_4
          expect(issues).not_to include security_issue_5
          expect(results.limited_issues_count).to eq 1
        end
      end
    end
  end

  it 'does not list merge requests on projects with limited access' do
    project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
    project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)

    expect(results.objects('merge_requests')).not_to include merge_request
  end

  context 'milestones' do
    it 'returns correct set of milestones' do
      private_project_1 = create(:project, :private)
      private_project_2 = create(:project, :private)
      internal_project = create(:project, :internal)
      public_project_1 = create(:project, :public)
      public_project_2 = create(:project, :public, :issues_disabled, :merge_requests_disabled)
      private_project_1.add_developer(user)
      # milestones that should not be visible
      create(:milestone, project: private_project_2, title: 'Private project without access milestone')
      create(:milestone, project: public_project_2, title: 'Public project with milestones disabled milestone')
      # milestones that should be visible
      milestone_1 = create(:milestone, project: private_project_1, title: 'Private project with access milestone', state: 'closed')
      milestone_2 = create(:milestone, project: internal_project, title: 'Internal project milestone')
      milestone_3 = create(:milestone, project: public_project_1, title: 'Public project with milestones enabled milestone')
      # Global search scope takes user authorized projects, internal projects and public projects.
      limit_projects = ProjectsFinder.new(current_user: user).execute

      milestones = described_class.new(user, 'milestone', limit_projects).objects('milestones')

      expect(milestones).to match_array([milestone_1, milestone_2, milestone_3])
    end
  end
end
