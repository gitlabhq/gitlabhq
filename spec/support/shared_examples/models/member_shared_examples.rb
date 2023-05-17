# frozen_string_literal: true

RSpec.shared_examples 'inherited access level as a member of entity' do
  let(:parent_entity) { create(:group) }
  let(:user) { create(:user) }
  let(:member) { entity.member(user) }

  context 'with root parent_entity developer member' do
    before do
      parent_entity.add_developer(user)
    end

    it 'is allowed to be a maintainer of the entity' do
      entity.add_maintainer(user)

      expect(member.access_level).to eq(Gitlab::Access::MAINTAINER)
    end

    it 'is not allowed to be a reporter of the entity' do
      entity.add_reporter(user)

      expect(member).to be_nil
    end

    it 'is allowed to change to be a developer of the entity' do
      entity.add_maintainer(user)

      expect { member.update!(access_level: Gitlab::Access::DEVELOPER) }
        .to change { member.access_level }.to(Gitlab::Access::DEVELOPER)
    end

    it 'is not allowed to change to be a guest of the entity' do
      entity.add_maintainer(user)

      expect { member.update(access_level: Gitlab::Access::GUEST) } # rubocop:disable Rails/SaveBang
        .not_to change { member.reload.access_level }
    end

    it "shows an error if the member can't be updated" do
      entity.add_maintainer(user)

      expect { member.update!(access_level: Gitlab::Access::REPORTER) }.to raise_error(ActiveRecord::RecordInvalid)

      expect(member.errors.full_messages).to eq(["Access level should be greater than or equal to Developer inherited membership from group #{parent_entity.name}"])
    end

    it 'allows changing the level from a non existing member' do
      non_member_user = create(:user)

      entity.add_maintainer(non_member_user)

      non_member = entity.member(non_member_user)

      expect { non_member.update!(access_level: Gitlab::Access::GUEST) }
        .to change { non_member.reload.access_level }
    end
  end
end

RSpec.shared_examples '#valid_level_roles' do |entity_name|
  let(:member_user) { create(:user) }
  let(:group) { create(:group) }
  let(:entity) { create(entity_name) } # rubocop:disable Rails/SaveBang
  let(:entity_member) { create("#{entity_name}_member", :developer, source: entity, user: member_user) }
  let(:presenter) { described_class.new(entity_member, current_user: member_user) }

  context 'when no parent member is present' do
    let(:all_permissible_roles) { entity_member.class.permissible_access_level_roles(member_user, entity) }

    it 'returns all permissible roles' do
      expect(presenter.valid_level_roles).to eq(all_permissible_roles)
    end
  end

  context 'when parent member is present' do
    before do
      group.add_reporter(member_user)
    end

    it 'returns higher roles when a parent member is present' do
      expect(presenter.valid_level_roles).to eq(expected_roles)
    end
  end
end

