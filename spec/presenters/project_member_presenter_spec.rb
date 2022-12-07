# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectMemberPresenter do
  let(:user) { double(:user) }
  let(:project) { double(:project) }
  let(:project_member) { double(:project_member, source: project) }
  let(:presenter) { described_class.new(project_member, current_user: user) }

  describe '#can_resend_invite?' do
    context 'when project_member is invited' do
      before do
        expect(project_member).to receive(:invite?).and_return(true)
      end

      context 'and user can admin_project_member' do
        before do
          allow(presenter).to receive(:can?).with(user, :admin_project_member, project).and_return(true)
        end

        it { expect(presenter.can_resend_invite?).to eq(true) }
      end

      context 'and user cannot admin_project_member' do
        before do
          allow(presenter).to receive(:can?).with(user, :admin_project_member, project).and_return(false)
        end

        it { expect(presenter.can_resend_invite?).to eq(false) }
      end
    end

    context 'when project_member is not invited' do
      before do
        expect(project_member).to receive(:invite?).and_return(false)
      end

      context 'and user can admin_project_member' do
        before do
          allow(presenter).to receive(:can?).with(user, :admin_project_member, project).and_return(true)
        end

        it { expect(presenter.can_resend_invite?).to eq(false) }
      end

      context 'and user cannot admin_project_member' do
        before do
          allow(presenter).to receive(:can?).with(user, :admin_project_member, project).and_return(false)
        end

        it { expect(presenter.can_resend_invite?).to eq(false) }
      end
    end
  end

  describe '#last_owner?' do
    context 'when member is the holder of the personal namespace' do
      before do
        allow(project_member).to receive(:holder_of_the_personal_namespace?).and_return(true)
      end

      it { expect(presenter.last_owner?).to eq(true) }
    end

    context 'when member is not the holder of the personal namespace' do
      before do
        allow(project_member).to receive(:holder_of_the_personal_namespace?).and_return(false)
      end

      it { expect(presenter.last_owner?).to eq(false) }
    end
  end

  describe '#can_update?' do
    context 'when user is NOT attempting to update an Owner' do
      before do
        allow(project_member).to receive(:owner?).and_return(false)
      end

      context 'when user can update_project_member' do
        before do
          allow(presenter).to receive(:can?).with(user, :update_project_member, presenter).and_return(true)
        end

        specify { expect(presenter.can_update?).to eq(true) }
      end

      context 'when user cannot update_project_member' do
        before do
          allow(presenter).to receive(:can?).with(user, :update_project_member, presenter).and_return(false)
          allow(presenter).to receive(:can?).with(user, :override_project_member, presenter).and_return(false)
        end

        specify { expect(presenter.can_update?).to eq(false) }
      end
    end

    context 'when user is attempting to update an Owner' do
      before do
        allow(project_member).to receive(:owner?).and_return(true)
      end

      context 'when user can manage owners' do
        before do
          allow(presenter).to receive(:can?).with(user, :manage_owners, project).and_return(true)
        end

        specify { expect(presenter.can_update?).to eq(true) }
      end

      context 'when user cannot manage owners' do
        before do
          allow(presenter).to receive(:can?).with(user, :manage_owners, project).and_return(false)
        end

        specify { expect(presenter.can_update?).to eq(false) }
      end
    end
  end

  describe '#can_remove?' do
    context 'when user is NOT attempting to remove an Owner' do
      before do
        allow(project_member).to receive(:owner?).and_return(false)
      end

      context 'when user can destroy_project_member' do
        before do
          allow(presenter).to receive(:can?).with(user, :destroy_project_member, presenter).and_return(true)
        end

        specify { expect(presenter.can_remove?).to eq(true) }
      end

      context 'when user cannot destroy_project_member' do
        before do
          allow(presenter).to receive(:can?).with(user, :destroy_project_member, presenter).and_return(false)
        end

        specify { expect(presenter.can_remove?).to eq(false) }
      end
    end

    context 'when user is attempting to remove an Owner' do
      before do
        allow(project_member).to receive(:owner?).and_return(true)
      end

      context 'when user can manage owners' do
        before do
          allow(presenter).to receive(:can?).with(user, :manage_owners, project).and_return(true)
        end

        specify { expect(presenter.can_remove?).to eq(true) }
      end

      context 'when user cannot manage owners' do
        before do
          allow(presenter).to receive(:can?).with(user, :manage_owners, project).and_return(false)
        end

        specify { expect(presenter.can_remove?).to eq(false) }
      end
    end
  end

  describe '#can_approve?' do
    context 'when project_member has request an invite' do
      before do
        expect(project_member).to receive(:request?).and_return(true)
      end

      context 'and user can update_project_member' do
        before do
          allow(presenter).to receive(:can_update?).and_return(true)
        end

        it { expect(presenter.can_approve?).to eq(true) }
      end

      context 'and user cannot update_project_member' do
        before do
          allow(presenter).to receive(:can_update?).and_return(false)
        end

        it { expect(presenter.can_approve?).to eq(false) }
      end
    end

    context 'when project_member did not request an invite' do
      before do
        expect(project_member).to receive(:request?).and_return(false)
      end

      context 'and user can update_project_member' do
        before do
          allow(presenter).to receive(:can_update?).and_return(true)
        end

        it { expect(presenter.can_approve?).to eq(false) }
      end

      context 'and user cannot update_project_member' do
        before do
          allow(presenter).to receive(:can_update?).and_return(false)
        end

        it { expect(presenter.can_approve?).to eq(false) }
      end
    end
  end

  describe 'valid level roles' do
    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?).with(member_user, :manage_owners, entity).and_return(can_manage_owners)
    end

    context 'when user cannot manage owners' do
      it_behaves_like '#valid_level_roles', :project do
        let(:expected_roles) { { 'Developer' => 30, 'Maintainer' => 40, 'Reporter' => 20 } }
        let(:can_manage_owners) { false }

        before do
          entity.group = group
        end
      end
    end

    context 'when user can manage owners' do
      it_behaves_like '#valid_level_roles', :project do
        let(:expected_roles) { { 'Developer' => 30, 'Maintainer' => 40, 'Owner' => 50, 'Reporter' => 20 } }
        let(:can_manage_owners) { true }

        before do
          entity.group = group
        end
      end
    end
  end
end
