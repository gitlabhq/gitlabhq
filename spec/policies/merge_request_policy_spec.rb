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

  def permissions(user, merge_request)
    described_class.new(user, merge_request)
  end

  # :policy, :is_allowed
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

  # :policy, :is_allowed
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

  # :policy, :is_allowed
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
    let(:perms) { permissions(subject, merge_request) }

    mr_perms.each do |thing|
      it "cannot #{thing}" do
        expect(perms).to be_disallowed(thing)
      end
    end
  end

  shared_examples_for 'a user with limited access' do
    where(:policy, :is_allowed) do
      permission_table
    end

    with_them do
      specify do
        is_allowed ? (is_expected.to be_allowed(policy)) : (is_expected.to be_disallowed(policy))
      end
    end
  end

  shared_examples_for 'a user with full access' do
    let(:perms) { permissions(subject, merge_request) }

    mr_perms.each do |thing|
      it "can #{thing}" do
        expect(perms).to be_allowed(thing)
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
      let(:merge_request) { create(:merge_request, source_project: project, target_project: project, author: user) }
      let(:user) { author }

      context 'and user is author' do
        subject { permissions(user, merge_request) }

        context 'and the user is a guest' do
          let(:user) { guest }

          it do
            is_expected.to be_allowed(:update_merge_request)
          end

          it do
            is_expected.to be_allowed(:reopen_merge_request)
          end

          it do
            is_expected.to be_allowed(:approve_merge_request)
          end

          it do
            is_expected.to be_disallowed(:reset_merge_request_approvals)
          end
        end

        context 'and the user is a planner' do
          let(:user) { planner }

          it do
            is_expected.to be_allowed(:update_merge_request)
          end

          it do
            is_expected.to be_allowed(:reopen_merge_request)
          end

          it do
            is_expected.to be_allowed(:approve_merge_request)
          end

          it do
            is_expected.to be_allowed(:mark_note_as_internal)
          end

          it do
            is_expected.to be_disallowed(:reset_merge_request_approvals)
          end
        end

        context 'and the user is a bot' do
          let(:user) { bot }

          it do
            is_expected.to be_allowed(:reset_merge_request_approvals)
          end
        end
      end

      context 'and user is not author' do
        let(:merge_request) do
          create(:merge_request, source_project: project, target_project: project, author: author)
        end

        describe 'a guest' do
          let(:permission_table) { permission_table_for_guest }

          subject { permissions(guest, merge_request) }

          it_behaves_like 'a user with limited access'
        end

        describe 'a planner' do
          let(:permission_table) { permission_table_for_planner(public_merge_request: true) }

          subject { permissions(planner, merge_request) }

          it_behaves_like 'a user with limited access'
        end
      end

      context 'with private project' do
        let_it_be(:project) { create(:project, :private) }

        describe 'a guest' do
          subject { guest }

          it_behaves_like 'a denied user'
        end

        describe 'a planner' do
          let(:permission_table) { permission_table_for_planner }

          subject { permissions(planner, merge_request) }

          it_behaves_like 'a user with limited access'
        end
      end
    end

    context 'when merge requests have been disabled' do
      let!(:merge_request) { create(:merge_request, source_project: project, target_project: project, author: author) }

      before do
        project.project_feature.update!(merge_requests_access_level: ProjectFeature::DISABLED)
      end

      describe 'the author' do
        subject { author }

        it_behaves_like 'a denied user'
      end

      describe 'a guest' do
        subject { guest }

        it_behaves_like 'a denied user'
      end

      describe 'a planner' do
        subject { planner }

        it_behaves_like 'a denied user'
      end

      describe 'a developer' do
        subject { developer }

        it_behaves_like 'a denied user'
      end

      describe 'a bot' do
        let(:subject) { permissions(bot, merge_request) }

        it do
          is_expected.to be_disallowed(:reset_merge_request_approvals)
        end
      end
    end

    context 'when merge requests are private' do
      let!(:merge_request) { create(:merge_request, source_project: project, target_project: project, author: author) }

      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
      end

      describe 'the author' do
        subject { author }

        it_behaves_like 'a denied user'
      end

      describe 'a planner' do
        subject { planner }

        it_behaves_like 'a denied user'
      end

      describe 'a developer' do
        subject { developer }

        it_behaves_like 'a user with full access'
      end

      describe 'a bot' do
        let(:subject) { permissions(bot, merge_request) }

        it do
          is_expected.to be_allowed(:reset_merge_request_approvals)
        end
      end
    end

    context 'when merge request is unlocked' do
      let(:merge_request) { create(:merge_request, :closed, source_project: project, target_project: project, author: author) }

      it 'allows author to reopen merge request' do
        expect(permissions(author, merge_request)).to be_allowed(:reopen_merge_request)
      end

      it 'allows developer to reopen merge request' do
        expect(permissions(developer, merge_request)).to be_allowed(:reopen_merge_request)
      end

      it 'prevents planner from reopening merge request' do
        expect(permissions(planner, merge_request)).to be_disallowed(:reopen_merge_request)
      end

      it 'prevents guest from reopening merge request' do
        expect(permissions(guest, merge_request)).to be_disallowed(:reopen_merge_request)
      end
    end

    context 'when merge request is locked' do
      let(:merge_request_locked) { create(:merge_request, :closed, discussion_locked: true, source_project: project, target_project: project, author: author) }

      it 'prevents author from reopening merge request' do
        expect(permissions(author, merge_request_locked)).to be_disallowed(:reopen_merge_request)
      end

      it 'prevents developer from reopening merge request' do
        expect(permissions(developer, merge_request_locked)).to be_disallowed(:reopen_merge_request)
      end

      it 'prevents planners from reopening merge request' do
        expect(permissions(planner, merge_request_locked)).to be_disallowed(:reopen_merge_request)
      end

      it 'prevents guests from reopening merge request' do
        expect(permissions(guest, merge_request_locked)).to be_disallowed(:reopen_merge_request)
      end

      context 'when the user is project member, with at least guest access' do
        let(:user) { guest }

        it 'can create a note' do
          expect(permissions(user, merge_request_locked)).to be_allowed(:create_note)
        end
      end
    end

    context 'with external authorization enabled' do
      let(:user) { create(:user) }
      let(:project) { create(:project, :public) }
      let(:merge_request) { create(:merge_request, source_project: project) }
      let(:policies) { described_class.new(user, merge_request) }

      before do
        enable_external_authorization_service_check
      end

      it 'can read the issue iid without accessing the external service' do
        expect(::Gitlab::ExternalAuthorization).not_to receive(:access_allowed?)

        expect(policies).to be_allowed(:read_merge_request_iid)
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

    context 'when project is public' do
      let(:project) { create(:project, :public, group: group) }

      describe 'the merge request author' do
        subject { permissions(author, merge_request) }

        it do
          is_expected.to be_allowed(:approve_merge_request)
        end

        it do
          is_expected.to be_disallowed(:reset_merge_request_approvals)
        end
      end

      describe 'a bot' do
        subject { permissions(bot, merge_request) }

        it do
          is_expected.to be_allowed(:approve_merge_request)
        end

        it do
          is_expected.to be_allowed(:reset_merge_request_approvals)
        end
      end

      describe 'a planner' do
        let(:permission_table) { permission_table_for_reporter } # same as reporter because MR is public

        subject { permissions(planner, merge_request) }

        it_behaves_like 'a user with limited access'
      end

      describe 'a reporter' do
        let(:permission_table) { permission_table_for_reporter }

        subject { permissions(reporter, merge_request) }

        it_behaves_like 'a user with limited access'
      end

      context 'and merge requests are private' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
        end

        describe 'a guest' do
          subject { guest }

          it_behaves_like 'a denied user'
        end

        describe 'a planner' do
          subject { planner }

          it_behaves_like 'a denied user'
        end

        describe 'a reporter' do
          let(:permission_table) { permission_table_for_reporter }

          subject { permissions(reporter, merge_request) }

          it_behaves_like 'a user with limited access'
        end

        describe 'a developer' do
          subject { developer }

          it_behaves_like 'a user with full access'
        end

        describe 'a bot' do
          let(:subject) { permissions(bot, merge_request) }

          it do
            is_expected.to be_allowed(:reset_merge_request_approvals)
          end
        end
      end
    end

    context 'when project is private' do
      let(:project) { create(:project, :private, group: group) }

      describe 'a guest' do
        subject { guest }

        it_behaves_like 'a denied user'
      end

      describe 'a planner' do
        let(:permission_table) { permission_table_for_planner }

        subject { permissions(planner, merge_request) }

        it_behaves_like 'a user with limited access'
      end

      describe 'a reporter' do
        let(:permission_table) { permission_table_for_reporter }

        subject { permissions(reporter, merge_request) }

        it_behaves_like 'a user with limited access'
      end

      describe 'a developer' do
        subject { developer }

        it_behaves_like 'a user with full access'
      end

      describe 'a bot' do
        let(:subject) { permissions(bot, merge_request) }

        it do
          is_expected.to be_allowed(:reset_merge_request_approvals)
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

      subject { permissions(user, merge_request) }

      before do
        group = create(:group)
        project.project_group_links.create!(
          group: group,
          group_access: Gitlab::Access::DEVELOPER)

        group.add_guest(non_team_member)
        group.add_guest(bot)
      end

      it do
        is_expected.to be_allowed(:approve_merge_request)
      end

      it do
        is_expected.to be_disallowed(:reset_merge_request_approvals)
      end

      context 'and the user is a bot' do
        let(:user) { bot }

        it do
          is_expected.to be_allowed(:approve_merge_request)
        end

        it do
          is_expected.to be_allowed(:reset_merge_request_approvals)
        end
      end
    end
  end

  context 'when user is not a project member' do
    let(:project) { create(:project, :public) }

    context 'when merge request is public' do
      let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

      subject { permissions(non_team_member, merge_request) }

      it do
        is_expected.not_to be_allowed(:approve_merge_request)
      end

      it do
        is_expected.not_to be_allowed(:reset_merge_request_approvals)
      end

      context 'and the user is a bot' do
        subject { permissions(bot, merge_request) }

        it do
          is_expected.not_to be_allowed(:approve_merge_request)
        end

        it do
          is_expected.not_to be_allowed(:reset_merge_request_approvals)
        end
      end
    end

    context 'when merge requests are disabled' do
      let!(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

      before do
        project.project_feature.update!(merge_requests_access_level: ProjectFeature::DISABLED)
      end

      subject { non_team_member }

      it_behaves_like 'a denied user'
    end

    context 'when merge requests are private' do
      let!(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
      end

      subject { non_team_member }

      it_behaves_like 'a denied user'
    end

    context 'when merge request is locked' do
      let(:merge_request) { create(:merge_request, :closed, discussion_locked: true, source_project: project, target_project: project) }

      it 'cannot create a note' do
        expect(permissions(non_team_member, merge_request)).to be_disallowed(:create_note)
      end
    end
  end

  context 'when user is anonymous' do
    let(:project) { create(:project, :public) }

    context 'when merge request is public' do
      let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

      subject { permissions(nil, merge_request) }

      specify do
        is_expected.to be_disallowed(:create_todo, :update_subscription)
      end
    end
  end

  context 'when the author of the merge request is banned', feature_category: :insider_threat do
    let_it_be(:user) { create(:user) }
    let_it_be(:admin) { create(:user, :admin) }
    let_it_be(:author) { create(:user, :banned) }
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:hidden_merge_request) { create(:merge_request, source_project: project, author: author) }

    it 'does not allow non-admin user to read the merge_request' do
      expect(permissions(user, hidden_merge_request)).not_to be_allowed(:read_merge_request)
    end

    it 'allows admin to read the merge_request', :enable_admin_mode do
      expect(permissions(admin, hidden_merge_request)).to be_allowed(:read_merge_request)
    end

    context 'when the `hide_merge_requests_from_banned_users` feature flag is disabled' do
      before do
        stub_feature_flags(hide_merge_requests_from_banned_users: false)
      end

      it 'allows non-admin users to read the merge_request' do
        expect(permissions(user, hidden_merge_request)).to be_allowed(:read_merge_request)
      end

      it 'allows admin users to read the merge_request', :enable_admin_mode do
        expect(permissions(admin, hidden_merge_request)).to be_allowed(:read_merge_request)
      end
    end
  end
end
