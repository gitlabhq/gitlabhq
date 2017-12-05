require 'spec_helper'

describe ProjectMemberPresenter do
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

  describe '#can_update?' do
    context 'when user can update_project_member' do
      before do
        allow(presenter).to receive(:can?).with(user, :update_project_member, presenter).and_return(true)
      end

      it { expect(presenter.can_update?).to eq(true) }
    end

    context 'when user cannot update_project_member' do
      before do
        allow(presenter).to receive(:can?).with(user, :update_project_member, presenter).and_return(false)
        allow(presenter).to receive(:can?).with(user, :override_project_member, presenter).and_return(false)
      end

      it { expect(presenter.can_update?).to eq(false) }
    end
  end

  describe '#can_remove?' do
    context 'when user can destroy_project_member' do
      before do
        allow(presenter).to receive(:can?).with(user, :destroy_project_member, presenter).and_return(true)
      end

      it { expect(presenter.can_remove?).to eq(true) }
    end

    context 'when user cannot destroy_project_member' do
      before do
        allow(presenter).to receive(:can?).with(user, :destroy_project_member, presenter).and_return(false)
      end

      it { expect(presenter.can_remove?).to eq(false) }
    end
  end

  describe '#can_approve?' do
    context 'when project_member has request an invite' do
      before do
        expect(project_member).to receive(:request?).and_return(true)
      end

      context 'and user can update_project_member' do
        before do
          allow(presenter).to receive(:can?).with(user, :update_project_member, presenter).and_return(true)
        end

        it { expect(presenter.can_approve?).to eq(true) }
      end

      context 'and user cannot update_project_member' do
        before do
          allow(presenter).to receive(:can?).with(user, :update_project_member, presenter).and_return(false)
          allow(presenter).to receive(:can?).with(user, :override_project_member, presenter).and_return(false)
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
          allow(presenter).to receive(:can?).with(user, :update_project_member, presenter).and_return(true)
        end

        it { expect(presenter.can_approve?).to eq(false) }
      end

      context 'and user cannot update_project_member' do
        before do
          allow(presenter).to receive(:can?).with(user, :update_project_member, presenter).and_return(false)
        end

        it { expect(presenter.can_approve?).to eq(false) }
      end
    end
  end
end
