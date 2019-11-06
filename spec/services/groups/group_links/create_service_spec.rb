# frozen_string_literal: true

require 'spec_helper'

describe Groups::GroupLinks::CreateService, '#execute' do
  let(:parent_group_user) { create(:user) }
  let(:group_user) { create(:user) }
  let(:child_group_user) { create(:user) }

  let_it_be(:group_parent) { create(:group, :private) }
  let_it_be(:group) { create(:group, :private, parent: group_parent) }
  let_it_be(:group_child) { create(:group, :private, parent: group) }

  let_it_be(:shared_group_parent) { create(:group, :private) }
  let_it_be(:shared_group) { create(:group, :private, parent: shared_group_parent) }
  let_it_be(:shared_group_child) { create(:group, :private, parent: shared_group) }

  let_it_be(:project_parent) { create(:project, group: shared_group_parent) }
  let_it_be(:project) { create(:project, group: shared_group) }
  let_it_be(:project_child) { create(:project, group: shared_group_child) }

  let(:opts) do
    {
      shared_group_access: Gitlab::Access::DEVELOPER,
      expires_at: nil
    }
  end
  let(:user) { group_user }

  subject { described_class.new(group, user, opts) }

  before do
    group.add_guest(group_user)
    shared_group.add_owner(group_user)
  end

  it 'adds group to another group' do
    expect { subject.execute(shared_group) }.to change { group.shared_group_links.count }.from(0).to(1)
  end

  it 'returns false if shared group is blank' do
    expect { subject.execute(nil) }.not_to change { group.shared_group_links.count }
  end

  context 'user does not have access to group' do
    let(:user) { create(:user) }

    before do
      shared_group.add_owner(user)
    end

    it 'returns error' do
      result = subject.execute(shared_group)

      expect(result[:status]).to eq(:error)
      expect(result[:http_status]).to eq(404)
    end
  end

  context 'user does not have admin access to shared group' do
    let(:user) { create(:user) }

    before do
      group.add_guest(user)
      shared_group.add_developer(user)
    end

    it 'returns error' do
      result = subject.execute(shared_group)

      expect(result[:status]).to eq(:error)
      expect(result[:http_status]).to eq(404)
    end
  end

  context 'group hierarchies' do
    before do
      group_parent.add_owner(parent_group_user)
      group.add_owner(group_user)
      group_child.add_owner(child_group_user)
    end

    context 'group user' do
      let(:user) { group_user }

      it 'create proper authorizations' do
        subject.execute(shared_group)

        expect(Ability.allowed?(user, :read_project, project_parent)).to be_falsey
        expect(Ability.allowed?(user, :read_project, project)).to be_truthy
        expect(Ability.allowed?(user, :read_project, project_child)).to be_truthy
      end
    end

    context 'parent group user' do
      let(:user) { parent_group_user }

      it 'create proper authorizations' do
        subject.execute(shared_group)

        expect(Ability.allowed?(user, :read_project, project_parent)).to be_falsey
        expect(Ability.allowed?(user, :read_project, project)).to be_falsey
        expect(Ability.allowed?(user, :read_project, project_child)).to be_falsey
      end
    end

    context 'child group user' do
      let(:user) { child_group_user }

      it 'create proper authorizations' do
        subject.execute(shared_group)

        expect(Ability.allowed?(user, :read_project, project_parent)).to be_falsey
        expect(Ability.allowed?(user, :read_project, project)).to be_falsey
        expect(Ability.allowed?(user, :read_project, project_child)).to be_falsey
      end
    end
  end
end
