require 'spec_helper'

describe NamespacePolicy, models: true do
  let(:user) { create(:user) }
  let(:owner) { create(:user) }
  let(:auditor) { create(:user, :auditor) }
  let(:admin) { create(:admin) }
  let(:namespace) { create(:namespace, owner: owner) }

  let(:owner_permissions) do
    [
      :create_projects,
      :admin_namespace
    ]
  end

  let(:admin_permissions) { owner_permissions }

  subject { described_class.abilities(current_user, namespace).to_set }

  context 'with no user' do
    let(:current_user) { nil }

    it do
      is_expected.to be_empty
    end
  end

  context 'regular user' do
    let(:current_user) { user }

    it do
      is_expected.to be_empty
    end
  end

  context 'owner' do
    let(:current_user) { owner }

    it do
      is_expected.to include(*owner_permissions)
    end
  end

  context 'auditor' do
    let(:current_user) { auditor }

    it do
      is_expected.to be_empty
    end
  end

  context 'admin' do
    let(:current_user) { admin }

    it do
      is_expected.to include(*owner_permissions)
    end
  end
end
