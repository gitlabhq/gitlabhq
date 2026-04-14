# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestPolicy, feature_category: :code_review_workflow do
  include ExternalAuthorizationServiceHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:guest) { create(:user) }
  let_it_be(:author) { create(:user) }
  let_it_be(:planner) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:non_team_member) { create(:user) }
  let_it_be(:bot) { create(:user, :project_bot) }

  subject(:policy) { described_class.new(user, merge_request) }

  # :permission, :is_allowed
  def permission_table_for_guest
    :read_merge_request            | true
    :create_todo                   | true
    :create_note                   | true
    :update_subscription           | true
    :create_merge_request_in       | true
    :create_merge_request_from     | false
    :approve_merge_request         | false
    :update_merge_request          | false
    :reset_merge_request_approvals | false
    :mark_note_as_internal         | false
  end

  # :permission, :is_allowed
  def permission_table_for_reporter
    :read_merge_request            | true
    :create_todo                   | true
    :create_note                   | true
    :update_subscription           | true
    :create_merge_request_in       | true
    :create_merge_request_from     | false
    :approve_merge_request         | false
    :update_merge_request          | false
    :reset_merge_request_approvals | false
    :mark_note_as_internal         | true
  end

  # :permission, :is_allowed
  def permission_table_for_planner(public_merge_request: false)
    :read_merge_request            | true
    :create_todo                   | true
    :create_note                   | true
    :update_subscription           | true
    :create_merge_request_in       | public_merge_request
    :create_merge_request_from     | false
    :approve_merge_request         | false
    :update_merge_request          | false
    :reset_merge_request_approvals | false
    :mark_note_as_internal         | true
  end

  mr_perms = %i[create_merge_request_in
    create_merge_request_from
    read_merge_request
    update_merge_request
    create_todo
    approve_merge_request
    create_note
    update_subscription
    mark_note_as_internal].freeze

  shared_examples_for 'a denied user' do
    it { expect_disallowed(*mr_perms) }
  end

  shared_examples_for 'a user with full access' do
    it { expect_allowed(*mr_perms) }
  end

  shared_examples_for 'a user with limited access' do
    where(:permission, :is_allowed) do
      permission_table
    end

    with_them do
      specify do
        is_allowed ? expect_allowed(permission) : expect_disallowed(permission)
      end
    end
  end

  context 'when user is a direct project member' do
    let(:project) { create(:project, :public) }

    before do
      project.add_guest(guest)
      project.add_guest(author)
      project.add_planner(planner)
      project.add_developer(developer)
      project.add_developer(bot)
    end

    context 'when merge request is public' do
      let(:merge_request) { create(:merge_request, source_project: project, target_project: project, author: author) }

      context 'and user is author' do
        let(:author) { user }

        context 'and the user is a guest' do
          let(:user) { guest }

          it { expect_allowed(:update_merge_request) }
          it { expect_allowed(:reopen_merge_request) }
          it { expect_allowed(:approve_merge_request) }
          it { expect_disallowed(:reset_merge_request_approvals) }
        end

        context 'and the user is a planner' do
          let(:user) { planner }

          it { expect_allowed(:update_merge_request) }
          it { expect_allowed(:reopen_merge_request) }
          it { expect_allowed(:approve_merge_request) }
          it { expect_allowed(:mark_note_as_internal) }
          it { expect_disallowed(:reset_merge_request_approvals) }
        end

        context 'and the user is a bot' do
          let(:user) { bot }

          it do
            expect_allowed(:reset_merge_request_approvals)
          end
        end
      end

      context 'and user is not author' do
        describe 'a guest' do
          let(:permission_table) { permission_table_for_guest }
          let(:user) { guest }

          it_behaves_like 'a user with limited access'
        end

        describe 'a planner' do
          let(:permission_table) { permission_table_for_planner(public_merge_request: true) }
          let(:user) { planner }

          it_behaves_like 'a user with limited access'
        end
      end

      context 'with private project' do
        let_it_be(:project) { create(:project, :private) }

        context 'when the user is a guest' do
          let(:user) { guest }

          it_behaves_like 'a denied user'
        end

        context 'when the user is a planner' do
          let(:permission_table) { permission_table_for_planner }
          let(:user) { planner }

          it_behaves_like 'a user with limited access'
        end
      end
    end

    context 'when merge requests have been disabled' do
      let!(:merge_request) { create(:merge_request, source_project: project, target_project: project, author: author) }

      before do
        project.project_feature.update!(merge_requests_access_level: ProjectFeature::DISABLED)
      end

      context 'for the author' do
        let(:user) { author }

        it_behaves_like 'a denied user'
      end

      context 'for a guest' do
        let(:user) { guest }

        it_behaves_like 'a denied user'
      end

      context 'for a planner' do
        let(:user) { planner }

        it_behaves_like 'a denied user'
      end

      context 'for a developer' do
        let(:user) { developer }

        it_behaves_like 'a denied user'
      end

      context 'for a bot' do
        let(:user) { bot }

        it do
          expect_disallowed(:reset_merge_request_approvals)
        end
      end
    end

    context 'when merge requests are private' do
      let!(:merge_request) { create(:merge_request, source_project: project, target_project: project, author: author) }

      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
      end

      context 'for the author' do
        let(:user) { author }

        it_behaves_like 'a denied user'
      end

      context 'for a planner' do
        let(:user) { planner }

        it_behaves_like 'a denied user'
      end

      context 'for a developer' do
        let(:user) { developer }

        it_behaves_like 'a user with full access'
      end

      context 'for a bot' do
        let(:user) { bot }

        it do
          expect_allowed(:reset_merge_request_approvals)
        end
      end
    end

    context 'when merge request is unlocked' do
      let(:merge_request) do
        create(:merge_request, :closed, source_project: project, target_project: project, author: author)
      end

      context 'with author' do
        let(:user) { author }

        it { expect_allowed(:reopen_merge_request) }
      end

      context 'with developer' do
        let(:user) { developer }

        it { expect_allowed(:reopen_merge_request) }
      end

      context 'with planner' do
        let(:user) { planner }

        it { expect_disallowed(:reopen_merge_request) }
      end

      context 'with guest' do
        let(:user) { guest }

        it { expect_disallowed(:reopen_merge_request) }
      end
    end

    context 'when merge request is locked' do
      let(:merge_request) do
        create(:merge_request, :closed, discussion_locked: true, source_project: project, target_project: project,
          author: author)
      end

      context 'with author' do
        let(:user) { author }

        it { expect_disallowed(:reopen_merge_request) }
      end

      context 'with developer' do
        let(:user) { developer }

        it { expect_disallowed(:reopen_merge_request) }
      end

      context 'with planner' do
        let(:user) { planner }

        it { expect_disallowed(:reopen_merge_request) }
      end

      context 'with guest' do
        let(:user) { guest }

        it { expect_disallowed(:reopen_merge_request) }
      end

      context 'when the user is project member, with at least guest access' do
        let(:user) { guest }

        it { expect_allowed(:create_note) }
      end
    end

    context 'with external authorization enabled' do
      let(:user) { create(:user) }
      let(:project) { create(:project, :public) }
      let(:merge_request) { create(:merge_request, source_project: project) }

      before do
        enable_external_authorization_service_check
      end

      it 'can read the issue iid without accessing the external service' do
        expect(::Gitlab::ExternalAuthorization).not_to receive(:access_allowed?)

        expect_allowed(:read_merge_request_iid)
      end
    end
  end

  context 'when user is an inherited member from the parent group' do
    let_it_be(:group) { create(:group, :public) }

    let(:merge_request) { create(:merge_request, source_project: project, target_project: project, author: author) }

    before_all do
      group.add_guest(guest)
      group.add_guest(author)
      group.add_planner(planner)
      group.add_reporter(reporter)
      group.add_developer(developer)
      group.add_developer(bot)
    end

    context 'when the project is public' do
      let(:project) { create(:project, :public, group: group) }

      context 'when the user is the merge request author' do
        let(:user) { author }

        it do
          expect_allowed(:approve_merge_request)
        end

        it do
          expect_disallowed(:reset_merge_request_approvals)
        end
      end

      context 'for a bot' do
        let(:user) { bot }

        it do
          expect_allowed(:approve_merge_request)
        end

        it do
          expect_allowed(:reset_merge_request_approvals)
        end
      end

      context 'for a planner' do
        let(:permission_table) { permission_table_for_reporter } # same as reporter because MR is public
        let(:user) { planner }

        it_behaves_like 'a user with limited access'
      end

      context 'for a reporter' do
        let(:permission_table) { permission_table_for_reporter }
        let(:user) { reporter }

        it_behaves_like 'a user with limited access'
      end

      context 'and merge requests are private' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
        end

        context 'for a guest' do
          let(:user) { guest }

          it_behaves_like 'a denied user'
        end

        context 'for a planner' do
          let(:user) { planner }

          it_behaves_like 'a denied user'
        end

        context 'for a reporter' do
          let(:permission_table) { permission_table_for_reporter }
          let(:user) { reporter }

          it_behaves_like 'a user with limited access'
        end

        describe 'for a developer' do
          let(:user) { developer }

          it_behaves_like 'a user with full access'
        end

        describe 'for a bot' do
          let(:user) { bot }

          it do
            expect_allowed(:reset_merge_request_approvals)
          end
        end
      end
    end

    context 'when project is private' do
      let(:project) { create(:project, :private, group: group) }

      describe 'a guest' do
        let(:user) { guest }

        it_behaves_like 'a denied user'
      end

      context 'for a planner' do
        let(:permission_table) { permission_table_for_planner }
        let(:user) { planner }

        it_behaves_like 'a user with limited access'
      end

      describe 'for a reporter' do
        let(:permission_table) { permission_table_for_reporter }
        let(:user) { reporter }

        it_behaves_like 'a user with limited access'
      end

      describe 'for a developer' do
        let(:user) { developer }

        it_behaves_like 'a user with full access'
      end

      describe 'for a bot' do
        let(:user) { bot }

        it do
          expect_allowed(:reset_merge_request_approvals)
        end
      end
    end
  end

  context 'when user is an inherited member from a shared group' do
    let(:project) { create(:project, :public) }
    let(:merge_request) { create(:merge_request, source_project: project, target_project: project, author: user) }
    let(:user) { author }

    before do
      project.add_guest(author)
    end

    context 'and group is given developer access' do
      let(:user) { non_team_member }

      before do
        group = create(:group)
        project.project_group_links.create!(
          group: group,
          group_access: Gitlab::Access::DEVELOPER)

        group.add_guest(non_team_member)
        group.add_guest(bot)
      end

      it do
        expect_allowed(:approve_merge_request)
      end

      it do
        expect_disallowed(:reset_merge_request_approvals)
      end

      context 'and the user is a bot' do
        let(:user) { bot }

        it do
          expect_allowed(:approve_merge_request)
        end

        it do
          expect_allowed(:reset_merge_request_approvals)
        end
      end
    end
  end

  context 'when user is not a project member' do
    let(:project) { create(:project, :public) }

    context 'when merge request is public' do
      let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
      let(:user) { non_team_member }

      it do
        expect_disallowed(:approve_merge_request)
      end

      it do
        expect_disallowed(:reset_merge_request_approvals)
      end

      context 'and the user is a bot' do
        let(:user) { bot }

        it do
          expect_disallowed(:approve_merge_request)
        end

        it do
          expect_disallowed(:reset_merge_request_approvals)
        end
      end
    end

    context 'when merge requests are disabled' do
      let!(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
      let(:user) { non_team_member }

      before do
        project.project_feature.update!(merge_requests_access_level: ProjectFeature::DISABLED)
      end

      it_behaves_like 'a denied user'
    end

    context 'when merge requests are private' do
      let!(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
      let(:user) { non_team_member }

      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
      end

      it_behaves_like 'a denied user'
    end

    context 'when merge request is locked' do
      let(:merge_request) do
        create(:merge_request, :closed, discussion_locked: true, source_project: project, target_project: project)
      end

      let(:user) { non_team_member }

      it 'cannot create a note' do
        expect_disallowed(:create_note)
      end
    end
  end

  context 'when user is anonymous' do
    let(:project) { create(:project, :public) }
    let(:user) { nil }

    context 'when merge request is public' do
      let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

      it do
        expect_disallowed(:create_todo, :update_subscription)
      end
    end
  end

  context 'when the author of the merge request is banned', feature_category: :insider_threat do
    let_it_be(:user) { create(:user) }
    let_it_be(:admin) { create(:user, :admin) }
    let_it_be(:author) { create(:user, :banned) }
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:merge_request) { create(:merge_request, source_project: project, author: author) }

    context 'for a regular user' do
      it { expect_disallowed(:read_merge_request) }
    end

    context 'for an admin user', :enable_admin_mode do
      let(:user) { admin }

      it { expect_allowed(:read_merge_request) }
    end
  end
end
