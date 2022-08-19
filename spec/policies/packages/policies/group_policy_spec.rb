# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Policies::GroupPolicy do
  include_context 'GroupPolicy context'

  subject { described_class.new(current_user, group.packages_policy_subject) }

  describe 'read_package' do
    context 'with admin' do
      let(:current_user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:read_package) }
      end

      context 'when admin mode is disabled' do
        it { is_expected.to be_disallowed(:read_package) }
      end
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:read_package) }
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(:read_package) }
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_allowed(:read_package) }
    end

    context 'with guest' do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(:read_package) }
    end

    context 'with non member' do
      let(:current_user) { create(:user) }

      it { is_expected.to be_disallowed(:read_package) }
    end

    context 'with anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:read_package) }
    end
  end

  describe 'deploy token access' do
    let!(:group_deploy_token) do
      create(:group_deploy_token, group: group, deploy_token: deploy_token)
    end

    subject { described_class.new(deploy_token, group.packages_policy_subject) }

    context 'when a deploy token with read_package_registry scope' do
      let(:deploy_token) { create(:deploy_token, :group, read_package_registry: true) }

      it { is_expected.to be_allowed(:read_package) }
    end

    context 'when a deploy token with write_package_registry scope' do
      let(:deploy_token) { create(:deploy_token, :group, write_package_registry: true) }

      it { is_expected.to be_allowed(:read_package) }
    end
  end
end
