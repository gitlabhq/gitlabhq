require 'spec_helper'

describe GroupPolicy, models: true do
  let(:guest) { create(:user) }
  let(:reporter) { create(:user) }
  let(:developer) { create(:user) }
  let(:master) { create(:user) }
  let(:owner) { create(:user) }
  let(:auditor) { create(:user, :auditor) }
  let(:admin) { create(:admin) }
  let(:group) { create(:group) }

  let(:master_permissions) do
    [
      :create_projects,
      :admin_milestones,
      :admin_label
    ]
  end

  let(:owner_permissions) do
    [
      :admin_group,
      :admin_namespace,
      :admin_group_member,
      :change_visibility_level
    ]
  end

  before do
    group.add_guest(guest)
    group.add_reporter(reporter)
    group.add_developer(developer)
    group.add_master(master)
    group.add_owner(owner)
  end

  subject { described_class.abilities(current_user, group).to_set }

  context 'with no user' do
    let(:current_user) { nil }

    it do
      is_expected.to include(:read_group)
      is_expected.not_to include(*master_permissions)
      is_expected.not_to include(*owner_permissions)
    end
  end

  context 'guests' do
    let(:current_user) { guest }

    it do
      is_expected.to include(:read_group)
      is_expected.not_to include(*master_permissions)
      is_expected.not_to include(*owner_permissions)
    end
  end

  context 'reporter' do
    let(:current_user) { reporter }

    it do
      is_expected.to include(:read_group)
      is_expected.not_to include(*master_permissions)
      is_expected.not_to include(*owner_permissions)
    end
  end

  context 'developer' do
    let(:current_user) { developer }

    it do
      is_expected.to include(:read_group)
      is_expected.not_to include(*master_permissions)
      is_expected.not_to include(*owner_permissions)
    end
  end

  context 'master' do
    let(:current_user) { master }

    it do
      is_expected.to include(:read_group)
      is_expected.to include(*master_permissions)
      is_expected.not_to include(*owner_permissions)
    end
  end

  context 'owner' do
    let(:current_user) { owner }

    it do
      is_expected.to include(:read_group)
      is_expected.to include(*master_permissions)
      is_expected.to include(*owner_permissions)
    end
  end

  context 'admin' do
    let(:current_user) { admin }

    it do
      is_expected.to include(:read_group)
      is_expected.to include(*master_permissions)
      is_expected.to include(*owner_permissions)
    end
  end

  describe 'private nested group inherit permissions' do
    let(:nested_group) { create(:group, :private, parent: group) }

    subject { described_class.abilities(current_user, nested_group).to_set }

    context 'with no user' do
      let(:current_user) { nil }

      it do
        is_expected.not_to include(:read_group)
        is_expected.not_to include(*master_permissions)
        is_expected.not_to include(*owner_permissions)
      end
    end

    context 'guests' do
      let(:current_user) { guest }

      it do
        is_expected.to include(:read_group)
        is_expected.not_to include(*master_permissions)
        is_expected.not_to include(*owner_permissions)
      end
    end

    context 'reporter' do
      let(:current_user) { reporter }

      it do
        is_expected.to include(:read_group)
        is_expected.not_to include(*master_permissions)
        is_expected.not_to include(*owner_permissions)
      end
    end

    context 'developer' do
      let(:current_user) { developer }

      it do
        is_expected.to include(:read_group)
        is_expected.not_to include(*master_permissions)
        is_expected.not_to include(*owner_permissions)
      end
    end

    context 'master' do
      let(:current_user) { master }

      it do
        is_expected.to include(:read_group)
        is_expected.to include(*master_permissions)
        is_expected.not_to include(*owner_permissions)
      end
    end

    context 'owner' do
      let(:current_user) { owner }

      it do
        is_expected.to include(:read_group)
        is_expected.to include(*master_permissions)
        is_expected.to include(*owner_permissions)
      end
    end

    context 'auditor' do
      let(:current_user) { auditor }

      it do
        is_expected.to include(:read_group)
        is_expected.to all(start_with("read"))
        is_expected.not_to include(*master_permissions)
        is_expected.not_to include(*owner_permissions)
      end
    end
  end
end
