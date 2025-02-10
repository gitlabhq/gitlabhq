# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuePolicy, feature_category: :team_planning do
  include_context 'ProjectPolicyTable context'
  include ExternalAuthorizationServiceHelpers
  include ProjectHelpers
  include UserHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:admin) { create(:user, :admin) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:planner) { create(:user) }
  let_it_be(:author) { create(:user) }
  let_it_be(:assignee) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:owner) { create(:user) }
  let_it_be(:reporter_from_group_link) { create(:user) }
  let_it_be(:non_member) { create(:user) }
  let(:support_bot) { Users::Internal.support_bot }
  let(:alert_bot) { Users::Internal.alert_bot }

  def permissions(user, issue)
    described_class.new(user, issue)
  end

  shared_examples 'support bot with service desk enabled' do
    before do
      allow(::Gitlab::Email::IncomingEmail).to receive(:enabled?) { true }
      allow(::Gitlab::Email::IncomingEmail).to receive(:supports_wildcard?) { true }

      project.update!(service_desk_enabled: true)
    end

    it 'allows support_bot to read issues, create and set metadata on new issues' do
      expect(permissions(support_bot, issue)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
        :set_confidentiality, :admin_issue_relation, :move_issue, :clone_issue
      )
      expect(permissions(support_bot, issue_no_assignee)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
        :set_confidentiality, :admin_issue_relation, :move_issue, :clone_issue
      )
      expect(permissions(support_bot, new_issue)).to be_allowed(
        :create_issue, :set_issue_metadata, :set_confidentiality, :admin_issue_relation
      )
    end
  end

  shared_examples 'support bot with service desk disabled' do
    it 'does not allow support_bot to read issues, create and set metadata on new issues' do
      expect(permissions(support_bot, issue)).to be_disallowed(
        :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
        :set_confidentiality, :admin_issue_relation, :move_issue, :clone_issue
      )
      expect(permissions(support_bot, issue_no_assignee)).to be_disallowed(
        :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
        :set_confidentiality, :admin_issue_relation, :move_issue, :clone_issue
      )
      expect(permissions(support_bot, new_issue)).to be_disallowed(
        :create_issue, :set_issue_metadata, :set_confidentiality, :admin_issue_relation
      )
    end
  end

  shared_examples 'alert bot' do
    it 'allows alert_bot to read and set metadata on issues' do
      expect(permissions(alert_bot, issue)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
        :set_confidentiality, :move_issue, :clone_issue
      )
      expect(permissions(alert_bot, issue_no_assignee)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
        :set_confidentiality, :move_issue, :clone_issue
      )
      expect(permissions(alert_bot, new_issue)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
        :set_confidentiality, :move_issue, :clone_issue
      )
    end
  end

  shared_examples 'grants the expected permissions' do |policy|
    specify do
      enable_admin_mode!(user) if admin_mode
      update_feature_access_level(project, feature_access_level)

      if expected_count == 1
        expect(permissions(user, issue)).to be_allowed(policy)
      else
        expect(permissions(user, issue)).to be_disallowed(policy)
      end
    end
  end

  context 'a private project' do
    let_it_be(:project) { create(:project, :private) }
    let_it_be_with_reload(:group_issue) { create(:issue, :group_level, namespace: group) }
    let_it_be_with_reload(:issue) { create(:issue, project: project, assignees: [assignee], author: author) }
    let_it_be_with_reload(:issue_no_assignee) { create(:issue, project: project) }
    let(:new_issue) { build(:issue, project: project, assignees: [assignee], author: author) }

    before_all do
      project.add_guest(guest)
      project.add_guest(author)
      project.add_guest(assignee)
      project.add_planner(planner)
      project.add_reporter(reporter)

      group.add_reporter(reporter_from_group_link)

      create(:project_group_link, group: group, project: project)
    end

    it 'allows guests to award emoji' do
      expect(permissions(guest, issue)).to be_allowed(:award_emoji)
    end

    it 'allows guests to read issues' do
      expect(permissions(guest, issue)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :admin_issue_relation, :admin_issue_link
      )
      expect(permissions(guest, issue)).to be_disallowed(
        :update_issue, :admin_issue, :set_issue_metadata, :set_confidentiality, :mark_note_as_internal,
        :move_issue, :clone_issue
      )

      expect(permissions(guest, issue_no_assignee)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :admin_issue_relation
      )
      expect(permissions(guest, issue_no_assignee)).to be_disallowed(
        :update_issue, :admin_issue, :set_issue_metadata, :set_confidentiality, :move_issue, :clone_issue
      )

      expect(permissions(guest, new_issue)).to be_allowed(:create_issue, :set_issue_metadata, :set_confidentiality)
    end

    it 'allows planners to read, update, admin and create confidential notes' do
      expect(permissions(planner, issue)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
        :set_confidentiality, :admin_issue_relation, :move_issue, :clone_issue
      )
      expect(permissions(planner, issue_no_assignee)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
        :set_confidentiality, :admin_issue_relation, :move_issue, :clone_issue
      )
      expect(permissions(planner, new_issue)).to be_allowed(
        :create_issue, :set_issue_metadata, :set_confidentiality, :mark_note_as_internal, :admin_issue_relation
      )
    end

    it 'allows reporters to read, update, admin and create confidential notes' do
      expect(permissions(reporter, issue)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
        :set_confidentiality, :admin_issue_relation, :move_issue, :clone_issue
      )
      expect(permissions(reporter, issue_no_assignee)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
        :set_confidentiality, :admin_issue_relation, :move_issue, :clone_issue
      )
      expect(permissions(reporter, new_issue)).to be_allowed(
        :create_issue, :set_issue_metadata, :set_confidentiality, :mark_note_as_internal, :admin_issue_relation
      )
    end

    it 'allows reporters from group links to read, update, and admin issues' do
      expect(permissions(reporter_from_group_link, issue)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
        :set_confidentiality, :admin_issue_relation, :move_issue, :clone_issue
      )
      expect(permissions(reporter_from_group_link, new_issue)).to be_allowed(
        :create_issue, :set_issue_metadata, :set_confidentiality, :admin_issue_relation
      )
    end

    it 'allows issue authors to read and update their issues' do
      expect(permissions(author, issue)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue_relation
      )
      expect(permissions(author, issue)).to be_disallowed(
        :admin_issue, :set_issue_metadata, :set_confidentiality, :move_issue, :clone_issue
      )

      expect(permissions(author, issue_no_assignee)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :admin_issue_relation
      )
      expect(permissions(author, issue_no_assignee)).to be_disallowed(
        :update_issue, :admin_issue, :set_issue_metadata, :set_confidentiality
      )

      expect(permissions(author, new_issue)).to be_allowed(
        :create_issue, :set_issue_metadata, :set_confidentiality, :admin_issue_relation
      )
    end

    it 'allows issue assignees to read and update their issues' do
      expect(permissions(assignee, issue)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue_relation
      )
      expect(permissions(assignee, issue)).to be_disallowed(
        :admin_issue, :set_issue_metadata, :set_confidentiality, :move_issue, :clone_issue
      )

      expect(permissions(assignee, issue_no_assignee)).to be_allowed(:read_issue, :read_note, :read_issue_iid)
      expect(permissions(assignee, issue_no_assignee)).to be_disallowed(
        :update_issue, :admin_issue, :set_issue_metadata, :set_confidentiality, :move_issue, :clone_issue
      )

      expect(permissions(assignee, new_issue)).to be_allowed(:create_issue, :set_issue_metadata, :set_confidentiality, :admin_issue_relation)
    end

    it 'does not allow non-members to read, update or create issues' do
      expect(permissions(non_member, issue)).to be_disallowed(
        :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
        :set_confidentiality, :admin_issue_relation, :move_issue, :clone_issue
      )
      expect(permissions(non_member, issue_no_assignee)).to be_disallowed(
        :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
        :set_confidentiality, :admin_issue_relation, :move_issue, :clone_issue
      )
      expect(permissions(non_member, new_issue)).to be_disallowed(
        :create_issue, :set_issue_metadata, :set_confidentiality
      )
    end

    it_behaves_like 'alert bot'
    it_behaves_like 'support bot with service desk disabled'
    it_behaves_like 'support bot with service desk enabled'

    context 'with confidential issues' do
      let(:confidential_issue) { create(:issue, :confidential, project: project, assignees: [assignee], author: author) }
      let(:confidential_issue_no_assignee) { create(:issue, :confidential, project: project) }

      it 'does not allow non-members to read confidential issues' do
        expect(permissions(non_member, confidential_issue)).to be_disallowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :admin_issue_relation,
          :award_emoji, :admin_issue_link, :move_issue, :clone_issue
        )
        expect(permissions(non_member, confidential_issue_no_assignee)).to be_disallowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
          :set_confidentiality, :admin_issue_relation, :award_emoji, :admin_issue_link, :move_issue, :clone_issue
        )
      end

      it 'does not allow guests to read confidential issues' do
        expect(permissions(guest, confidential_issue)).to be_disallowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :admin_issue_relation,
          :award_emoji, :admin_issue_link, :move_issue, :clone_issue
        )
        expect(permissions(guest, confidential_issue_no_assignee)).to be_disallowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
          :set_confidentiality, :admin_issue_relation, :award_emoji, :admin_issue_link, :move_issue, :clone_issue
        )
      end

      it 'allows planners to read, update, and admin confidential issues' do
        expect(permissions(planner, confidential_issue)).to be_allowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
          :set_confidentiality, :admin_issue_relation, :award_emoji, :move_issue, :clone_issue
        )
        expect(permissions(planner, confidential_issue_no_assignee)).to be_allowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
          :set_confidentiality, :admin_issue_relation, :award_emoji, :move_issue, :clone_issue
        )
      end

      it 'allows reporters to read, update, and admin confidential issues' do
        expect(permissions(reporter, confidential_issue)).to be_allowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
          :set_confidentiality, :admin_issue_relation, :award_emoji, :move_issue, :clone_issue
        )
        expect(permissions(reporter, confidential_issue_no_assignee)).to be_allowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
          :set_confidentiality, :admin_issue_relation, :award_emoji, :move_issue, :clone_issue
        )
      end

      it 'allows reporters from group links to read, update, and admin confidential issues' do
        expect(permissions(reporter_from_group_link, confidential_issue)).to be_allowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
          :set_confidentiality, :admin_issue_relation, :award_emoji, :move_issue, :clone_issue
        )
        expect(permissions(reporter_from_group_link, confidential_issue_no_assignee)).to be_allowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
          :set_confidentiality, :admin_issue_relation, :award_emoji, :move_issue, :clone_issue
        )
      end

      it 'allows issue authors to read and update their confidential issues' do
        expect(permissions(author, confidential_issue)).to be_allowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue_relation, :award_emoji
        )
        expect(permissions(author, confidential_issue)).to be_disallowed(
          :admin_issue, :set_issue_metadata, :set_confidentiality, :move_issue, :clone_issue
        )

        expect(permissions(author, confidential_issue_no_assignee)).to be_disallowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :admin_issue_relation, :award_emoji,
          :move_issue, :clone_issue
        )
        expect(permissions(author, confidential_issue_no_assignee)).to be_disallowed(
          :admin_issue, :read_note, :set_issue_metadata, :set_confidentiality, :award_emoji, :move_issue, :clone_issue
        )
      end

      it 'does not allow issue author to read or update confidential issue moved to an private project' do
        confidential_issue.project = create(:project, :private)

        expect(permissions(author, confidential_issue)).to be_disallowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :set_issue_metadata, :set_confidentiality,
          :admin_issue_relation, :award_emoji
        )
      end

      it 'allows issue assignees to read and update their confidential issues' do
        expect(permissions(assignee, confidential_issue)).to be_allowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :award_emoji
        )
        expect(permissions(assignee, confidential_issue)).to be_disallowed(
          :admin_issue, :set_issue_metadata, :set_confidentiality, :move_issue, :clone_issue
        )

        expect(permissions(assignee, confidential_issue_no_assignee)).to be_disallowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
          :set_confidentiality, :admin_issue_relation, :award_emoji, :move_issue, :clone_issue
        )
      end

      it 'does not allow issue assignees to read or update confidential issue moved to an private project' do
        confidential_issue.project = create(:project, :private)

        expect(permissions(assignee, confidential_issue)).to be_disallowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :set_issue_metadata, :set_confidentiality,
          :admin_issue_relation, :award_emoji
        )
      end
    end
  end

  context 'a public project' do
    let_it_be_with_reload(:project) { create(:project, :public) }
    let_it_be_with_reload(:issue) { create(:issue, project: project, assignees: [assignee], author: author) }
    let_it_be_with_reload(:group_issue) { create(:issue, :group_level, namespace: group) }
    let_it_be_with_reload(:issue_no_assignee) { create(:issue, project: project) }
    let_it_be_with_reload(:issue_locked) { create(:issue, :locked, project: project, author: author, assignees: [assignee]) }
    let(:new_issue) { build(:issue, project: project) }

    before_all do
      project.add_guest(guest)
      project.add_planner(planner)
      project.add_reporter(reporter)
      project.add_maintainer(maintainer)
      project.add_owner(owner)

      group.add_reporter(reporter_from_group_link)

      create(:project_group_link, group: group, project: project)
    end

    it 'does not allow anonymous user to create todos' do
      expect(permissions(nil, issue)).to be_allowed(:read_issue, :read_note)
      expect(permissions(nil, issue)).to be_disallowed(
        :create_todo, :update_subscription, :set_issue_metadata, :set_confidentiality, :admin_issue_relation
      )
      expect(permissions(nil, new_issue)).to be_disallowed(:create_issue, :set_issue_metadata, :set_confidentiality)
    end

    it 'does not allow anonymous user to admin issue links' do
      expect(permissions(nil, issue)).to be_disallowed(:admin_issue_link)
    end

    it 'allows guests to award emoji' do
      expect(permissions(guest, issue)).to be_allowed(:award_emoji)
      expect(permissions(guest, issue_no_assignee)).to be_allowed(:award_emoji)
    end

    it 'allows guests to admin issue links' do
      expect(permissions(guest, issue)).to be_allowed(:admin_issue_link)
    end

    it 'allows guests to read issues' do
      expect(permissions(guest, issue)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :create_todo, :update_subscription, :admin_issue_relation
      )
      expect(permissions(guest, issue)).to be_disallowed(
        :update_issue, :admin_issue, :reopen_issue, :set_issue_metadata, :set_confidentiality, :move_issue, :clone_issue
      )

      expect(permissions(guest, issue_no_assignee)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :admin_issue_relation
      )
      expect(permissions(guest, issue_no_assignee)).to be_disallowed(
        :update_issue, :admin_issue, :reopen_issue, :set_issue_metadata, :set_confidentiality, :move_issue, :clone_issue
      )

      expect(permissions(guest, issue_locked)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :admin_issue_relation
      )
      expect(permissions(guest, issue_locked)).to be_disallowed(
        :update_issue, :admin_issue, :reopen_issue, :set_issue_metadata, :set_confidentiality, :move_issue, :clone_issue
      )

      expect(permissions(guest, new_issue)).to be_allowed(
        :create_issue, :set_issue_metadata, :set_confidentiality, :admin_issue_relation
      )
    end

    it 'allows planners to read, update, reopen, and admin issues' do
      expect(permissions(planner, issue)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :reopen_issue, :set_issue_metadata,
        :set_confidentiality, :admin_issue_relation, :move_issue, :clone_issue
      )
      expect(permissions(planner, issue_no_assignee)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :reopen_issue, :set_issue_metadata,
        :set_confidentiality, :admin_issue_relation, :move_issue, :clone_issue
      )
      expect(permissions(planner, issue_locked)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
        :set_confidentiality, :admin_issue_relation, :move_issue, :clone_issue
      )
      expect(permissions(planner, issue_locked)).to be_disallowed(:reopen_issue)
      expect(permissions(planner, new_issue)).to be_allowed(
        :create_issue, :set_issue_metadata, :set_confidentiality, :admin_issue_relation
      )
    end

    it 'allows reporters to read, update, reopen, and admin issues' do
      expect(permissions(reporter, issue)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :reopen_issue, :set_issue_metadata,
        :set_confidentiality, :admin_issue_relation, :move_issue, :clone_issue
      )
      expect(permissions(reporter, issue_no_assignee)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :reopen_issue, :set_issue_metadata,
        :set_confidentiality, :admin_issue_relation, :move_issue, :clone_issue
      )
      expect(permissions(reporter, issue_locked)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
        :set_confidentiality, :admin_issue_relation, :move_issue, :clone_issue
      )
      expect(permissions(reporter, issue_locked)).to be_disallowed(:reopen_issue)
      expect(permissions(reporter, new_issue)).to be_allowed(
        :create_issue, :set_issue_metadata, :set_confidentiality, :admin_issue_relation
      )
    end

    it 'allows reporters from group links to read, update, reopen and admin issues' do
      expect(permissions(reporter_from_group_link, issue)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :reopen_issue, :set_issue_metadata,
        :set_confidentiality, :admin_issue_relation, :move_issue, :clone_issue
      )
      expect(permissions(reporter_from_group_link, issue_no_assignee)).to be_allowed(:reopen_issue)
      expect(permissions(reporter_from_group_link, issue_locked)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
        :set_confidentiality, :admin_issue_relation, :move_issue, :clone_issue
      )
      expect(permissions(reporter_from_group_link, issue_locked)).to be_disallowed(:reopen_issue)
      expect(permissions(reporter, new_issue)).to be_allowed(
        :create_issue, :set_issue_metadata, :set_confidentiality, :admin_issue_relation
      )
    end

    it 'allows issue authors to read, reopen and update their issues' do
      expect(permissions(author, issue)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :update_issue, :reopen_issue
      )
      expect(permissions(author, issue)).to be_disallowed(
        :admin_issue, :set_issue_metadata, :set_confidentiality, :move_issue, :clone_issue
      )

      expect(permissions(author, issue_no_assignee)).to be_allowed(:read_issue, :read_note, :read_issue_iid)
      expect(permissions(author, issue_no_assignee)).to be_disallowed(
        :update_issue, :admin_issue, :reopen_issue, :set_issue_metadata, :set_confidentiality, :move_issue, :clone_issue
      )

      expect(permissions(author, issue_locked)).to be_allowed(:read_issue, :read_note, :read_issue_iid, :update_issue)
      expect(permissions(author, issue_locked)).to be_disallowed(
        :admin_issue, :reopen_issue, :set_issue_metadata, :set_confidentiality, :move_issue, :clone_issue
      )

      expect(permissions(author, new_issue)).to be_allowed(:create_issue)
      expect(permissions(author, new_issue)).to be_disallowed(:set_issue_metadata)
    end

    it 'allows issue assignees to read, reopen and update their issues' do
      expect(permissions(assignee, issue)).to be_allowed(
        :read_issue, :read_note, :read_issue_iid, :update_issue, :reopen_issue
      )
      expect(permissions(assignee, issue)).to be_disallowed(
        :admin_issue, :set_issue_metadata, :set_confidentiality, :move_issue, :clone_issue
      )

      expect(permissions(assignee, issue_no_assignee)).to be_allowed(:read_issue, :read_note, :read_issue_iid)
      expect(permissions(assignee, issue_no_assignee)).to be_disallowed(
        :update_issue, :admin_issue, :reopen_issue, :set_issue_metadata, :set_confidentiality, :move_issue, :clone_issue
      )

      expect(permissions(assignee, issue_locked)).to be_allowed(:read_issue, :read_note, :read_issue_iid, :update_issue)
      expect(permissions(assignee, issue_locked)).to be_disallowed(
        :admin_issue, :reopen_issue, :set_issue_metadata, :set_confidentiality, :move_issue, :clone_issue
      )
    end

    it 'allows non-members to read and create issues' do
      expect(permissions(non_member, issue)).to be_allowed(:read_issue, :read_note, :read_issue_iid)
      expect(permissions(non_member, issue_no_assignee)).to be_allowed(:read_issue, :read_note, :read_issue_iid)
      expect(permissions(non_member, new_issue)).to be_allowed(:create_issue)
    end

    it 'allows non-members to read issues' do
      expect(permissions(non_member, issue)).to be_allowed(:read_issue, :read_note, :read_issue_iid)
      expect(permissions(non_member, issue_no_assignee)).to be_allowed(:read_issue, :read_note, :read_issue_iid)
    end

    it 'does not allow non-members to update, admin or set metadata except for set confidential flag' do
      expect(permissions(non_member, issue)).to be_disallowed(
        :update_issue, :admin_issue, :set_issue_metadata, :set_confidentiality, :move_issue, :clone_issue
      )
      expect(permissions(non_member, issue_no_assignee)).to be_disallowed(
        :update_issue, :admin_issue, :set_issue_metadata, :set_confidentiality, :move_issue, :clone_issue
      )
      expect(permissions(non_member, new_issue)).to be_disallowed(:set_issue_metadata)
      # this is allowed for non-members in a public project, as we want to let users report security issues
      # see https://gitlab.com/gitlab-org/gitlab/-/issues/337665
      expect(permissions(non_member, new_issue)).to be_allowed(:set_confidentiality)
    end

    it 'allows support_bot to read issues' do
      # support_bot is still allowed read access in public projects through :public_access permission,
      # see project_policy public_access rules policy (rule { can?(:public_access) }.policy {...})
      expect(permissions(support_bot, issue)).to be_allowed(:read_issue, :read_note, :read_issue_iid)
      expect(permissions(support_bot, issue)).to be_disallowed(
        :update_issue, :admin_issue, :set_issue_metadata, :set_confidentiality, :move_issue, :clone_issue
      )

      expect(permissions(support_bot, issue_no_assignee)).to be_allowed(:read_issue, :read_note, :read_issue_iid)
      expect(permissions(support_bot, issue_no_assignee)).to be_disallowed(
        :update_issue, :admin_issue, :set_issue_metadata, :set_confidentiality, :move_issue, :clone_issue
      )

      expect(permissions(support_bot, new_issue)).to be_disallowed(
        :create_issue, :set_issue_metadata, :set_confidentiality
      )
    end

    it_behaves_like 'alert bot'
    it_behaves_like 'support bot with service desk enabled'

    context 'when issues are private' do
      before_all do
        project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
      end

      let_it_be_with_reload(:issue) { create(:issue, project: project, author: author) }
      let_it_be(:visitor) { create(:user) }

      it 'forbids visitors from viewing issues' do
        expect(permissions(visitor, issue)).to be_disallowed(:read_issue)
      end

      it 'forbids visitors from commenting' do
        expect(permissions(visitor, issue)).to be_disallowed(:create_note)
      end

      it 'forbids visitors from subscribing' do
        expect(permissions(visitor, issue)).to be_disallowed(:update_subscription)
      end

      it 'allows guests to view' do
        expect(permissions(guest, issue)).to be_allowed(:read_issue)
      end

      it 'allows guests to comment' do
        expect(permissions(guest, issue)).to be_allowed(:create_note)
      end

      it 'allows guests to subscribe' do
        expect(permissions(guest, issue)).to be_allowed(:update_subscription)
      end

      it 'allows guests to admin relation' do
        expect(permissions(guest, issue)).to be_allowed(:admin_issue_relation)
      end

      context 'when admin mode is enabled', :enable_admin_mode do
        it 'allows admins to view' do
          expect(permissions(admin, issue)).to be_allowed(:read_issue)
        end

        it 'allows admins to comment' do
          expect(permissions(admin, issue)).to be_allowed(:create_note)
        end

        it 'allows admins to admin issue links' do
          expect(permissions(admin, issue)).to be_allowed(:admin_issue_link)
        end
      end

      context 'when admin mode is disabled' do
        it 'forbids admins to view' do
          expect(permissions(admin, issue)).to be_disallowed(:read_issue)
        end

        it 'forbids admins to comment' do
          expect(permissions(admin, issue)).to be_disallowed(:create_note)
        end
      end

      it 'does not allow non-members to update or create issues' do
        expect(permissions(non_member, issue)).to be_disallowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
          :set_confidentiality, :admin_issue_relation, :move_issue, :clone_issue
        )
        expect(permissions(non_member, issue_no_assignee)).to be_disallowed(
          :update_issue, :admin_issue, :set_issue_metadata, :set_confidentiality, :admin_issue_relation,
          :move_issue, :clone_issue
        )
        expect(permissions(non_member, new_issue)).to be_disallowed(
          :create_issue, :set_issue_metadata, :set_confidentiality, :admin_issue_relation
        )
      end

      it_behaves_like 'alert bot'
      it_behaves_like 'support bot with service desk disabled'
      it_behaves_like 'support bot with service desk enabled'
    end

    context 'with confidential issues' do
      let(:confidential_issue) { create(:issue, :confidential, project: project, assignees: [assignee], author: author) }
      let(:confidential_issue_no_assignee) { create(:issue, :confidential, project: project) }

      it 'does not allow guests to read confidential issues' do
        expect(permissions(guest, confidential_issue)).to be_disallowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :admin_issue_relation,
          :move_issue, :clone_issue
        )
        expect(permissions(guest, confidential_issue_no_assignee)).to be_disallowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
          :set_confidentiality, :move_issue, :clone_issue
        )
      end

      it 'allows planners to read, update, and admin confidential issues' do
        expect(permissions(planner, confidential_issue)).to be_allowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :admin_issue_relation,
          :move_issue, :clone_issue
        )
        expect(permissions(planner, confidential_issue_no_assignee)).to be_allowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
          :set_confidentiality, :move_issue, :clone_issue
        )
      end

      it 'allows reporters to read, update, and admin confidential issues' do
        expect(permissions(reporter, confidential_issue)).to be_allowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :admin_issue_relation,
          :move_issue, :clone_issue)
        expect(permissions(reporter, confidential_issue_no_assignee)).to be_allowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
          :set_confidentiality, :move_issue, :clone_issue
        )
      end

      it 'allows reporter from group links to read, update, and admin confidential issues' do
        expect(permissions(reporter_from_group_link, confidential_issue)).to be_allowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :admin_issue_relation,
          :move_issue, :clone_issue
        )
        expect(permissions(reporter_from_group_link, confidential_issue_no_assignee)).to be_allowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
          :set_confidentiality, :move_issue, :clone_issue
        )
      end

      it 'allows issue authors to read and update their confidential issues' do
        expect(permissions(author, confidential_issue)).to be_allowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue
        )
        expect(permissions(author, confidential_issue)).to be_disallowed(
          :admin_issue, :set_issue_metadata, :set_confidentiality, :move_issue, :clone_issue
        )

        expect(permissions(author, confidential_issue_no_assignee)).to be_disallowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
          :set_confidentiality, :move_issue, :clone_issue
        )
      end

      it 'allows issue assignees to read and update their confidential issues' do
        expect(permissions(assignee, confidential_issue)).to be_allowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue
        )
        expect(permissions(assignee, confidential_issue)).to be_disallowed(
          :admin_issue, :set_issue_metadata, :set_confidentiality, :move_issue, :clone_issue
        )

        expect(permissions(assignee, confidential_issue_no_assignee)).to be_disallowed(
          :read_issue, :read_note, :read_issue_iid, :update_issue, :admin_issue, :set_issue_metadata,
          :set_confidentiality, :move_issue, :clone_issue
        )
      end

      it 'allows admins to read confidential issues' do
        expect(permissions(admin, confidential_issue)).to be_allowed(:read_issue)
      end
    end

    context 'with a hidden issue' do
      let(:user) { create(:user) }
      let(:banned_user) { create(:user, :banned) }
      let(:hidden_issue) { create(:issue, project: project, author: banned_user) }

      it 'does not allow non-admin user to read the issue' do
        expect(permissions(user, hidden_issue)).not_to be_allowed(:read_issue)
      end

      it 'allows admin to read the issue', :enable_admin_mode do
        expect(permissions(admin, hidden_issue)).to be_allowed(:read_issue)
      end
    end

    context 'when accounting for notes widget' do
      context 'and notes widget is disabled for issue' do
        before_all do
          WorkItems::Type.default_by_type(:issue).widget_definitions.find_by_widget_type(:notes).update!(disabled: true)
        end

        it 'does not allow accessing notes' do
          # if notes widget is disabled not even maintainer can access notes
          expect(permissions(maintainer, issue)).to be_disallowed(
            :create_note, :read_note, :mark_note_as_internal, :read_internal_note, :admin_note
          )
          expect(permissions(admin, issue)).to be_disallowed(
            :create_note, :read_note, :read_internal_note, :mark_note_as_internal, :set_note_created_at, :admin_note
          )
        end
      end

      context 'and notes widget is enabled for issue' do
        it 'allows accessing notes' do
          # with notes widget enabled, even guests can access notes
          expect(permissions(guest, issue)).to be_allowed(:create_note, :read_note)
          expect(permissions(guest, issue)).to be_disallowed(
            :read_internal_note, :mark_note_as_internal, :set_note_created_at, :admin_note
          )
          expect(permissions(planner, issue)).to be_allowed(
            :create_note, :read_note, :read_internal_note, :mark_note_as_internal
          )
          expect(permissions(reporter, issue)).to be_allowed(
            :create_note, :read_note, :read_internal_note, :mark_note_as_internal
          )
          expect(permissions(reporter, issue)).to be_disallowed(:admin_note)
          expect(permissions(maintainer, issue)).to be_allowed(
            :create_note, :read_note, :read_internal_note, :mark_note_as_internal, :admin_note
          )
          expect(permissions(owner, issue)).to be_allowed(
            :create_note, :read_note, :read_internal_note, :mark_note_as_internal, :set_note_created_at, :admin_note
          )
        end
      end
    end
  end

  # rubocop:disable RSpec/MultipleMemoizedHelpers -- Need helpers for testing multiple scenarios
  context 'with group level issues' do
    let_it_be(:private_group) { create(:group, :private) }
    let_it_be(:public_group) { create(:group, :public) }
    let_it_be(:private_project) { create(:project, :private, group: private_group) }
    let_it_be(:public_project) { create(:project, :public, group: public_group) }

    let_it_be(:admin) { create(:user, :admin) }
    let_it_be(:non_member_user) { create(:user) }

    let_it_be(:guest) { create(:user, guest_of: [private_project, public_project]) }
    let_it_be(:planner) { create(:user, planner_of: [private_project, public_project]) }
    let_it_be(:guest_author) { create(:user, guest_of: [private_project, public_project]) }
    let_it_be(:reporter) { create(:user, reporter_of: [private_project, public_project]) }

    let_it_be(:group_guest) { create(:user, guest_of: [private_group, public_group]) }
    let_it_be(:group_planner) { create(:user, planner_of: [private_group, public_group]) }
    let_it_be(:group_guest_author) { create(:user, guest_of: [private_group, public_group]) }
    let_it_be(:group_reporter) { create(:user, reporter_of: [private_group, public_group]) }

    context 'with public group' do
      let(:work_item) { create(:issue, :group_level, namespace: public_group) }
      let(:confidential_work_item) { create(:issue, :group_level, confidential: true, namespace: public_group) }
      let(:authored_work_item) { create(:issue, :group_level, namespace: public_group, author: group_guest_author) }
      let(:authored_confidential_work_item) { create(:issue, :group_level, confidential: true, namespace: public_group, author: group_guest_author) }
      let(:not_persisted_work_item) { build(:issue, :group_level, namespace: public_group) }

      # only checking abilities without group level work items license, because in FOSS there is no license available
      it_behaves_like 'abilities without group level work items license'
    end

    context 'with private group' do
      let(:work_item) { create(:issue, :group_level, namespace: private_group) }
      let(:confidential_work_item) { create(:issue, :group_level, confidential: true, namespace: private_group) }
      let(:authored_work_item) { create(:issue, :group_level, namespace: private_group, author: group_guest_author) }
      let(:authored_confidential_work_item) { create(:issue, :group_level, confidential: true, namespace: private_group, author: group_guest_author) }
      let(:not_persisted_work_item) { build(:issue, :group_level, namespace: private_group) }

      # only checking abilities without group level work items license, because in FOSS there is no license available
      it_behaves_like 'abilities without group level work items license'
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  context 'with external authorization enabled' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :public) }
    let(:issue) { create(:issue, project: project) }
    let(:policies) { described_class.new(user, issue) }

    before do
      enable_external_authorization_service_check
    end

    it 'can read the issue iid without accessing the external service' do
      expect(::Gitlab::ExternalAuthorization).not_to receive(:access_allowed?)

      expect(policies).to be_allowed(:read_issue_iid)
    end
  end

  describe 'crm permissions' do
    let(:user) { create(:user) }
    let(:subgroup) { create(:group, parent: create(:group)) }
    let(:project) { create(:project, group: subgroup) }
    let(:issue) { create(:issue, project: project) }
    let(:policies) { described_class.new(user, issue) }

    %i[planner reporter].each do |role|
      context "when project #{role}" do
        it 'is disallowed' do
          project.try(:"add_#{role}", user)

          expect(policies).to be_disallowed(:read_crm_contacts)
          expect(policies).to be_disallowed(:set_issue_crm_contacts)
        end
      end

      context "when subgroup #{role}" do
        it 'is allowed' do
          subgroup.try(:"add_#{role}", user)

          expect(policies).to be_disallowed(:read_crm_contacts)
          expect(policies).to be_disallowed(:set_issue_crm_contacts)
        end
      end

      context "when root group #{role}" do
        it 'is allowed' do
          subgroup.parent.try(:"add_#{role}", user)

          expect(policies).to be_allowed(:read_crm_contacts)
          expect(policies).to be_allowed(:set_issue_crm_contacts)
        end
      end

      context 'when crm disabled on subgroup' do
        let(:subgroup) { create(:group, :crm_disabled, parent: create(:group)) }

        it 'is disallowed' do
          subgroup.parent.try(:"add_#{role}", user)

          expect(policies).to be_disallowed(:read_crm_contacts)
          expect(policies).to be_disallowed(:set_issue_crm_contacts)
        end
      end

      context 'when personal namespace' do
        let(:project) { create(:project) }

        it 'is disallowed' do
          project.try(:"add_#{role}", user)

          expect(policies).to be_disallowed(:read_crm_contacts)
          expect(policies).to be_disallowed(:set_issue_crm_contacts)
        end
      end

      context 'when custom crm_group configured' do
        let_it_be(:crm_settings) { create(:crm_settings, source_group: create(:group)) }
        let_it_be(:subgroup) { create(:group, parent: create(:group), crm_settings: crm_settings) }
        let_it_be(:project) { create(:project, group: subgroup) }

        context 'when custom crm_group guest' do
          it 'is disallowed' do
            subgroup.parent.try(:"add_#{role}", user)
            crm_settings.source_group.add_guest(user)

            expect(policies).to be_disallowed(:read_crm_contacts)
            expect(policies).to be_disallowed(:set_issue_crm_contacts)
          end
        end

        context "when custom crm_group #{role}" do
          it 'is allowed' do
            subgroup.parent.try(:"add_#{role}", user)
            crm_settings.source_group.try(:"add_#{role}", user)

            expect(policies).to be_allowed(:read_crm_contacts)
            expect(policies).to be_allowed(:set_issue_crm_contacts)
          end
        end
      end
    end
  end

  context 'when user is an inherited member from the group' do
    let(:user) { create_user_from_membership(group, membership) }
    let(:project) { create(:project, project_level, group: group) }
    let(:issue) { create(:issue, project: project) }

    context 'and policy allows guest access' do
      where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
        permission_table_for_guest_feature_access
      end

      with_them do
        it_behaves_like 'grants the expected permissions', :read_issue
        it_behaves_like 'grants the expected permissions', :read_issue_iid
      end
    end

    context 'and policy allows reporter access' do
      where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
        permission_table_for_reporter_issue_access
      end

      with_them do
        it_behaves_like 'grants the expected permissions', :update_issue
        it_behaves_like 'grants the expected permissions', :admin_issue
        it_behaves_like 'grants the expected permissions', :set_issue_metadata
        it_behaves_like 'grants the expected permissions', :set_confidentiality
      end
    end
  end
end
