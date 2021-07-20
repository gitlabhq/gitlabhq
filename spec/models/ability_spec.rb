# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ability do
  context 'using a nil subject' do
    it 'has no permissions' do
      expect(described_class.policy_for(nil, nil)).to be_banned
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
          read_cross_project_filter = -> (merge_requests) do
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
    context 'with an admin when admin mode is enabled', :enable_admin_mode do
      it 'returns all given issues' do
        user = build(:user, admin: true)
        issue = build(:issue)

        expect(described_class.issues_readable_by_user([issue], user))
          .to eq([issue])
      end
    end

    context 'with an admin when admin mode is disabled' do
      it 'returns the issues readable by the admin' do
        user = build(:user, admin: true)
        issue = build(:issue)

        expect(issue).to receive(:readable_by?).with(user).and_return(true)

        expect(described_class.issues_readable_by_user([issue], user))
          .to eq([issue])
      end

      it 'returns no issues when not given access' do
        user = build(:user, admin: true)
        issue = build(:issue)

        expect(described_class.issues_readable_by_user([issue], user))
          .to be_empty
      end
    end

    context 'with a regular user' do
      it 'returns the issues readable by the user' do
        user = build(:user)
        issue = build(:issue)

        expect(issue).to receive(:readable_by?).with(user).and_return(true)

        expect(described_class.issues_readable_by_user([issue], user))
          .to eq([issue])
      end

      it 'returns an empty Array when no issues are readable' do
        user = build(:user)
        issue = build(:issue)

        expect(issue).to receive(:readable_by?).with(user).and_return(false)

        expect(described_class.issues_readable_by_user([issue], user)).to eq([])
      end
    end

    context 'without a regular user' do
      it 'returns issues that are publicly visible' do
        hidden_issue = build(:issue)
        visible_issue = build(:issue)

        expect(hidden_issue).to receive(:publicly_visible?).and_return(false)
        expect(visible_issue).to receive(:publicly_visible?).and_return(true)

        issues = described_class
          .issues_readable_by_user([hidden_issue, visible_issue])

        expect(issues).to eq([visible_issue])
      end
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

        filters = { read_cross_project: -> (issues) { issues.where(project: project) } }
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
          read_cross_project_filter = -> (feature_flags) do
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

    subject { described_class.policy_for(project.owner, project) }

    context 'wiki named abilities' do
      it 'disables wiki abilities if the project has no wiki' do
        expect(subject).not_to be_allowed(:read_wiki)
        expect(subject).not_to be_allowed(:create_wiki)
        expect(subject).not_to be_allowed(:update_wiki)
        expect(subject).not_to be_allowed(:admin_wiki)
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
        "/dp/condition/BasePolicy/admin/#{user_b.id}"
      )
      expect(keys).not_to include("/dp/condition/BasePolicy/admin/#{user_a.id}")
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
