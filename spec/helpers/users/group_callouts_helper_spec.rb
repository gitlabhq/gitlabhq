# frozen_string_literal: true

require "spec_helper"

RSpec.describe Users::GroupCalloutsHelper do
  let_it_be(:user, refind: true) { create(:user) }
  let_it_be(:group) { create(:group) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe '.show_invite_banner?' do
    subject { helper.show_invite_banner?(group) }

    context 'when user has the admin ability for the group' do
      before do
        group.add_owner(user)
      end

      context 'when the invite_members_banner has not been dismissed' do
        it { is_expected.to eq(true) }

        context 'when the group was just created' do
          before do
            flash[:notice] = "Group #{group.name} was successfully created"
          end

          it { is_expected.to eq(false) }
        end

        context 'with concerning multiple members' do
          let_it_be(:user_2) { create(:user) }

          context 'on current group' do
            before do
              group.add_guest(user_2)
            end

            it { is_expected.to eq(false) }
          end

          context 'on current group that is a subgroup' do
            let_it_be(:subgroup) { create(:group, parent: group) }

            subject { helper.show_invite_banner?(subgroup) }

            context 'with only one user on parent and this group' do
              it { is_expected.to eq(true) }
            end

            context 'when another user is on this group' do
              before do
                subgroup.add_guest(user_2)
              end

              it { is_expected.to eq(false) }
            end

            context 'when another user is on the parent group' do
              before do
                group.add_guest(user_2)
              end

              it { is_expected.to eq(false) }
            end
          end
        end
      end

      context 'when the invite_members_banner has been dismissed' do
        before do
          create(
            :group_callout,
            user: user,
            group: group,
            feature_name: described_class::INVITE_MEMBERS_BANNER
          )
        end

        it { is_expected.to eq(false) }
      end
    end

    context 'when user does not have admin ability for the group' do
      it { is_expected.to eq(false) }
    end
  end
end
