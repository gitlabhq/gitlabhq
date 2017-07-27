require 'spec_helper'

describe GroupPolicy do
  let(:guest) { create(:user) }
  let(:reporter) { create(:user) }
  let(:developer) { create(:user) }
  let(:master) { create(:user) }
  let(:owner) { create(:user) }
  let(:auditor) { create(:user, :auditor) }
  let(:admin) { create(:admin) }
  let(:group) { create(:group) }

  before do
    group.add_guest(guest)
    group.add_reporter(reporter)
    group.add_developer(developer)
    group.add_master(master)
    group.add_owner(owner)
  end

  subject { described_class.new(current_user, group) }

  context 'when LDAP sync is not enabled' do
    context 'owner' do
      let(:current_user) { owner }

      it { is_expected.to be_disallowed(:override_group_member) }
    end

    context 'admin' do
      let(:current_user) { admin }

      it { is_expected.to be_disallowed(:override_group_member) }
    end
  end

  context 'when LDAP sync is enabled' do
    before do
      allow(group).to receive(:ldap_synced?).and_return(true)
    end

    context 'with no user' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:override_group_member) }
    end

    context 'guests' do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(:override_group_member) }
    end

    context 'reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_disallowed(:override_group_member) }
    end

    context 'developer' do
      let(:current_user) { developer }

      it { is_expected.to be_disallowed(:override_group_member) }
    end

    context 'master' do
      let(:current_user) { master }

      it { is_expected.to be_disallowed(:override_group_member) }
    end

    context 'owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:override_group_member) }
    end

    context 'admin' do
      let(:current_user) { admin }

      it { is_expected.to be_allowed(:override_group_member) }
    end
  end
end