RSpec.shared_examples_for "member creation" do
  let_it_be(:admin) { create(:admin) }

  it 'returns a Member object', :aggregate_failures do
    member = described_class.add_member(source, user, :maintainer)

    expect(member).to be_a member_type
    expect(member).to be_persisted
  end

  context 'when adding a project_bot' do
    let_it_be(:project_bot) { create(:user, :project_bot) }

    before_all do
      source.add_owner(user)
    end

    context 'when project_bot is already a member' do
      before do
        source.add_developer(project_bot)
      end

      it 'does not update the member' do
        member = described_class.add_member(source, project_bot, :maintainer, current_user: user)

        expect(source.users.reload).to include(project_bot)
        expect(member).to be_persisted
        expect(member.access_level).to eq(Gitlab::Access::DEVELOPER)
        expect(member.errors.full_messages).to include(/not authorized to update member/)
      end
    end

    context 'when project_bot is not already a member' do
      it 'adds the member' do
        member = described_class.add_member(source, project_bot, :maintainer, current_user: user)

        expect(source.users.reload).to include(project_bot)
        expect(member).to be_persisted
      end
    end
  end

  context 'when admin mode is enabled', :enable_admin_mode, :aggregate_failures do
    it 'sets members.created_by to the given admin current_user' do
      member = described_class.add_member(source, user, :maintainer, current_user: admin)

      expect(member).to be_persisted
      expect(source.users.reload).to include(user)
      expect(member.created_by).to eq(admin)
    end
  end

  context 'when admin mode is disabled' do
    it 'rejects setting members.created_by to the given admin current_user', :aggregate_failures do
      member = described_class.add_member(source, user, :maintainer, current_user: admin)

      expect(member).not_to be_persisted
      expect(source.users.reload).not_to include(user)
      expect(member.errors.full_messages).to include(/not authorized to create member/)
    end
  end

  it 'sets members.expires_at to the given expires_at' do
    member = described_class.add_member(source, user, :maintainer, expires_at: Date.new(2016, 9, 22))

    expect(member.expires_at).to eq(Date.new(2016, 9, 22))
  end

  described_class.access_levels.each do |sym_key, int_access_level|
    it "accepts the :#{sym_key} symbol as access level", :aggregate_failures do
      expect(source.users).not_to include(user)

      member = described_class.add_member(source, user.id, sym_key)

      expect(member.access_level).to eq(int_access_level)
      expect(source.users.reload).to include(user)
    end

    it "accepts the #{int_access_level} integer as access level", :aggregate_failures do
      expect(source.users).not_to include(user)

      member = described_class.add_member(source, user.id, int_access_level)

      expect(member.access_level).to eq(int_access_level)
      expect(source.users.reload).to include(user)
    end
  end

  context 'with no current_user' do
    context 'when called with a known user id' do
      it 'adds the user as a member' do
        expect(source.users).not_to include(user)

        described_class.add_member(source, user.id, :maintainer)

        expect(source.users.reload).to include(user)
      end
    end

    context 'when called with an unknown user id' do
      it 'does not add the user as a member' do
        expect(source.users).not_to include(user)

        described_class.add_member(source, non_existing_record_id, :maintainer)

        expect(source.users.reload).not_to include(user)
      end
    end

    context 'when called with a user object' do
      it 'adds the user as a member' do
        expect(source.users).not_to include(user)

        described_class.add_member(source, user, :maintainer)

        expect(source.users.reload).to include(user)
      end
    end

    context 'when called with a requester user object' do
      before do
        source.request_access(user)
      end

      it 'adds the requester as a member', :aggregate_failures do
        expect(source.users).not_to include(user)
        expect(source.requesters.exists?(user_id: user)).to eq(true)

        described_class.add_member(source, user, :maintainer)

        expect(source.users.reload).to include(user)
        expect(source.requesters.reload.exists?(user_id: user)).to eq(false)
      end
    end

    context 'when called with a known user email' do
      it 'adds the user as a member' do
        expect(source.users).not_to include(user)

        described_class.add_member(source, user.email, :maintainer)

        expect(source.users.reload).to include(user)
      end
    end

    context 'when called with an unknown user email' do
      it 'creates an invited member' do
        expect(source.users).not_to include(user)

        described_class.add_member(source, 'user@example.com', :maintainer)

        expect(source.members.invite.pluck(:invite_email)).to include('user@example.com')
      end
    end

    context 'when called with an unknown user email starting with a number' do
      it 'creates an invited member', :aggregate_failures do
        email_starting_with_number = "#{user.id}_email@example.com"

        described_class.add_member(source, email_starting_with_number, :maintainer)

        expect(source.members.invite.pluck(:invite_email)).to include(email_starting_with_number)
        expect(source.users.reload).not_to include(user)
      end
    end
  end

  context 'when current_user can update member', :enable_admin_mode do
    it 'creates the member' do
      expect(source.users).not_to include(user)

      described_class.add_member(source, user, :maintainer, current_user: admin)

      expect(source.users.reload).to include(user)
    end

    context 'when called with a requester user object' do
      before do
        source.request_access(user)
      end

      it 'adds the requester as a member', :aggregate_failures do
        expect(source.users).not_to include(user)
        expect(source.requesters.exists?(user_id: user)).to be_truthy

        described_class.add_member(source, user, :maintainer, current_user: admin)

        expect(source.users.reload).to include(user)
        expect(source.requesters.reload.exists?(user_id: user)).to be_falsy
      end
    end
  end

  context 'when current_user cannot update member' do
    it 'does not create the member', :aggregate_failures do
      expect(source.users).not_to include(user)

      member = described_class.add_member(source, user, :maintainer, current_user: user)

      expect(source.users.reload).not_to include(user)
      expect(member).not_to be_persisted
    end

    context 'when called with a requester user object' do
      before do
        source.request_access(user)
      end

      it 'does not destroy the requester', :aggregate_failures do
        expect(source.users).not_to include(user)
        expect(source.requesters.exists?(user_id: user)).to be_truthy

        described_class.add_member(source, user, :maintainer, current_user: user)

        expect(source.users.reload).not_to include(user)
        expect(source.requesters.exists?(user_id: user)).to be_truthy
      end
    end
  end

  context 'when member already exists' do
    context 'when member is a user' do
      before do
        source.add_member(user, :developer)
      end

      context 'with no current_user' do
        it 'updates the member' do
          expect(source.users).to include(user)

          described_class.add_member(source, user, :maintainer)

          expect(source.members.find_by(user_id: user).access_level).to eq(Gitlab::Access::MAINTAINER)
        end
      end

      context 'when current_user can update member', :enable_admin_mode do
        it 'updates the member' do
          expect(source.users).to include(user)

          described_class.add_member(source, user, :maintainer, current_user: admin)

          expect(source.members.find_by(user_id: user).access_level).to eq(Gitlab::Access::MAINTAINER)
        end
      end

      context 'when current_user cannot update member' do
        it 'does not update the member' do
          expect(source.users).to include(user)

          described_class.add_member(source, user, :maintainer, current_user: user)

          expect(source.members.find_by(user_id: user).access_level).to eq(Gitlab::Access::DEVELOPER)
        end
      end
    end

    context 'when member is an invite by email' do
      let_it_be(:email) { 'user@email.com' }
      let_it_be(:existing_member) { source.add_developer(email) }

      it 'updates the member for that email' do
        expect do
          described_class.add_member(source, email, :maintainer)
        end.to change { existing_member.reset.access_level }.from(Member::DEVELOPER).to(Member::MAINTAINER)
                                                            .and not_change { source.members.invite.count }
      end
    end
  end
