# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectMemberPresenter, feature_category: :groups_and_projects do
  let(:user) { double(:user) }
  let(:project) { double(:project) }
  let(:project_member) { double(:project_member, source: project) }
  let(:presenter) { described_class.new(project_member, current_user: user) }

  describe '#can_resend_invite?' do
    subject(:can_resend_invite) { presenter.can_resend_invite? }

    before do
      allow(project_member).to receive(:invite?).and_return(is_invited)
      allow(presenter).to receive(:can?).with(user, :admin_project_member, project).and_return(can_admin)
    end

    context 'when project_member is invited' do
      let(:is_invited) { true }

      context 'and user can admin_project_member' do
        let(:can_admin) { true }

        it { is_expected.to eq(true) }
      end

      context 'and user cannot admin_project_member' do
        let(:can_admin) { false }

        it { is_expected.to eq(false) }
      end
    end

    context 'when project_member is not invited' do
      let(:can_admin) { true }
      let(:is_invited) { false }

      it { is_expected.to eq(false) }
    end
  end

  describe '#last_owner?' do
    subject(:last_owner) { presenter.last_owner? }

    before do
      allow(project_member).to receive(:holder_of_the_personal_namespace?).and_return(is_holder)
    end

    context 'when member is the holder of the personal namespace' do
      let(:is_holder) { true }

      it { is_expected.to eq(true) }
    end

    context 'when member is not the holder of the personal namespace' do
      let(:is_holder) { false }

      it { is_expected.to eq(false) }
    end
  end

  describe '#can_update?' do
    subject(:can_update) { presenter.can_update? }

    before do
      allow(project_member).to receive(:owner?).and_return(is_owner)
    end

    context 'when user is NOT attempting to update an Owner' do
      let(:is_owner) { false }
      let(:can_update_member) { true }

      before do
        allow(presenter).to receive(:can?).with(user, :update_project_member, presenter).and_return(can_update_member)
        allow(presenter).to receive(:can?).with(user, :override_project_member, presenter).and_return(false)
      end

      context 'when user can update_project_member' do
        it { is_expected.to eq(true) }
      end

      context 'when user cannot update_project_member' do
        let(:can_update_member) { false }

        it { is_expected.to eq(false) }
      end
    end

    context 'when user is attempting to update an Owner' do
      let(:is_owner) { true }
      let(:can_manage_owners) { true }

      before do
        allow(presenter).to receive(:can?).with(user, :manage_owners, project).and_return(can_manage_owners)
      end

      context 'when user can manage owners' do
        it { is_expected.to eq(true) }
      end

      context 'when user cannot manage owners' do
        let(:can_manage_owners) { false }

        it { is_expected.to eq(false) }
      end
    end
  end

  describe '#can_remove?' do
    subject(:can_remove) { presenter.can_remove? }

    before do
      allow(project_member).to receive(:owner?).and_return(is_owner)
    end

    context 'when user is NOT attempting to remove an Owner' do
      let(:is_owner) { false }
      let(:can_destroy_member) { true }

      before do
        allow(presenter).to receive(:can?).with(user, :destroy_project_member, presenter).and_return(can_destroy_member)
      end

      context 'when user can destroy_project_member' do
        let(:can_destroy_member) { true }

        it { is_expected.to eq(true) }
      end

      context 'when user cannot destroy_project_member' do
        let(:can_destroy_member) { false }

        it { is_expected.to eq(false) }
      end
    end

    context 'when user is attempting to remove an Owner' do
      let(:is_owner) { true }
      let(:can_manage_owners) { true }

      before do
        allow(presenter).to receive(:can?).with(user, :manage_owners, project).and_return(can_manage_owners)
      end

      context 'when user can manage owners' do
        let(:can_manage_owners) { true }

        it { is_expected.to eq(true) }
      end

      context 'when user cannot manage owners' do
        let(:can_manage_owners) { false }

        it { is_expected.to eq(false) }
      end
    end
  end

  describe '#can_approve?' do
    subject(:can_approve) { presenter.can_approve? }

    before do
      allow(project_member).to receive(:request?).and_return(has_request)
      allow(presenter).to receive(:can_update?).and_return(can_update)
    end

    context 'when project_member has request an invite' do
      let(:has_request) { true }

      context 'and user can update_project_member' do
        let(:can_update) { true }

        it { is_expected.to eq(true) }
      end

      context 'and user cannot update_project_member' do
        let(:can_update) { false }

        it { is_expected.to eq(false) }
      end
    end

    context 'when project_member did not request an invite' do
      let(:has_request) { false }

      context 'and user can update_project_member' do
        let(:can_update) { true }

        it { is_expected.to eq(false) }
      end

      context 'and user cannot update_project_member' do
        let(:can_update) { false }

        it { is_expected.to eq(false) }
      end
    end
  end

  describe 'valid level roles' do
    context 'when current user is a developer' do
      it_behaves_like '#valid_level_roles', :project do
        let(:expected_roles) { { 'Developer' => 30, 'Reporter' => 20 } }

        before do
          entity.group = group
        end
      end
    end
  end
end
