# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SearchResults, feature_category: :global_search do
  include ProjectForksHelper
  include SearchHelpers

  let_it_be(:user) { create(:user, username: 'foobar') }
  let_it_be(:project) { create(:project, name: 'foo') }
  let_it_be(:issue) { create(:issue, project: project, title: 'foo') }
  let_it_be(:milestone) { create(:milestone, project: project, title: 'foo') }

  let(:merge_request) { create(:merge_request, source_project: project, title: 'foo') }
  let(:query) { 'foo' }
  let(:filters) { {} }
  let(:sort) { nil }
  let(:limit_projects) { Project.order(:id) }

  subject(:results) { described_class.new(user, query, limit_projects, sort: sort, filters: filters) }

  context 'as a user with access' do
    using RSpec::Parameterized::TableSyntax
    before_all do
      project.add_developer(user)
    end

    describe '#objects' do
      it 'returns without_counts collection by default' do
        expect(results.objects('projects')).to be_kind_of(Kaminari::PaginatableWithoutCount)
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

    describe '#aggregations' do
      where(:scope) do
        %w[blobs commits epics issues merge_requests milestones projects users wiki_blobs unknown]
      end

      with_them do
        it 'returns an empty array' do
          expect(results.aggregations(scope)).to be_empty
        end
      end
    end

    describe '#counts' do
      where(:scope) do
        %w[blobs commits epics issues merge_requests milestones projects users wiki_blobs unknown]
      end

      with_them do
        it 'returns an empty array' do
          expect(results.counts(scope)).to be_empty
        end
      end
    end

    context 'when count_limit is lower than total amount' do
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

          expect(results).to receive(:issues).with(confidential: false).and_call_original
          expect(results).not_to receive(:issues).with(no_args)

          expect(results.limited_issues_count).to eq(1)
        end
      end
    end

    context 'when count_limit is higher than total amount' do
      describe '#limited_issues_count' do
        it 'runs multiple queries to get the limited amount of issues' do
          expect(results).to receive(:issues).with(confidential: false).and_call_original
          expect(results).to receive(:issues).with(no_args).and_call_original

          expect(results.limited_issues_count).to eq(1)
        end
      end
    end

    it 'does not include merge requests from source projects' do
      forked_project = fork_project(project, user)
      merge_request_2 = create(:merge_request, target_project: project, source_project: forked_project, title: 'foo')

      results = described_class.new(user, 'foo', Project.where(id: forked_project.id))

      expect(results.objects('merge_requests')).not_to include merge_request_2
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

      context 'with filtering' do
        let_it_be(:closed_result) { create(:closed_merge_request, source_project: project, title: 'foo') }
        let_it_be(:opened_result) { create(:reopened_merge_request, source_project: project, title: 'foo') }
        let_it_be(:archived_project) { create(:project, :public, :archived) }
        let_it_be(:unarchived_project) { create(:project, :public) }
        let_it_be(:archived_result) { create(:merge_request, source_project: archived_project, title: 'foo') }
        let_it_be(:unarchived_result) { create(:merge_request, source_project: unarchived_project, title: 'foo') }
        let_it_be(:query) { 'foo' }

        include_examples 'search results filtered by state'
        include_examples 'search results filtered by archived'
      end

      context 'with ordering' do
        let_it_be(:old_result) do
          create(:reopened_merge_request, source_project: project, source_branch: 'b1', title: 'sorted old',
            created_at: 1.month.ago)
        end

        let_it_be(:new_result) do
          create(:reopened_merge_request, source_project: project, source_branch: 'b2', title: 'sorted recent',
            created_at: 1.day.ago)
        end

        let_it_be(:very_old_result) do
          create(:reopened_merge_request, source_project: project, source_branch: 'b3', title: 'sorted very old',
            created_at: 1.year.ago)
        end

        let_it_be(:old_updated) do
          create(:reopened_merge_request, source_project: project, source_branch: 'b4', title: 'updated old',
            updated_at: 1.month.ago)
        end

        let_it_be(:new_updated) do
          create(:reopened_merge_request, source_project: project, source_branch: 'b5', title: 'updated recent',
            updated_at: 1.day.ago)
        end

        let_it_be(:very_old_updated) do
          create(:reopened_merge_request, source_project: project, source_branch: 'b6', title: 'updated very old',
            updated_at: 1.year.ago)
        end

        include_examples 'search results sorted' do
          let(:results_created) do
            described_class.new(user, 'sorted', Project.order(:id), sort: sort, filters: filters)
          end

          let(:results_updated) do
            described_class.new(user, 'updated', Project.order(:id), sort: sort, filters: filters)
          end
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

      context 'with filtering' do
        let_it_be(:closed_result) { create(:issue, :closed, project: project, title: 'foo closed') }
        let_it_be(:opened_result) { create(:issue, :opened, project: project, title: 'foo open') }
        let_it_be(:confidential_result) { create(:issue, :confidential, project: project, title: 'foo confidential') }
        let_it_be(:unarchived_project) { project }
        let_it_be(:archived_project) { create(:project, :public, :archived) }
        let_it_be(:unarchived_result) { create(:issue, project: unarchived_project, title: 'foo unarchived') }
        let_it_be(:archived_result) { create(:issue, project: archived_project, title: 'foo archived') }

        include_examples 'search results filtered by state'
        include_examples 'search results filtered by confidential'
        include_examples 'search results filtered by archived'
      end

      context 'with ordering' do
        let_it_be(:old_result) { create(:issue, project: project, title: 'sorted old', created_at: 1.month.ago) }
        let_it_be(:new_result) { create(:issue, project: project, title: 'sorted recent', created_at: 1.day.ago) }
        let_it_be(:very_old_result) { create(:issue, project: project, title: 'sorted old2', created_at: 1.year.ago) }

        let_it_be(:old_updated) { create(:issue, project: project, title: 'updated old', updated_at: 1.month.ago) }
        let_it_be(:new_updated) { create(:issue, project: project, title: 'updated recent', updated_at: 1.day.ago) }
        let_it_be(:very_old_updated) { create(:issue, project: project, title: 'updated old2', updated_at: 1.year.ago) }

        let_it_be(:less_popular_result) { create(:issue, project: project, title: 'less popular', upvotes_count: 10) }
        let_it_be(:popular_result) { create(:issue, project: project, title: 'popular', upvotes_count: 100) }
        let_it_be(:non_popular_result) { create(:issue, project: project, title: 'non popular', upvotes_count: 1) }

        include_examples 'search results sorted' do
          let(:results_created) do
            described_class.new(user, 'sorted', Project.order(:id), sort: sort, filters: filters)
          end

          let(:results_updated) do
            described_class.new(user, 'updated', Project.order(:id), sort: sort, filters: filters)
          end
        end

        include_examples 'search results sorted by popularity' do
          let(:results_popular) do
            described_class.new(user, 'popular', Project.order(:id), sort: sort, filters: filters)
          end
        end
      end
    end

    describe '#projects' do
      let(:scope) { 'projects' }
      let(:query) { 'Test' }

      describe 'filtering' do
        let_it_be(:group) { create(:group, name: 'my-group') }
        let_it_be(:unarchived_result) { create(:project, :public, group: group, name: 'Test1') }
        let_it_be(:archived_result) { create(:project, :archived, :public, group: group, name: 'Test2') }

        it_behaves_like 'search results filtered by archived'

        it 'returns the project' do
          expect(results.objects('projects')).to eq([unarchived_result])
        end

        context 'when the query is Gitlab::Search::Params::MIN_TERM_LENGTH characters long' do
          let(:query) { 'Te' }

          it 'returns the project' do
            expect(results.objects('projects')).to eq([unarchived_result])
          end
        end

        context 'when the query is less than Gitlab::Search::Params::MIN_TERM_LENGTH characters long' do
          let(:query) { 'T' }

          it 'does not return the project' do
            expect(results.objects('projects')).not_to eq([unarchived_result])
          end
        end

        context 'when the query does not match the project name but it matches the group name' do
          let(:query) { 'group' }

          it 'returns the project' do
            expect(results.objects('projects')).to eq([unarchived_result])
          end
        end
      end
    end

    describe '#users' do
      subject(:user_search_result) { results.objects('users') }

      let_it_be(:another_user) { create(:user, username: 'barfoo') }
      let_it_be(:parent_group) { create(:group) }
      let_it_be(:group) { create(:group, parent: parent_group) }

      it 'does not call the UsersFinder when the current_user is not allowed to read users list' do
        allow(Ability).to receive(:allowed?).and_return(false)

        expect(UsersFinder).not_to receive(:new)

        user_search_result
      end

      it 'calls the UsersFinder' do
        expected_params = { search: 'foo', use_minimum_char_limit: false }

        expect(UsersFinder).to receive(:new).with(user, expected_params).and_call_original

        user_search_result
      end

      context 'when the autocomplete filter is added' do
        let(:filters) { { autocomplete: true } }

        shared_examples 'returns users' do
          it 'returns the current_user since they match the query' do
            expect(user_search_result).to match_array(user)
          end

          context 'when another user belongs to a project the current_user belongs to' do
            before_all do
              project.add_developer(another_user)
            end

            it 'includes the other user' do
              expect(user_search_result).to match_array([user, another_user])
            end
          end

          context 'when another user belongs to a group' do
            before_all do
              group.add_developer(another_user)
            end

            it 'does not include the other user' do
              expect(user_search_result).not_to include(another_user)
            end

            context 'when the current_user also belongs to that group' do
              before_all do
                group.add_developer(user)
              end

              it 'includes the other user' do
                expect(user_search_result).to match_array([user, another_user])
              end
            end

            context 'when the current_user belongs to a parent of the group' do
              before_all do
                parent_group.add_developer(user)
              end

              it 'includes the other user' do
                expect(user_search_result).to match_array([user, another_user])
              end
            end

            context 'when the current_user belongs to a group that is shared by the group' do
              let_it_be_with_reload(:shared_with_group) { create(:group) }
              let_it_be_with_reload(:group_group_link) do
                create(:group_group_link,
                  group_access: ::Gitlab::Access::GUEST,
                  shared_group: group,
                  shared_with_group: shared_with_group
                )
              end

              before_all do
                shared_with_group.add_developer(user)
              end

              it 'includes the other user' do
                expect(user_search_result).to match_array([user, another_user])
              end
            end

            context 'when the current_user belongs to a child of the group' do
              let_it_be(:child_group) { create(:group, parent: group) }

              before_all do
                child_group.add_developer(user)
              end

              it 'includes the other user' do
                expect(user_search_result).to match_array([user, another_user])
              end
            end
          end

          context 'when another user is a guest of a private group' do
            let_it_be(:public_parent_group) { create(:group, :public) }
            let_it_be(:private_group) { create(:group, :private, parent: public_parent_group) }

            before_all do
              private_group.add_guest(another_user)
            end

            it 'does not include the other user' do
              expect(user_search_result).to match_array(user)
            end

            context 'when the current_user is a guest of the private group' do
              before_all do
                private_group.add_guest(user)
              end

              it 'includes the other user' do
                expect(user_search_result).to match_array([user, another_user])
              end
            end

            context 'when the current_user is a guest of the public parent of the private group' do
              before_all do
                public_parent_group.add_guest(user)
              end

              it 'includes the other user' do
                expect(user_search_result).to match_array([user, another_user])
              end
            end
          end
        end

        include_examples 'returns users'
      end
    end
  end

  it 'does not list issues on private projects' do
    private_project = create(:project, :private)
    issue = create(:issue, project: private_project, title: 'foo')

    expect(results.objects('issues')).not_to include issue
  end

  describe 'confidential issues' do
    let_it_be(:project_1) { create(:project, :internal) }
    let_it_be(:project_2) { create(:project, :internal) }
    let_it_be(:project_3) { create(:project, :internal) }
    let_it_be(:project_4) { create(:project, :internal) }
    let_it_be(:query) { 'foo' }
    let_it_be(:limit_projects) { Project.id_in([project_1.id, project_2.id, project_3.id]) }
    let_it_be(:author) { create(:user) }
    let_it_be(:assignee) { create(:user) }
    let_it_be(:non_member) { create(:user) }
    let_it_be(:member) { create(:user) }
    let_it_be(:admin) { create(:admin) }
    let_it_be(:issue) { create(:issue, project: project_1, title: 'foo') }
    let_it_be(:hidden_issue1) { create(:issue, :confidential, project: project_1, title: 'foo', author: author) }
    let_it_be(:hidden_issue2) { create(:issue, :confidential, title: 'foo', project: project_1, assignees: [assignee]) }
    let_it_be(:hidden_issue3) { create(:issue, :confidential, project: project_2, title: 'foo', author: author) }
    let_it_be(:hidden_issue4) { create(:issue, :confidential, project: project_3, title: 'foo', assignees: [assignee]) }
    let_it_be(:hidden_issue5) { create(:issue, :confidential, project: project_4, title: 'foo') }

    it 'does not list confidential issues for non project members' do
      results = described_class.new(non_member, query, limit_projects)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).not_to include(hidden_issue1, hidden_issue2, hidden_issue3, hidden_issue4, hidden_issue5)
      expect(results.limited_issues_count).to eq 1
    end

    it 'does not list confidential issues for project members with guest role' do
      project_1.add_guest(member)
      project_2.add_guest(member)

      results = described_class.new(member, query, limit_projects)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).not_to include(hidden_issue1, hidden_issue2, hidden_issue3, hidden_issue4, hidden_issue5)
      expect(results.limited_issues_count).to eq 1
    end

    it 'lists confidential issues for author' do
      results = described_class.new(author, query, limit_projects)
      issues = results.objects('issues')

      expect(issues).to include(issue, hidden_issue1, hidden_issue3)
      expect(issues).not_to include(hidden_issue2, hidden_issue4, hidden_issue5)
      expect(results.limited_issues_count).to eq 3
    end

    it 'lists confidential issues for assignee' do
      results = described_class.new(assignee, query, limit_projects)
      issues = results.objects('issues')

      expect(issues).to include(issue, hidden_issue2, hidden_issue4)
      expect(issues).not_to include(hidden_issue1, hidden_issue3, hidden_issue5)
      expect(results.limited_issues_count).to eq 3
    end

    it 'lists confidential issues for project members' do
      project_1.add_developer(member)
      project_2.add_developer(member)

      results = described_class.new(member, query, limit_projects)
      issues = results.objects('issues')

      expect(issues).to include(issue, hidden_issue1, hidden_issue2, hidden_issue3)
      expect(issues).not_to include(hidden_issue4, hidden_issue5)
      expect(results.limited_issues_count).to eq 4
    end

    context 'with admin user' do
      context 'when admin mode enabled', :enable_admin_mode do
        it 'lists all issues' do
          results = described_class.new(admin, query, limit_projects)
          issues = results.objects('issues')

          expect(issues).to include(issue, hidden_issue1, hidden_issue2, hidden_issue3, hidden_issue4)
          expect(issues).not_to include(hidden_issue5)
          expect(results.limited_issues_count).to eq 5
        end
      end

      context 'when admin mode disabled' do
        it 'does not list confidential issues' do
          results = described_class.new(admin, query, limit_projects)
          issues = results.objects('issues')

          expect(issues).to include issue
          expect(issues).not_to include(hidden_issue1, hidden_issue2, hidden_issue3, hidden_issue4, hidden_issue5)
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

  context 'for milestones' do
    let_it_be(:archived_project) { create(:project, :public, :archived) }
    let_it_be(:private_project_1) { create(:project, :private) }
    let_it_be(:private_project_2) { create(:project, :private) }
    let_it_be(:internal_project) { create(:project, :internal) }
    let_it_be(:public_project_1) { create(:project, :public) }
    let_it_be(:public_project_2) { create(:project, :public, :issues_disabled, :merge_requests_disabled) }
    let_it_be(:hidden_milestone_1) { create(:milestone, project: private_project_2, title: 'milestone 1') }
    let_it_be(:hidden_milestone_2) { create(:milestone, project: public_project_2, title: 'milestone 2') }
    let_it_be(:hidden_milestone_3) { create(:milestone, project: archived_project, title: 'Milestone 3') }
    let_it_be(:milestone_1) { create(:milestone, :closed, project: private_project_1, title: 'milestone 4') }
    let_it_be(:milestone_2) { create(:milestone, project: internal_project, title: 'milestone 5') }
    let_it_be(:milestone_3) { create(:milestone, project: public_project_1, title: 'milestone 6') }

    let(:unarchived_result) { milestone_1 }
    let(:archived_result) { hidden_milestone_3 }
    let(:limit_projects) { ProjectsFinder.new(current_user: user).execute }
    let(:query) { 'milestone' }
    let(:scope) { 'milestones' }

    before_all do
      private_project_1.add_developer(user)
    end

    it 'returns correct set of milestones' do
      expect(results.objects(scope)).to match_array([milestone_1, milestone_2, milestone_3])
    end

    include_examples 'search results filtered by archived'
  end
end
