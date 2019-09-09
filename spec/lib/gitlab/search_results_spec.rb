# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::SearchResults do
  include ProjectForksHelper
  include SearchHelpers

  let(:user) { create(:user) }
  let!(:project) { create(:project, name: 'foo') }
  let!(:issue) { create(:issue, project: project, title: 'foo') }

  let!(:merge_request) do
    create(:merge_request, source_project: project, title: 'foo')
  end

  let!(:milestone) { create(:milestone, project: project, title: 'foo') }
  let(:results) { described_class.new(user, Project.all, 'foo') }

  context 'as a user with access' do
    before do
      project.add_developer(user)
    end

    describe '#objects' do
      it 'returns without_counts collection by default' do
        expect(results.objects('projects')).to be_kind_of(Kaminari::PaginatableWithoutCount)
      end

      it 'returns with counts collection when requested' do
        expect(results.objects('projects', 1, false)).not_to be_kind_of(Kaminari::PaginatableWithoutCount)
      end
    end

    describe '#formatted_count' do
      using RSpec::Parameterized::TableSyntax

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

    describe '#formatted_limited_count' do
      using RSpec::Parameterized::TableSyntax

      where(:count, :expected) do
        23   | '23'
        100  | '100'
        101  | max_limited_count
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
          create(:milestone, project: project, title: 'foo2')

          expect(results).to receive(:issues).with(public_only: true).and_call_original
          expect(results).not_to receive(:issues).with(no_args).and_call_original

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

      results = described_class.new(user, Project.where(id: forked_project.id), 'foo')

      expect(results.objects('merge_requests')).to include merge_request_2
    end

    describe '#merge_requests' do
      it 'includes project filter by default' do
        expect(results).to receive(:project_ids_relation).and_call_original

        results.objects('merge_requests')
      end

      it 'skips project filter if default project context is used' do
        allow(results).to receive(:default_project_filter).and_return(true)

        expect(results).not_to receive(:project_ids_relation)

        results.objects('merge_requests')
      end
    end

    describe '#issues' do
      it 'includes project filter by default' do
        expect(results).to receive(:project_ids_relation).and_call_original

        results.objects('issues')
      end

      it 'skips project filter if default project context is used' do
        allow(results).to receive(:default_project_filter).and_return(true)

        expect(results).not_to receive(:project_ids_relation)

        results.objects('issues')
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
      results = described_class.new(non_member, limit_projects, query)
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

      results = described_class.new(member, limit_projects, query)
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
      results = described_class.new(author, limit_projects, query)
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
      results = described_class.new(assignee, limit_projects, query)
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

      results = described_class.new(member, limit_projects, query)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).to include security_issue_1
      expect(issues).to include security_issue_2
      expect(issues).to include security_issue_3
      expect(issues).not_to include security_issue_4
      expect(issues).not_to include security_issue_5
      expect(results.limited_issues_count).to eq 4
    end

    it 'lists all issues for admin' do
      results = described_class.new(admin, limit_projects, query)
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

      milestones = described_class.new(user, limit_projects, 'milestone').objects('milestones')

      expect(milestones).to match_array([milestone_1, milestone_2, milestone_3])
    end
  end
end
