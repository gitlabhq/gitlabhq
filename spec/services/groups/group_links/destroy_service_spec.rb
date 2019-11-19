# frozen_string_literal: true

require 'spec_helper'

describe Groups::GroupLinks::DestroyService, '#execute' do
  let(:user) { create(:user) }

  let_it_be(:group) { create(:group, :private) }
  let_it_be(:shared_group) { create(:group, :private) }
  let_it_be(:project) { create(:project, group: shared_group) }

  subject { described_class.new(nil, nil) }

  context 'single link' do
    let!(:link) { create(:group_group_link, shared_group: shared_group, shared_with_group: group) }

    it 'destroys link' do
      expect { subject.execute(link) }.to change { GroupGroupLink.count }.from(1).to(0)
    end

    it 'revokes project authorization' do
      group.add_developer(user)

      expect { subject.execute(link) }.to(
        change { Ability.allowed?(user, :read_project, project) }.from(true).to(false))
    end
  end

  context 'multiple links' do
    let_it_be(:another_group) { create(:group, :private) }
    let_it_be(:another_shared_group) { create(:group, :private) }

    let!(:links) do
      [
        create(:group_group_link, shared_group: shared_group, shared_with_group: group),
        create(:group_group_link, shared_group: shared_group, shared_with_group: another_group),
        create(:group_group_link, shared_group: another_shared_group, shared_with_group: group),
        create(:group_group_link, shared_group: another_shared_group, shared_with_group: another_group)
      ]
    end

    it 'updates project authorization once per group' do
      expect(GroupGroupLink).to receive(:delete)
      expect(group).to receive(:refresh_members_authorized_projects).once
      expect(another_group).to receive(:refresh_members_authorized_projects).once

      subject.execute(links)
    end

    it 'rolls back changes when error happens' do
      group.add_developer(user)

      expect(group).to receive(:refresh_members_authorized_projects).once.and_call_original
      expect(another_group).to(
        receive(:refresh_members_authorized_projects).and_raise('boom'))

      expect { subject.execute(links) }.to raise_error('boom')

      expect(GroupGroupLink.count).to eq(links.length)
      expect(Ability.allowed?(user, :read_project, project)).to be_truthy
    end
  end
end
