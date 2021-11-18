# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::InviteTeamMembersMenu do
  let_it_be(:owner) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:group) do
    build(:group).tap do |g|
      g.add_owner(owner)
    end
  end

  let(:context) { Sidebars::Groups::Context.new(current_user: owner, container: group) }

  subject(:invite_menu) { described_class.new(context) }

  context 'when the group is viewed by an owner of the group' do
    describe '#render?' do
      it 'renders the Invite team members link' do
        expect(invite_menu.render?).to eq(true)
      end

      context 'when the group already has at least 2 members' do
        before do
          group.add_guest(guest)
        end

        it 'does not render the link' do
          expect(invite_menu.render?).to eq(false)
        end
      end
    end

    describe '#title' do
      it 'displays the correct Invite team members text for the link in the side nav' do
        expect(invite_menu.title).to eq('Invite members')
      end
    end
  end

  context 'when the group is viewed by a guest user without admin permissions' do
    let(:context) { Sidebars::Groups::Context.new(current_user: guest, container: group) }

    before do
      group.add_guest(guest)
    end

    describe '#render?' do
      it 'does not render the link' do
        expect(subject.render?).to eq(false)
      end
    end
  end
end
