# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MemberEntity, feature_category: :groups_and_projects do
  let_it_be(:current_user) { create(:user) }

  let(:entity) { described_class.new(member, { current_user: current_user, group: group, source: source }) }
  let(:entity_hash) { entity.as_json }

  shared_examples 'member.json' do
    it 'matches json schema' do
      expect(entity.to_json).to match_schema('entities/member')
    end

    it 'correctly exposes `can_update`' do
      allow(member).to receive(:can_update?).and_return(true)

      expect(entity_hash[:can_update]).to be(true)
    end

    it 'correctly exposes `can_remove`' do
      allow(member).to receive(:can_remove?).and_return(true)

      expect(entity_hash[:can_remove]).to be(true)
    end

    describe '#access_level' do
      it 'correctly exposes `string_value`' do
        expect(entity_hash[:access_level][:string_value]).to eq(member.human_access_with_none)
      end
    end

    context 'when is_source_accessible_to_current_user is true' do
      before do
        allow(member).to receive(:is_source_accessible_to_current_user).and_return(true)
      end

      it 'exposes source and created_by' do
        expect(entity_hash[:source]).to be_present
        expect(entity_hash[:created_by]).to be_present
      end
    end

    context 'when is_source_accessible_to_current_user is false' do
      before do
        allow(member).to receive(:is_source_accessible_to_current_user).and_return(false)
      end

      it 'does not exposes source and created_by' do
        expect(entity_hash[:source]).to be_nil
        expect(entity_hash[:created_by]).to be_nil
      end
    end
  end

  shared_examples 'invite' do
    it 'correctly exposes `invite.avatar_url`' do
      avatar_url = 'https://www.gravatar.com/avatar/c4637cb869d5f94c3193bde4f23d4cdc?s=80&d=identicon'
      allow(entity).to receive(:avatar_icon_for_email).with(member.invite_email, Member::AVATAR_SIZE).and_return(avatar_url)

      expect(entity_hash[:invite][:avatar_url]).to match(avatar_url)
    end

    it 'correctly exposes `invite.can_resend`' do
      allow(member).to receive(:can_resend_invite?).and_return(true)

      expect(entity_hash[:invite][:can_resend]).to be(true)
    end

    it 'exposes `invite.user_state` as empty string' do
      expect(entity_hash[:invite][:user_state]).to eq('')
    end
  end

  shared_examples 'user state is blocked_pending_approval' do
    it 'displays proper user state' do
      expect(entity_hash[:invite][:user_state]).to eq('blocked_pending_approval')
    end
  end

  shared_examples 'exposes source type properties' do |is_direct_member, is_inherited_member, is_shared_member|
    it "exposes `is_direct_member` as `#{is_direct_member}`" do
      expect(entity_hash[:is_direct_member]).to be(is_direct_member)
    end

    it "exposes `is_inherited_member` as `#{is_inherited_member}`" do
      expect(entity_hash[:is_inherited_member]).to be(is_inherited_member)
    end

    it "exposes `is_shared_member` as `#{is_shared_member}`" do
      expect(entity_hash[:is_shared_member]).to be(is_shared_member)
    end
  end

  context 'group member' do
    let_it_be(:parent_group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: parent_group) }
    let_it_be(:shared_group) { create(:group) }

    let(:group) { subgroup }
    let(:source) { subgroup }
    let(:member) do
      GroupMemberPresenter.new(
        create(:group_member, source: subgroup, created_by: current_user), current_user: current_user
      )
    end

    it_behaves_like 'member.json'

    context 'invite' do
      let(:member) do
        GroupMemberPresenter.new(
          create(:group_member, :invited, source: subgroup, created_by: current_user), current_user: current_user
        )
      end

      it_behaves_like 'member.json'
      it_behaves_like 'invite'
    end

    context 'direct member' do
      it_behaves_like 'exposes source type properties', true, false, false
    end

    context 'inherited member' do
      let(:member) do
        GroupMemberPresenter.new(
          create(:group_member, source: parent_group, created_by: current_user), current_user: current_user
        )
      end

      it_behaves_like 'exposes source type properties', false, true, false
    end

    context 'shared member' do
      let(:member) do
        GroupMemberPresenter.new(
          create(:group_member, source: shared_group, created_by: current_user), current_user: current_user
        )
      end

      let(:group_group_link) { create(:group_group_link, shared_group: shared_group, shared_with_group: subgroup) }

      it_behaves_like 'exposes source type properties', false, false, true
    end

    context 'is_last_owner' do
      context 'when member is last owner' do
        before do
          allow(member).to receive(:last_owner?).and_return(true)
        end

        it 'exposes `is_last_owner` as `true`' do
          expect(entity_hash[:is_last_owner]).to be(true)
        end
      end

      context 'when owner is not last owner' do
        before do
          allow(member).to receive(:last_owner?).and_return(false)
        end

        it 'exposes `is_last_owner` as `false`' do
          expect(entity_hash[:is_last_owner]).to be(false)
        end
      end
    end

    context 'new member user state is blocked_pending_approval' do
      let(:user) { create(:user, :blocked_pending_approval) }
      let(:group_member) { create(:group_member, :invited, group: subgroup, invite_email: user.email) }
      let(:member) { GroupMemberPresenter.new(GroupMember.with_invited_user_state.find(group_member.id), current_user: current_user) }

      it_behaves_like 'user state is blocked_pending_approval'
    end
  end

  context 'project member' do
    let_it_be(:parent_group) { create(:group) }
    let_it_be(:project) { create(:project, group: parent_group) }
    let_it_be(:shared_group) { create(:group) }
    let_it_be(:personal_project) { create(:project) }

    let(:group) { project.group }
    let(:source) { project }
    let(:member) do
      ProjectMemberPresenter.new(
        create(:project_member, source: source, created_by: current_user), current_user: current_user
      )
    end

    it_behaves_like 'member.json'

    context 'invite' do
      let(:member) do
        ProjectMemberPresenter.new(
          create(:project_member, :invited, source: source, created_by: current_user), current_user: current_user
        )
      end

      it_behaves_like 'member.json'
      it_behaves_like 'invite'
    end

    context 'direct member' do
      it_behaves_like 'exposes source type properties', true, false, false

      context 'personal project' do
        let(:source) { personal_project }
        let(:group) { nil }

        it_behaves_like 'exposes source type properties', true, false, false
      end
    end

    context 'inherited member' do
      let(:member) do
        GroupMemberPresenter.new(
          create(:group_member, source: parent_group, created_by: current_user), current_user: current_user
        )
      end

      it_behaves_like 'exposes source type properties', false, true, false
    end

    context 'shared member' do
      let(:member) do
        GroupMemberPresenter.new(
          create(:group_member, source: shared_group, created_by: current_user), current_user: current_user
        )
      end

      let(:project_group_link) { create(:project_group_link, group: shared_group, project: project) }

      it_behaves_like 'exposes source type properties', false, false, true

      context 'personal project' do
        let(:source) { personal_project }
        let(:group) { nil }

        it_behaves_like 'exposes source type properties', false, false, true
      end
    end

    context 'new members user state is blocked_pending_approval' do
      let(:user) { create(:user, :blocked_pending_approval) }
      let(:project_member) { create(:project_member, :invited, source: project, invite_email: user.email) }
      let(:member) { ProjectMemberPresenter.new(ProjectMember.with_invited_user_state.find(project_member.id), current_user: current_user) }

      it_behaves_like 'user state is blocked_pending_approval'
    end
  end
end
