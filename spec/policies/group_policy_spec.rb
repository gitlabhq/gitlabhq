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

  let(:reporter_permissions) { [:admin_label] }

  let(:master_permissions) do
    [
      :create_projects,
      :admin_milestones
    ]
  end

  let(:owner_permissions) do
    [
      :admin_group,
      :admin_namespace,
      :admin_group_member,
      :change_visibility_level,
      :create_subgroup
    ]
  end

  before do
    group.add_guest(guest)
    group.add_reporter(reporter)
    group.add_developer(developer)
    group.add_master(master)
    group.add_owner(owner)
  end

  subject { described_class.new(current_user, group) }

  def expect_allowed(*permissions)
    permissions.each { |p| is_expected.to be_allowed(p) }
  end

  def expect_disallowed(*permissions)
    permissions.each { |p| is_expected.not_to be_allowed(p) }
  end

  context 'with no user' do
    let(:current_user) { nil }

    it do
      expect_allowed(:read_group)
      expect_disallowed(*reporter_permissions)
      expect_disallowed(*master_permissions)
      expect_disallowed(*owner_permissions)
    end
  end

  context 'guests' do
    let(:current_user) { guest }

    it do
      expect_allowed(:read_group)
      expect_disallowed(*reporter_permissions)
      expect_disallowed(*master_permissions)
      expect_disallowed(*owner_permissions)
    end
  end

  context 'reporter' do
    let(:current_user) { reporter }

    it do
      expect_allowed(:read_group)
      expect_allowed(*reporter_permissions)
      expect_disallowed(*master_permissions)
      expect_disallowed(*owner_permissions)
    end
  end

  context 'developer' do
    let(:current_user) { developer }

    it do
      expect_allowed(:read_group)
      expect_allowed(*reporter_permissions)
      expect_disallowed(*master_permissions)
      expect_disallowed(*owner_permissions)
    end
  end

  context 'master' do
    let(:current_user) { master }

    it do
      expect_allowed(:read_group)
      expect_allowed(*reporter_permissions)
      expect_allowed(*master_permissions)
      expect_disallowed(*owner_permissions)
    end
  end

  context 'owner' do
    let(:current_user) { owner }

    it do
      expect_allowed(:read_group)
      expect_allowed(*reporter_permissions)
      expect_allowed(*master_permissions)
      expect_allowed(*owner_permissions)
    end
  end

  context 'admin' do
    let(:current_user) { admin }

    it do
      expect_allowed(:read_group)
      expect_allowed(*reporter_permissions)
      expect_allowed(*master_permissions)
      expect_allowed(*owner_permissions)
    end
  end

  describe 'private nested group use the highest access level from the group and inherited permissions', :nested_groups do
    let(:nested_group) { create(:group, :private, parent: group) }

    before do
      nested_group.add_guest(guest)
      nested_group.add_guest(reporter)
      nested_group.add_guest(developer)
      nested_group.add_guest(master)

      group.owners.destroy_all

      group.add_guest(owner)
      nested_group.add_owner(owner)
    end

    subject { described_class.new(current_user, nested_group) }

    context 'with no user' do
      let(:current_user) { nil }

      it do
        expect_disallowed(:read_group)
        expect_disallowed(*reporter_permissions)
        expect_disallowed(*master_permissions)
        expect_disallowed(*owner_permissions)
      end
    end

    context 'guests' do
      let(:current_user) { guest }

      it do
        expect_allowed(:read_group)
        expect_disallowed(*reporter_permissions)
        expect_disallowed(*master_permissions)
        expect_disallowed(*owner_permissions)
      end
    end

    context 'reporter' do
      let(:current_user) { reporter }

      it do
        expect_allowed(:read_group)
        expect_allowed(*reporter_permissions)
        expect_disallowed(*master_permissions)
        expect_disallowed(*owner_permissions)
      end
    end

    context 'developer' do
      let(:current_user) { developer }

      it do
        expect_allowed(:read_group)
        expect_allowed(*reporter_permissions)
        expect_disallowed(*master_permissions)
        expect_disallowed(*owner_permissions)
      end
    end

    context 'master' do
      let(:current_user) { master }

      it do
        expect_allowed(:read_group)
        expect_allowed(*reporter_permissions)
        expect_allowed(*master_permissions)
        expect_disallowed(*owner_permissions)
      end
    end

    context 'owner' do
      let(:current_user) { owner }

      it do
        expect_allowed(:read_group)
        expect_allowed(*reporter_permissions)
        expect_allowed(*master_permissions)
        expect_allowed(*owner_permissions)
      end
    end

    context 'auditor' do
      let(:current_user) { auditor }

      it do
        is_expected.to be_allowed(:read_group)
        is_expected.to be_disallowed(*master_permissions)
        is_expected.to be_disallowed(*owner_permissions)
      end
    end
  end
end
