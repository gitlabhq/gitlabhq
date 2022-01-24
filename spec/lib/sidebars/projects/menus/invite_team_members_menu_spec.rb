# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::InviteTeamMembersMenu do
  let_it_be(:project) { create(:project) }
  let_it_be(:guest) { create(:user) }

  let(:context) { Sidebars::Projects::Context.new(current_user: owner, container: project) }

  subject(:invite_menu) { described_class.new(context) }

  context 'when the project is viewed by an owner of the group' do
    let(:owner) { project.first_owner }

    describe '#render?' do
      it 'renders the Invite team members link' do
        expect(invite_menu.render?).to eq(true)
      end

      context 'when the project already has at least 2 members' do
        before do
          project.add_guest(guest)
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

  context 'when the project is viewed by a guest user without admin permissions' do
    let(:context) { Sidebars::Projects::Context.new(current_user: guest, container: project) }

    before do
      project.add_guest(guest)
    end

    describe '#render?' do
      it 'does not render' do
        expect(invite_menu.render?).to eq(false)
      end
    end
  end
end
