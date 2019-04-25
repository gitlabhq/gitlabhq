# frozen_string_literal: true

require 'spec_helper'

describe NotificationRecipient do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }
  let(:target) { create(:issue, project: project) }

  subject(:recipient) { described_class.new(user, :watch, target: target, project: project) }

  describe '#has_access?' do
    before do
      allow(user).to receive(:can?).and_call_original
    end

    context 'user cannot read cross project' do
      it 'returns false' do
        expect(user).to receive(:can?).with(:read_cross_project).and_return(false)
        expect(recipient.has_access?).to eq false
      end
    end

    context 'user cannot read build' do
      let(:target) { build(:ci_pipeline) }

      it 'returns false' do
        expect(user).to receive(:can?).with(:read_build, target).and_return(false)
        expect(recipient.has_access?).to eq false
      end
    end

    context 'user cannot read commit' do
      let(:target) { build(:commit) }

      it 'returns false' do
        expect(user).to receive(:can?).with(:read_commit, target).and_return(false)
        expect(recipient.has_access?).to eq false
      end
    end

    context 'target has no policy' do
      let(:target) { double.as_null_object }

      it 'returns true' do
        expect(recipient.has_access?).to eq true
      end
    end
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
