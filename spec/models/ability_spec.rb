# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ability, feature_category: :system_access do
  describe '#policy_for' do
    subject(:policy) { described_class.policy_for(user, subject, **options) }

    let(:user) { User.new }
    let(:subject) { :global }
    let(:options) { {} }

    context 'using a nil subject' do
      let(:user) { nil }
      let(:subject) { nil }

      it 'has no permissions' do
        expect(policy).to be_banned
      end
    end

    context 'with request store', :request_store do
      before do
        ::Gitlab::SafeRequestStore.write(:example, :value) # make request store different from {}
      end

      it 'caches in the request store' do
        expect(DeclarativePolicy).to receive(:policy_for).with(user, subject, cache: ::Gitlab::SafeRequestStore.storage)

        policy
      end

      context 'when cache: false' do
        let(:options) { { cache: false } }

        it 'uses a fresh cache each time' do
          expect(DeclarativePolicy).to receive(:policy_for).with(user, subject, cache: {})

          policy
        end
      end
    end
  end

  describe '.users_that_can_read_project' do
    context 'using a public project' do
      it 'returns all the users' do
        project = create(:project, :public)
        user = build(:user)

        expect(described_class.users_that_can_read_project([user], project))
          .to eq([user])
      end
    end

    context 'using an internal project' do
      let(:project) { create(:project, :internal) }

      it 'returns users that are administrators' do
        user = build(:user, admin: true)

        expect(described_class.users_that_can_read_project([user], project))
          .to eq([user])
      end

      it 'returns internal users while skipping external users' do
        user1 = build(:user)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(described_class.users_that_can_read_project(users, project))
          .to eq([user1])
      end

      it 'returns external users if they are the project owner' do
        user1 = build(:user, external: true)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(project).to receive(:owner).at_least(:once).and_return(user1)

        expect(described_class.users_that_can_read_project(users, project))
          .to eq([user1])
      end

      it 'returns external users if they are project members' do
        user1 = build(:user, external: true)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(project.team).to receive(:members).at_least(:once).and_return([user1])

        expect(described_class.users_that_can_read_project(users, project))
          .to eq([user1])
      end

      it 'returns an empty Array if all users are external users without access' do
        user1 = build(:user, external: true)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(described_class.users_that_can_read_project(users, project))
          .to eq([])
      end
    end

    context 'using a private project' do
      let(:project) { create(:project, :private) }

      it 'returns users that are administrators when admin mode is enabled', :enable_admin_mode do
        user = build(:user, admin: true)

        expect(described_class.users_that_can_read_project([user], project))
          .to eq([user])
      end

      it 'does not return users that are administrators when admin mode is disabled' do
        user = build(:user, admin: true)

        expect(described_class.users_that_can_read_project([user], project))
          .to eq([])
      end

      it 'returns external users if they are the project owner' do
        user1 = build(:user, external: true)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(project).to receive(:owner).at_least(:once).and_return(user1)

        expect(described_class.users_that_can_read_project(users, project))
          .to eq([user1])
      end

      it 'returns external users if they are project members' do
        user1 = build(:user, external: true)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(project.team).to receive(:members).at_least(:once).and_return([user1])

        expect(described_class.users_that_can_read_project(users, project))
          .to eq([user1])
      end

      it 'returns an empty Array if all users are internal users without access' do
        user1 = build(:user)
        user2 = build(:user)
        users = [user1, user2]

        expect(described_class.users_that_can_read_project(users, project))
          .to eq([])
      end

      it 'returns an empty Array if all users are external users without access' do
        user1 = build(:user, external: true)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(described_class.users_that_can_read_project(users, project))
          .to eq([])
      end
    end
  end

  describe '.users_that_can_read_personal_snippet' do
    def users_for_snippet(snippet)
      described_class.users_that_can_read_personal_snippet(users, snippet)
    end

    let(:users)  { create_list(:user, 3) }
    let(:author) { users[0] }

    it 'private snippet is readable only by its author' do
      snippet = create(:personal_snippet, :private, author: author)

      expect(users_for_snippet(snippet)).to match_array([author])
    end

    it 'public snippet is readable by all users' do
      snippet = create(:personal_snippet, :public, author: author)

      expect(users_for_snippet(snippet)).to match_array(users)
    end
  end

  describe '.users_that_can_read_internal_note' do
    shared_examples 'filtering users that can read internal note' do
      let_it_be(:guest) { create(:user) }
      let_it_be(:reporter) { create(:user) }

      let(:users) { [reporter, guest] }

      before do
        parent.add_guest(guest)
        parent.add_reporter(reporter)
      end

      it 'returns users that can read internal notes' do
        result = described_class.users_that_can_read_internal_notes(users, parent)

        expect(result).to match_array([reporter])
      end
    end

    context 'for groups' do
      it_behaves_like 'filtering users that can read internal note' do
        let(:parent) { create(:group) }
      end
    end

    context 'for projects' do
      it_behaves_like 'filtering users that can read internal note' do
        let(:parent) { create(:project) }
      end
    end
  end

  describe '.merge_requests_readable_by_user' do
    context 'with an admin when admin mode is enabled', :enable_admin_mode do
      it 'returns all merge requests' do
        user = build(:user, admin: true)
        merge_request = build(:merge_request)

        expect(described_class.merge_requests_readable_by_user([merge_request], user))
          .to eq([merge_request])
      end
    end

    context 'with an admin when admin mode is disabled' do
      it 'returns merge_requests that are publicly visible' do
        user = build(:user, admin: true)
        hidden_merge_request = build(:merge_request)
        visible_merge_request = build(:merge_request, source_project: build(:project, :public))

        merge_requests = described_class
                           .merge_requests_readable_by_user([hidden_merge_request, visible_merge_request], user)

        expect(merge_requests).to eq([visible_merge_request])
      end
    end

    context 'without a user' do
      it 'returns merge_requests that are publicly visible' do
        hidden_merge_request = build(:merge_request)
        visible_merge_request = build(:merge_request, source_project: build(:project, :public))

        merge_requests = described_class
                           .merge_requests_readable_by_user([hidden_merge_request, visible_merge_request])

        expect(merge_requests).to eq([visible_merge_request])
      end
    end

    context 'with a user' do
      let(:user) { create(:user) }
      let(:project) { create(:project) }
      let(:merge_request) { create(:merge_request, source_project: project) }
      let(:cross_project_merge_request) do
        create(:merge_request, source_project: create(:project, :public))
      end

      let(:other_merge_request) { create(:merge_request) }
      let(:all_merge_requests) do
        [merge_request, cross_project_merge_request, other_merge_request]
      end

      subject(:readable_merge_requests) do
        described_class.merge_requests_readable_by_user(all_merge_requests, user)
      end

      before do
        project.add_developer(user)
      end

      it 'returns projects visible to the user' do
        expect(readable_merge_requests).to contain_exactly(merge_request, cross_project_merge_request)
      end

      context 'when a user cannot read cross project and a filter is passed' do
        before do
          allow(described_class).to receive(:allowed?).and_call_original
          expect(described_class).to receive(:allowed?).with(user, :read_cross_project) { false }
        end

        subject(:readable_merge_requests) do
          read_cross_project_filter = ->(merge_requests) do
            merge_requests.select { |mr| mr.source_project == project }
          end
          described_class.merge_requests_readable_by_user(
            all_merge_requests, user,
            filters: { read_cross_project: read_cross_project_filter }
          )
        end

        it 'returns only MRs of the specified project without checking access on others' do
          expect(described_class).not_to receive(:allowed?).with(user, :read_merge_request, cross_project_merge_request)

          expect(readable_merge_requests).to contain_exactly(merge_request)
        end
      end
    end
  end

  describe '.issues_readable_by_user' do
    it 'is aliased to .work_items_readable_by_user' do
      expect(described_class.method(:issues_readable_by_user))
        .to eq(described_class.method(:work_items_readable_by_user))
    end

    context 'when the user cannot read cross project' do
      let(:user) { create(:user) }
      let(:issue) { create(:issue) }
      let(:other_project_issue) { create(:issue) }
      let(:project) { issue.project }

      before do
        project.add_developer(user)

        allow(described_class).to receive(:allowed?).and_call_original
        allow(described_class).to receive(:allowed?).with(user, :read_cross_project, any_args) { false }
      end

      it 'excludes issues from other projects whithout checking separatly when passing a scope' do
        expect(described_class).not_to receive(:allowed?).with(user, :read_issue, other_project_issue)

        filters = { read_cross_project: ->(issues) { issues.where(project: project) } }
        result = described_class.issues_readable_by_user(Issue.all, user, filters: filters)

        expect(result).to contain_exactly(issue)
      end
    end
  end

  describe '.feature_flags_readable_by_user' do
    context 'without a user' do
      it 'returns no feature flags' do
        feature_flag_1 = build(:operations_feature_flag)
        feature_flag_2 = build(:operations_feature_flag, project: build(:project, :public))

        feature_flags = described_class
                          .feature_flags_readable_by_user([feature_flag_1, feature_flag_2])

        expect(feature_flags).to eq([])
      end
    end

    context 'with a user' do
      let(:user) { create(:user) }
      let(:project) { create(:project) }
      let(:feature_flag) { create(:operations_feature_flag, project: project) }
      let(:cross_project) { create(:project) }
      let(:cross_project_feature_flag) { create(:operations_feature_flag, project: cross_project) }

      let(:other_feature_flag) { create(:operations_feature_flag) }
      let(:all_feature_flags) do
        [feature_flag, cross_project_feature_flag, other_feature_flag]
      end

      subject(:readable_feature_flags) do
        described_class.feature_flags_readable_by_user(all_feature_flags, user)
      end

      before do
        project.add_developer(user)
        cross_project.add_developer(user)
      end

      it 'returns feature flags visible to the user' do
        expect(readable_feature_flags).to contain_exactly(feature_flag, cross_project_feature_flag)
      end

      context 'when a user cannot read cross project and a filter is passed' do
        before do
          allow(described_class).to receive(:allowed?).and_call_original
          expect(described_class).to receive(:allowed?).with(user, :read_cross_project) { false }
        end

        subject(:readable_feature_flags) do
          read_cross_project_filter = ->(feature_flags) do
            feature_flags.select { |flag| flag.project == project }
          end
          described_class.feature_flags_readable_by_user(
            all_feature_flags, user,
            filters: { read_cross_project: read_cross_project_filter }
          )
        end

        it 'returns only feature flags of the specified project without checking access on others' do
          expect(described_class).not_to receive(:allowed?).with(user, :read_feature_flag, cross_project_feature_flag)

          expect(readable_feature_flags).to contain_exactly(feature_flag)
        end
      end
    end
  end

  describe '.project_disabled_features_rules' do
    let(:project) { create(:project, :wiki_disabled) }

    subject { described_class.policy_for(project.first_owner, project) }

    context 'wiki named abilities' do
      it 'disables wiki abilities if the project has no wiki' do
        expect(subject).not_to be_allowed(:read_wiki)
        expect(subject).not_to be_allowed(:create_wiki)
        expect(subject).not_to be_allowed(:update_wiki)
        expect(subject).not_to be_allowed(:admin_wiki)
      end
    end
  end

  describe '.allowed?' do
    let_it_be(:group) { create(:group, :private) }
    let_it_be_with_reload(:primary_user) { create(:user, :service_account) }
    let_it_be(:scoped_user) { create(:user) }

    let(:request_store_key) { format(::Gitlab::Auth::Identity::COMPOSITE_IDENTITY_KEY_FORMAT, primary_user.id) }

    context 'with composite identity', :request_store do
      before do
        primary_user.update!(composite_identity_enforced: true)
      end

      context 'with linked identity' do
        before do
          ::Gitlab::Auth::Identity.new(primary_user).link!(scoped_user)
        end

        context 'when called with primary user' do
          subject { described_class.allowed?(primary_user, :read_group, group) }

          context 'when both users are members' do
            before_all do
              group.add_developer(scoped_user)
              group.add_developer(primary_user)
            end

            it 'returns true' do
              expect(subject).to be_truthy
            end
          end

          context 'when only primary user is a member' do
            before_all do
              group.add_developer(primary_user)
            end

            it 'returns false' do
              expect(subject).to be_falsey
            end

            context 'with unenforced composite identity' do
              before do
                primary_user.update!(composite_identity_enforced: false)
              end

              it 'returns true' do
                expect(subject).to be_truthy
              end
            end
          end

          context 'when only scoped user is a member' do
            before_all do
              group.add_developer(scoped_user)
            end

            it 'returns false' do
              expect(subject).to be_falsey
            end
          end

          context 'when neither user is a member' do
            it 'returns false' do
              expect(subject).to be_falsey
            end
          end

          context 'when scoped user is a composite identity' do
            let_it_be(:scoped_user) { primary_user }

            it 'returns false' do
              group.add_developer(primary_user)

              expect(subject).to be_falsey
            end
          end
        end

        context 'when called with scoped user' do
          subject { described_class.allowed?(scoped_user, :read_group, group) }

          context 'when both users are members' do
            before_all do
              group.add_developer(scoped_user)
              group.add_developer(primary_user)
              scoped_user.composite_identity_enforced!
            end

            it 'returns true' do
              expect(subject).to be_truthy
            end
          end

          context 'when only primary user is a member' do
            before_all do
              group.add_developer(primary_user)
            end

            it 'returns false' do
              expect(subject).to be_falsey
            end
          end

          context 'when only scoped user is a member' do
            before_all do
              scoped_user.composite_identity_enforced!
              group.add_developer(scoped_user)
            end

            it 'returns false' do
              expect(subject).to be_falsey
            end
          end

          context 'when neither user is a member' do
            it 'returns false' do
              expect(subject).to be_falsey
            end
          end
        end
      end

      context 'without linked identity' do
        before do
          ::Gitlab::SafeRequestStore.delete(request_store_key)
        end

        before_all do
          group.add_developer(primary_user)
        end

        subject { described_class.allowed?(primary_user, :read_group, group) }

        it 'returns false' do
          expect(subject).to be_falsey
        end

        context 'when ability check is not null safe' do
          # some ability checks raise an error if the passed in user is nil
          # this test has the ability check raise StandardError for a nil user to replicate this behavior
          it 'returns false' do
            allow(described_class).to receive(:allowed?).and_call_original
            allow(described_class).to receive(:allowed?).with(nil, :read_group, group,
              { composite_identity_check: false })
              .and_raise(StandardError)

            expect(subject).to be_falsey
          end
        end
      end
    end
  end

  describe 'forgetting', :request_store do
    it 'allows us to discard specific values from the DeclarativePolicy cache' do
      user_a = build_stubbed(:user)
      user_b = build_stubbed(:user)

      # expect these keys to remain
      Gitlab::SafeRequestStore[:administrator] = :wibble
      Gitlab::SafeRequestStore['admin'] = :wobble
      described_class.allowed?(user_b, :read_all_resources)
      # expect the DeclarativePolicy cache keys added by this action not to remain
      described_class.forgetting(/admin/) do
        described_class.allowed?(user_a, :read_all_resources)
      end

      keys = Gitlab::SafeRequestStore.storage.keys

      expect(keys).to include(
        :administrator,
        'admin',
        "/dp/condition/BasePolicy/admin/User:#{user_b.id}"
      )
      expect(keys).not_to include("/dp/condition/BasePolicy/admin/User:#{user_a.id}")
    end

    # regression spec for re-entrant admin condition checks
    # See: https://gitlab.com/gitlab-org/gitlab/-/issues/332983
    context 'when bypassing the session' do
      let(:user) { build_stubbed(:admin) }
      let(:ability) { :admin_all_resources } # any admin-only ability is fine here.

      def check_ability
        described_class.forgetting(/admin/) { described_class.allowed?(user, ability) }
      end

      it 'allows us to have re-entrant evaluation of admin-only permissions' do
        expect { Gitlab::Auth::CurrentUserMode.bypass_session!(user.id) }
          .to change { check_ability }.from(false).to(true)
      end
    end
  end
end
