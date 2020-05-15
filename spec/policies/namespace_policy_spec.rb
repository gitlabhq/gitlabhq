# frozen_string_literal: true

require 'spec_helper'

describe NamespacePolicy do
  let(:user) { create(:user) }
  let(:owner) { create(:user) }
  let(:admin) { create(:admin) }
  let(:namespace) { create(:namespace, owner: owner) }

  let(:owner_permissions) { [:create_projects, :admin_namespace, :read_namespace, :read_statistics, :transfer_projects] }

  subject { described_class.new(current_user, namespace) }

  context 'with no user' do
    let(:current_user) { nil }

    it { is_expected.to be_banned }
  end

  context 'regular user' do
    let(:current_user) { user }

    it { is_expected.to be_disallowed(*owner_permissions) }
  end

  context 'owner' do
    let(:current_user) { owner }

    it { is_expected.to be_allowed(*owner_permissions) }

    context 'user who has exceeded project limit' do
      let(:owner) { create(:user, projects_limit: 0) }

      it { is_expected.to be_disallowed(:create_projects) }
      it { is_expected.to be_disallowed(:transfer_projects) }
    end
  end

  context 'admin' do
    let(:current_user) { admin }

    context 'when admin mode is enabled', :enable_admin_mode do
      it { is_expected.to be_allowed(*owner_permissions) }
    end

    context 'when admin mode is disabled' do
      it { is_expected.to be_disallowed(*owner_permissions) }
    end
  end
end
