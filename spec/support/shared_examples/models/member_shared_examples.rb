# frozen_string_literal: true

RSpec.shared_examples 'inherited access level as a member of entity' do
  let(:parent_entity) { create(:group) }
  let(:user) { create(:user) }
  let(:member) { entity.is_a?(Group) ? entity.group_member(user) : entity.project_member(user) }

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

      non_member = entity.is_a?(Group) ? entity.group_member(non_member_user) : entity.project_member(non_member_user)

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
  let(:expected_roles) { { 'Developer' => 30, 'Maintainer' => 40, 'Reporter' => 20 } }

  it 'returns all roles when no parent member is present' do
    expect(presenter.valid_level_roles).to eq(entity_member.class.access_level_roles)
  end

  it 'returns higher roles when a parent member is present' do
    group.add_reporter(member_user)

    expect(presenter.valid_level_roles).to eq(expected_roles)
  end
end

RSpec.shared_examples_for "member creation" do
  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:admin) }

  describe '#execute' do
    it 'returns a Member object', :aggregate_failures do
      member = described_class.new(source, user, :maintainer).execute

      expect(member).to be_a member_type
      expect(member).to be_persisted
    end

    context 'when admin mode is enabled', :enable_admin_mode do
      it 'sets members.created_by to the given admin current_user' do
        member = described_class.new(source, user, :maintainer, current_user: admin).execute

        expect(member.created_by).to eq(admin)
      end
    end

    context 'when admin mode is disabled' do
      it 'rejects setting members.created_by to the given admin current_user' do
        member = described_class.new(source, user, :maintainer, current_user: admin).execute

        expect(member.created_by).to be_nil
      end
    end

    it 'sets members.expires_at to the given expires_at' do
      member = described_class.new(source, user, :maintainer, expires_at: Date.new(2016, 9, 22)).execute

      expect(member.expires_at).to eq(Date.new(2016, 9, 22))
    end

    described_class.access_levels.each do |sym_key, int_access_level|
      it "accepts the :#{sym_key} symbol as access level", :aggregate_failures do
        expect(source.users).not_to include(user)

        member = described_class.new(source, user.id, sym_key).execute

        expect(member.access_level).to eq(int_access_level)
        expect(source.users.reload).to include(user)
      end

      it "accepts the #{int_access_level} integer as access level", :aggregate_failures do
        expect(source.users).not_to include(user)

        member = described_class.new(source, user.id, int_access_level).execute

        expect(member.access_level).to eq(int_access_level)
        expect(source.users.reload).to include(user)
      end
    end

    context 'with no current_user' do
      context 'when called with a known user id' do
        it 'adds the user as a member' do
          expect(source.users).not_to include(user)

          described_class.new(source, user.id, :maintainer).execute

          expect(source.users.reload).to include(user)
        end
      end

      context 'when called with an unknown user id' do
        it 'adds the user as a member' do
          expect(source.users).not_to include(user)

          described_class.new(source, non_existing_record_id, :maintainer).execute

          expect(source.users.reload).not_to include(user)
        end
      end

      context 'when called with a user object' do
        it 'adds the user as a member' do
          expect(source.users).not_to include(user)

          described_class.new(source, user, :maintainer).execute

          expect(source.users.reload).to include(user)
        end
      end

      context 'when called with a requester user object' do
        before do
          source.request_access(user)
        end

        it 'adds the requester as a member', :aggregate_failures do
          expect(source.users).not_to include(user)
          expect(source.requesters.exists?(user_id: user)).to be_truthy

          expect do
            described_class.new(source, user, :maintainer).execute
          end.to raise_error(Gitlab::Access::AccessDeniedError)

          expect(source.users.reload).not_to include(user)
          expect(source.requesters.reload.exists?(user_id: user)).to be_truthy
        end
      end

      context 'when called with a known user email' do
        it 'adds the user as a member' do
          expect(source.users).not_to include(user)

          described_class.new(source, user.email, :maintainer).execute

          expect(source.users.reload).to include(user)
        end
      end

      context 'when called with an unknown user email' do
        it 'creates an invited member' do
          expect(source.users).not_to include(user)

          described_class.new(source, 'user@example.com', :maintainer).execute

          expect(source.members.invite.pluck(:invite_email)).to include('user@example.com')
        end
      end

      context 'when called with an unknown user email starting with a number' do
        it 'creates an invited member', :aggregate_failures do
          email_starting_with_number = "#{user.id}_email@example.com"

          described_class.new(source, email_starting_with_number, :maintainer).execute

          expect(source.members.invite.pluck(:invite_email)).to include(email_starting_with_number)
          expect(source.users.reload).not_to include(user)
        end
      end
    end

    context 'when current_user can update member', :enable_admin_mode do
      it 'creates the member' do
        expect(source.users).not_to include(user)

        described_class.new(source, user, :maintainer, current_user: admin).execute

        expect(source.users.reload).to include(user)
      end

      context 'when called with a requester user object' do
        before do
          source.request_access(user)
        end

        it 'adds the requester as a member', :aggregate_failures do
          expect(source.users).not_to include(user)
          expect(source.requesters.exists?(user_id: user)).to be_truthy

          described_class.new(source, user, :maintainer, current_user: admin).execute

          expect(source.users.reload).to include(user)
          expect(source.requesters.reload.exists?(user_id: user)).to be_falsy
        end
      end
    end

    context 'when current_user cannot update member' do
      it 'does not create the member', :aggregate_failures do
        expect(source.users).not_to include(user)

        member = described_class.new(source, user, :maintainer, current_user: user).execute

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

          described_class.new(source, user, :maintainer, current_user: user).execute

          expect(source.users.reload).not_to include(user)
          expect(source.requesters.exists?(user_id: user)).to be_truthy
        end
      end
    end

    context 'when member already exists' do
      before do
        source.add_user(user, :developer)
      end

      context 'with no current_user' do
        it 'updates the member' do
          expect(source.users).to include(user)

          described_class.new(source, user, :maintainer).execute

          expect(source.members.find_by(user_id: user).access_level).to eq(Gitlab::Access::MAINTAINER)
        end
      end

      context 'when current_user can update member', :enable_admin_mode do
        it 'updates the member' do
          expect(source.users).to include(user)

          described_class.new(source, user, :maintainer, current_user: admin).execute

          expect(source.members.find_by(user_id: user).access_level).to eq(Gitlab::Access::MAINTAINER)
        end
      end

      context 'when current_user cannot update member' do
        it 'does not update the member' do
          expect(source.users).to include(user)

          described_class.new(source, user, :maintainer, current_user: user).execute

          expect(source.members.find_by(user_id: user).access_level).to eq(Gitlab::Access::DEVELOPER)
        end
      end
    end
  end

  describe '.add_users' do
    let_it_be(:user1) { create(:user) }
    let_it_be(:user2) { create(:user) }

    it 'returns a Member objects' do
      members = described_class.add_users(source, [user1, user2], :maintainer)

      expect(members).to be_a Array
      expect(members.size).to eq(2)
      expect(members.first).to be_a member_type
      expect(members.first).to be_persisted
    end

    it 'returns an empty array' do
      members = described_class.add_users(source, [], :maintainer)

      expect(members).to be_a Array
      expect(members).to be_empty
    end

    it 'supports different formats' do
      list = ['joe@local.test', admin, user1.id, user2.id.to_s]

      members = described_class.add_users(source, list, :maintainer)

      expect(members.size).to eq(4)
      expect(members.first).to be_invite
    end
  end
end
