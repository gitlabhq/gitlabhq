require 'spec_helper'

describe GroupMemberPresenter do
  let(:user) { double(:user) }
  let(:group) { double(:group) }
  let(:group_member) { double(:group_member, source: group) }
  let(:presenter) { described_class.new(group_member, current_user: user) }

  describe '#can_resend_invite?' do
    context 'when group_member is invited' do
      before do
        expect(group_member).to receive(:invite?).and_return(true)
      end

      context 'and user can admin_group_member' do
        before do
          allow(presenter).to receive(:can?).with(user, :admin_group_member, group).and_return(true)
        end

        it { expect(presenter.can_resend_invite?).to eq(true) }
      end

      context 'and user cannot admin_group_member' do
        before do
          allow(presenter).to receive(:can?).with(user, :admin_group_member, group).and_return(false)
        end

        it { expect(presenter.can_resend_invite?).to eq(false) }
      end
    end

    context 'when group_member is not invited' do
      before do
        expect(group_member).to receive(:invite?).and_return(false)
      end

      context 'and user can admin_group_member' do
        before do
          allow(presenter).to receive(:can?).with(user, :admin_group_member, group).and_return(true)
        end

        it { expect(presenter.can_resend_invite?).to eq(false) }
      end

      context 'and user cannot admin_group_member' do
        before do
          allow(presenter).to receive(:can?).with(user, :admin_group_member, group).and_return(false)
        end

        it { expect(presenter.can_resend_invite?).to eq(false) }
      end
    end
  end

  describe '#can_update?' do
    context 'when user can update_group_member' do
      before do
        allow(presenter).to receive(:can?).with(user, :update_group_member, presenter).and_return(true)
      end

      it { expect(presenter.can_update?).to eq(true) }
    end

    context 'when user cannot update_group_member' do
      before do
        allow(presenter).to receive(:can?).with(user, :update_group_member, presenter).and_return(false)
        allow(presenter).to receive(:can?).with(user, :override_group_member, presenter).and_return(false)
      end

      it { expect(presenter.can_update?).to eq(false) }
    end
  end

  describe '#can_remove?' do
    context 'when user can destroy_group_member' do
      before do
        allow(presenter).to receive(:can?).with(user, :destroy_group_member, presenter).and_return(true)
      end

      it { expect(presenter.can_remove?).to eq(true) }
    end

    context 'when user cannot destroy_group_member' do
      before do
        allow(presenter).to receive(:can?).with(user, :destroy_group_member, presenter).and_return(false)
      end

      it { expect(presenter.can_remove?).to eq(false) }
    end
  end

  describe '#can_approve?' do
    context 'when group_member has request an invite' do
      before do
        expect(group_member).to receive(:request?).and_return(true)
      end

      context 'when user can update_group_member' do
        before do
          allow(presenter).to receive(:can?).with(user, :update_group_member, presenter).and_return(true)
        end

        it { expect(presenter.can_approve?).to eq(true) }
      end

      context 'when user cannot update_group_member' do
        before do
          allow(presenter).to receive(:can?).with(user, :update_group_member, presenter).and_return(false)
          allow(presenter).to receive(:can?).with(user, :override_group_member, presenter).and_return(false)
        end

        it { expect(presenter.can_approve?).to eq(false) }
      end
    end

    context 'when group_member did not request an invite' do
      before do
        expect(group_member).to receive(:request?).and_return(false)
      end

      context 'when user can update_group_member' do
        before do
          allow(presenter).to receive(:can?).with(user, :update_group_member, presenter).and_return(true)
        end

        it { expect(presenter.can_approve?).to eq(false) }
      end

      context 'when user cannot update_group_member' do
        before do
          allow(presenter).to receive(:can?).with(user, :update_group_member, presenter).and_return(false)
        end

        it { expect(presenter.can_approve?).to eq(false) }
      end
    end
  end
end
