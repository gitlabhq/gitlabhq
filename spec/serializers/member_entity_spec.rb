# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MemberEntity do
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
  end

  shared_examples 'is_direct_member' do
    context 'when `source` is the same as `member.source`' do
      let(:source) { direct_member_source }

      it 'exposes `is_direct_member` as `true`' do
        expect(entity_hash[:is_direct_member]).to be(true)
      end
    end

    context 'when `source` is not the same as `member.source`' do
      let(:source) { inherited_member_source }

      it 'exposes `is_direct_member` as `false`' do
        expect(entity_hash[:is_direct_member]).to be(false)
      end
    end
  end

  context 'group member' do
    let(:group) { create(:group) }
    let(:source) { group }
    let(:member) { GroupMemberPresenter.new(create(:group_member, group: group), current_user: current_user) }

    it_behaves_like 'member.json'

    context 'invite' do
      let(:member) { GroupMemberPresenter.new(create(:group_member, :invited, group: group), current_user: current_user) }

      it_behaves_like 'member.json'
      it_behaves_like 'invite'
    end

    context 'is_direct_member' do
      let(:direct_member_source) { group }
      let(:inherited_member_source) { create(:group) }

      it_behaves_like 'is_direct_member'
    end
  end

  context 'project member' do
    let(:project) { create(:project) }
    let(:group) { project.group }
    let(:source) { project }
    let(:member) { ProjectMemberPresenter.new(create(:project_member, project: project), current_user: current_user) }

    it_behaves_like 'member.json'

    context 'invite' do
      let(:member) { ProjectMemberPresenter.new(create(:project_member, :invited, project: project), current_user: current_user) }

      it_behaves_like 'member.json'
      it_behaves_like 'invite'
    end

    context 'is_direct_member' do
      let(:direct_member_source) { project }
      let(:inherited_member_source) { group }

      it_behaves_like 'is_direct_member'
    end
  end
end
