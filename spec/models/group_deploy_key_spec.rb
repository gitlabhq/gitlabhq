# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupDeployKey do
  let_it_be(:group) { create(:group) }
  let_it_be(:group_deploy_key) { create(:group_deploy_key) }

  it { is_expected.to validate_presence_of(:user) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_many(:groups) }

  it 'is of type DeployKey' do
    expect(build(:group_deploy_key).type).to eq('DeployKey')
  end

  describe '#group_deploy_keys_group_for' do
    subject { group_deploy_key.group_deploy_keys_group_for(group) }

    context 'when this group deploy key is linked to a given group' do
      it 'returns the relevant group_deploy_keys_group association' do
        group_deploy_keys_group = create(:group_deploy_keys_group, group: group, group_deploy_key: group_deploy_key)

        expect(subject).to eq(group_deploy_keys_group)
      end
    end

    context 'when this group deploy key is not linked to a given group' do
      it { is_expected.to be_nil }
    end
  end

  describe '.defined_enums' do
    it 'excludes the inherited enum' do
      expect(described_class.defined_enums).to eq({})
    end
  end

  describe '#can_be_edited_for' do
    let_it_be(:user) { create(:user) }

    subject { group_deploy_key.can_be_edited_for?(user, group) }

    context 'when a given user has the :update_group_deploy_key permission for that key' do
      it 'is true' do
        allow(Ability).to receive(:allowed?).with(user, :update_group_deploy_key, group_deploy_key).and_return(true)

        expect(subject).to be_truthy
      end
    end

    context 'when a given user does not have the :update_group_deploy_key permission for that key' do
      before do
        allow(Ability).to receive(:allowed?).with(user, :update_group_deploy_key, group_deploy_key).and_return(false)
      end

      it 'is true when this user has the :update_group_deploy_key_for_group permission for this group' do
        allow(Ability).to receive(:allowed?).with(user, :update_group_deploy_key_for_group, group_deploy_key.group_deploy_keys_group_for(group)).and_return(true)

        expect(subject).to be_truthy
      end

      it 'is false when this user does not have the :update_group_deploy_key_for_group permission for this group' do
        allow(Ability).to receive(:allowed?).with(user, :update_group_deploy_key_for_group, group_deploy_key.group_deploy_keys_group_for(group)).and_return(false)

        expect(subject).to be_falsey
      end
    end
  end

  describe '#group_deploy_keys_groups_for_user' do
    let_it_be(:user) { create(:user) }

    context 'when a group has a group deploy key' do
      let_it_be(:expected_association) { create(:group_deploy_keys_group, group: group, group_deploy_key: group_deploy_key) }

      it 'returns the related group_deploy_keys_group association when the user can read the group' do
        allow(Ability).to receive(:allowed?).with(user, :read_group, group).and_return(true)

        expect(group_deploy_key.group_deploy_keys_groups_for_user(user))
          .to contain_exactly(expected_association)
      end

      it 'does not return the related group_deploy_keys_group association when the user cannot read the group' do
        allow(Ability).to receive(:allowed?).with(user, :read_group, group).and_return(false)

        expect(group_deploy_key.group_deploy_keys_groups_for_user(user)).to be_empty
      end
    end
  end

  describe '.for_groups' do
    context 'when group deploy keys are enabled for some groups' do
      let_it_be(:group1) { create(:group) }
      let_it_be(:group2) { create(:group) }
      let_it_be(:group3) { create(:group) }
      let_it_be(:gdk1) { create(:group_deploy_key) }
      let_it_be(:gdk2) { create(:group_deploy_key) }
      let_it_be(:gdk3) { create(:group_deploy_key) }

      it 'returns these group deploy keys' do
        gdk1.groups << group1
        gdk1.groups << group2
        gdk2.groups << group3
        gdk3.groups << group2

        expect(described_class.for_groups([group1.id, group3.id])).to contain_exactly(gdk1, gdk2)
        expect(described_class.for_groups([group2.id])).to contain_exactly(gdk1, gdk3)
      end
    end
  end
end
