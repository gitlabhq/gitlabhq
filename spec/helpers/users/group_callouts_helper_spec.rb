# frozen_string_literal: true

require "spec_helper"

RSpec.describe Users::GroupCalloutsHelper do
  let(:user) { build_stubbed(:user) }
  let(:group) { build_stubbed(:group) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe '.show_invite_banner?' do
    subject { helper.show_invite_banner?(group) }

    before do
      # unless set up otherwise, we assume that the user is the only member of the group and its ancestor chain
      allow(group).to receive(:member_count).and_return(1)
      allow(group).to receive_message_chain(:members_with_parents, :count).and_return(1)
    end

    context 'when user has the invite_group_members ability for the group' do
      before do
        allow(Ability).to receive(:allowed?).with(user, :invite_group_members, group).and_return(true)
      end

      context 'when the invite_members_banner has not been dismissed' do
        it { is_expected.to eq(true) }

        context 'when the group was just created' do
          before do
            flash[:notice] = "Group #{group.name} was successfully created"
          end

          it { is_expected.to eq(false) }
        end

        context 'with other members' do
          context 'when there are other members in the group' do
            before do
              allow(group).to receive(:member_count).and_return(2)
            end

            it { is_expected.to eq(false) }
          end

          context 'when there are other members within ancestor groups' do
            before do
              allow(group).to receive_message_chain(:members_with_parents, :count).and_return(2)
            end

            it { is_expected.to eq(false) }
          end
        end
      end

      context 'when the invite_members_banner has been dismissed' do
        let(:user) do
          build(:user, group_callouts: [
            build(:group_callout, group: group, feature_name: 'invite_members_banner')
          ])
        end

        it { is_expected.to eq(false) }
      end
    end

    context 'when user does not have invite_group_members ability for the group' do
      before do
        allow(Ability).to receive(:allowed?).with(user, :invite_group_members, group).and_return(false)
      end

      it { is_expected.to eq(false) }
    end
  end
end