end

RSpec.shared_examples_for "bulk member creation" do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user1) { create(:user) }
  let_it_be(:user2) { create(:user) }

  context 'when current user does not have permission' do
    it 'does not succeed' do
      # maintainers cannot add owners
      source.add_maintainer(user)

      expect(described_class.add_members(source, [user1, user2], :owner, current_user: user)).to be_empty
    end
  end

  it 'returns Member objects' do
    members = described_class.add_members(source, [user1, user2], :maintainer)

    expect(members.map(&:user)).to contain_exactly(user1, user2)
    expect(members).to all(be_a(member_type))
    expect(members).to all(be_persisted)
  end

  it 'returns an empty array' do
    members = described_class.add_members(source, [], :maintainer)

    expect(members).to be_a Array
    expect(members).to be_empty
  end

  it 'supports different formats' do
    list = ['joe@local.test', admin, user1.id, user2.id.to_s]

    members = described_class.add_members(source, list, :maintainer)

    expect(members.size).to eq(4)
    expect(members.first).to be_invite
  end

  context 'with different source types' do
    shared_examples 'supports multiple sources' do
      specify do
        members = described_class.add_members(sources, [user1, user2], :maintainer)

        expect(members.map(&:user)).to contain_exactly(user1, user2, user1, user2)
        expect(members).to all(be_a(member_type))
        expect(members).to all(be_persisted)
      end
    end

    context 'with an array of sources' do
      let_it_be(:sources) { [source, source2] }

      it_behaves_like 'supports multiple sources'
    end

    context 'with a query producing sources' do
      let_it_be(:sources) { source_type.id_in([source, source2]) }

      it_behaves_like 'supports multiple sources'
    end
  end

  context 'with de-duplication' do
    it 'has the same user by id and user' do
      members = described_class.add_members(source, [user1.id, user1, user1.id, user2, user2.id, user2], :maintainer)

      expect(members.map(&:user)).to contain_exactly(user1, user2)
      expect(members).to all(be_a(member_type))
      expect(members).to all(be_persisted)
    end

    it 'has the same user sent more than once' do
      members = described_class.add_members(source, [user1, user1], :maintainer)

      expect(members.map(&:user)).to contain_exactly(user1)
      expect(members).to all(be_a(member_type))
      expect(members).to all(be_persisted)
    end
  end

  it 'with the same user sent more than once by user and by email' do
    members = described_class.add_members(source, [user1, user1.email], :maintainer)

    expect(members.map(&:user)).to contain_exactly(user1)
    expect(members).to all(be_a(member_type))
    expect(members).to all(be_persisted)
  end

  it 'with the same user sent more than once by user id and by email' do
    members = described_class.add_members(source, [user1.id, user1.email], :maintainer)

    expect(members.map(&:user)).to contain_exactly(user1)
    expect(members).to all(be_a(member_type))
    expect(members).to all(be_persisted)
  end

  context 'when a member already exists' do
    before do
      source.add_member(user1, :developer)
    end

    it 'has the same user sent more than once with the member already existing' do
      expect do
        members = described_class.add_members(source, [user1, user1, user2], :maintainer)
        expect(members.map(&:user)).to contain_exactly(user1, user2)
        expect(members).to all(be_a(member_type))
        expect(members).to all(be_persisted)
      end.to change { Member.count }.by(1)
    end

    it 'supports existing users as expected with user_ids passed' do
      user3 = create(:user)

      expect do
        members = described_class.add_members(source, [user1.id, user2, user3.id], :maintainer)
        expect(members.map(&:user)).to contain_exactly(user1, user2, user3)
        expect(members).to all(be_a(member_type))
        expect(members).to all(be_persisted)
      end.to change { Member.count }.by(2)
    end

    it 'supports existing users as expected without user ids passed' do
      user3 = create(:user)

      expect do
        members = described_class.add_members(source, [user1, user2, user3], :maintainer)
        expect(members.map(&:user)).to contain_exactly(user1, user2, user3)
        expect(members).to all(be_a(member_type))
        expect(members).to all(be_persisted)
      end.to change { Member.count }.by(2)
    end
  end

  context 'when `tasks_to_be_done` and `tasks_project_id` are passed' do
    let(:task_project) { source.is_a?(Group) ? create(:project, group: source) : source }

    it 'creates a member_task with the correct attributes', :aggregate_failures do
      members = described_class.add_members(source, [user1], :developer, tasks_to_be_done: %w(ci code), tasks_project_id: task_project.id)
      member = members.last

      expect(member.tasks_to_be_done).to match_array([:ci, :code])
      expect(member.member_task.project).to eq(task_project)
    end

    context 'with an already existing member' do
      before do
        source.add_member(user1, :developer)
      end

      it 'does not update tasks to be done if tasks already exist', :aggregate_failures do
        member = source.members.find_by(user_id: user1.id)
        create(:member_task, member: member, project: task_project, tasks_to_be_done: %w(code ci))

        expect do
          described_class.add_members(
            source,
            [user1.id],
            :developer,
            tasks_to_be_done: %w(issues),
            tasks_project_id: task_project.id
          )
        end.not_to change { MemberTask.count }

        member.reset
        expect(member.tasks_to_be_done).to match_array([:code, :ci])
        expect(member.member_task.project).to eq(task_project)
      end

      it 'adds tasks to be done if they do not exist', :aggregate_failures do
        expect do
          described_class.add_members(
            source,
            [user1.id],
            :developer,
            tasks_to_be_done: %w(issues),
            tasks_project_id: task_project.id
          )
        end.to change { MemberTask.count }.by(1)

        member = source.members.find_by(user_id: user1.id)
        expect(member.tasks_to_be_done).to match_array([:issues])
        expect(member.member_task.project).to eq(task_project)
      end
    end
  end
end

RSpec.shared_examples 'owner management' do
  describe '.cannot_manage_owners?' do
    subject { described_class.cannot_manage_owners?(source, user) }

    context 'when maintainer' do
      before do
        source.add_maintainer(user)
      end

      it 'cannot manage owners' do
        expect(subject).to be_truthy
      end
    end

    context 'when owner' do
      before do
        source.add_owner(user)
      end

      it 'can manage owners' do
        expect(subject).to be_falsey
      end
    end
  end
end
