require 'spec_helper'

describe NotificationRecipient do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }
  let(:target) { create(:issue, project: project) }

  subject(:recipient) { described_class.new(user, :watch, target: target, project: project) }

  it 'denies access to a target when cross project access is denied' do
    allow(Ability).to receive(:allowed?).and_call_original
    expect(Ability).to receive(:allowed?).with(user, :read_cross_project, :global).and_return(false)

    expect(recipient.has_access?).to be_falsy
  end

  context '#notification_setting' do
    context 'for child groups', :nested_groups do
      let!(:moved_group) { create(:group) }
      let(:group) { create(:group) }
      let(:sub_group_1) { create(:group, parent: group) }
      let(:sub_group_2) { create(:group, parent: sub_group_1) }
      let(:project) { create(:project, namespace: moved_group) }

      before do
        sub_group_2.add_owner(user)
        moved_group.add_owner(user)
        Groups::TransferService.new(moved_group, user).execute(sub_group_2)

        moved_group.reload
      end

      context 'when notification setting is global' do
        before do
          user.notification_settings_for(group).global!
          user.notification_settings_for(sub_group_1).mention!
          user.notification_settings_for(sub_group_2).global!
          user.notification_settings_for(moved_group).global!
        end

        it 'considers notification setting from the first parent without global setting' do
          expect(subject.notification_setting.source).to eq(sub_group_1)
        end
      end

      context 'when notification setting is not global' do
        before do
          user.notification_settings_for(group).global!
          user.notification_settings_for(sub_group_1).mention!
          user.notification_settings_for(sub_group_2).watch!
          user.notification_settings_for(moved_group).disabled!
        end

        it 'considers notification setting from lowest group member in hierarchy' do
          expect(subject.notification_setting.source).to eq(moved_group)
        end
      end
    end
  end
end
