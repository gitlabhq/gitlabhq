# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Policies::GroupPolicy, feature_category: :package_registry do
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

      it { is_expected.to be_allowed(:read_package) }

      context 'when allow_guest_plus_roles_to_pull_packages is disabled' do
        before do
          stub_feature_flags(allow_guest_plus_roles_to_pull_packages: false)
        end

        it { is_expected.to be_disallowed(:read_package) }
      end
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

  describe 'read public package registry' do
    using RSpec::Parameterized::TableSyntax

    let_it_be_with_reload(:project) { create(:project, group: group) }
    let(:current_user) { can_read_group ? reporter : external_user }

    subject { described_class.new(current_user, group.packages_policy_subject) }

    before do
      group.update!(visibility_level: Gitlab::VisibilityLevel.const_get(group_visibility, false))
      project.update!(visibility_level: Gitlab::VisibilityLevel.const_get(project_visibility, false))
      project.project_feature.update!(package_registry_access_level: package_registry_access_level)
      stub_application_setting(package_registry_allow_anyone_to_pull_option: application_setting)
    end

    where(:group_visibility, :project_visibility, :package_registry_access_level, :can_read_group,
      :application_setting, :result) do
      'PRIVATE' | 'PRIVATE' | ::ProjectFeature::DISABLED | true  | true  | true
      'PRIVATE' | 'PRIVATE' | ::ProjectFeature::DISABLED | true  | false | true
      'PRIVATE' | 'PRIVATE' | ::ProjectFeature::DISABLED | false | true  | false
      'PRIVATE' | 'PRIVATE' | ::ProjectFeature::DISABLED | false | false | false

      'PRIVATE' | 'PRIVATE' | ::ProjectFeature::PRIVATE  | true  | true  | true
      'PRIVATE' | 'PRIVATE' | ::ProjectFeature::PRIVATE  | true  | false | true
      'PRIVATE' | 'PRIVATE' | ::ProjectFeature::PRIVATE  | false | true  | false
      'PRIVATE' | 'PRIVATE' | ::ProjectFeature::PRIVATE  | false | false | false

      'PRIVATE' | 'PRIVATE' | ::ProjectFeature::ENABLED  | true  | true  | true
      'PRIVATE' | 'PRIVATE' | ::ProjectFeature::ENABLED  | true  | false | true
      'PRIVATE' | 'PRIVATE' | ::ProjectFeature::ENABLED  | false | true  | false
      'PRIVATE' | 'PRIVATE' | ::ProjectFeature::ENABLED  | false | false | false

      'PRIVATE' | 'PRIVATE' | ::ProjectFeature::PUBLIC   | true  | true  | true
      'PRIVATE' | 'PRIVATE' | ::ProjectFeature::PUBLIC   | true  | false | true
      'PRIVATE' | 'PRIVATE' | ::ProjectFeature::PUBLIC   | false | true  | true
      'PRIVATE' | 'PRIVATE' | ::ProjectFeature::PUBLIC   | false | false | false

      'INTERNAL' | 'PRIVATE' | ::ProjectFeature::DISABLED | true  | true  | true
      'INTERNAL' | 'PRIVATE' | ::ProjectFeature::DISABLED | true  | false | true
      'INTERNAL' | 'PRIVATE' | ::ProjectFeature::DISABLED | false | true  | false
      'INTERNAL' | 'PRIVATE' | ::ProjectFeature::DISABLED | false | false | false

      'INTERNAL' | 'PRIVATE' | ::ProjectFeature::PRIVATE  | true  | true  | true
      'INTERNAL' | 'PRIVATE' | ::ProjectFeature::PRIVATE  | true  | false | true
      'INTERNAL' | 'PRIVATE' | ::ProjectFeature::PRIVATE  | false | true  | false
      'INTERNAL' | 'PRIVATE' | ::ProjectFeature::PRIVATE  | false | false | false

      'INTERNAL' | 'PRIVATE' | ::ProjectFeature::ENABLED  | true  | true  | true
      'INTERNAL' | 'PRIVATE' | ::ProjectFeature::ENABLED  | true  | false | true
      'INTERNAL' | 'PRIVATE' | ::ProjectFeature::ENABLED  | false | true  | false
      'INTERNAL' | 'PRIVATE' | ::ProjectFeature::ENABLED  | false | false | false

      'INTERNAL' | 'PRIVATE' | ::ProjectFeature::PUBLIC   | true  | true  | true
      'INTERNAL' | 'PRIVATE' | ::ProjectFeature::PUBLIC   | true  | false | true
      'INTERNAL' | 'PRIVATE' | ::ProjectFeature::PUBLIC   | false | true  | true
      'INTERNAL' | 'PRIVATE' | ::ProjectFeature::PUBLIC   | false | false | false
    end

    with_them do
      it { is_expected.to public_send(result ? :be_allowed : :be_disallowed, :read_package_within_public_registries) }
    end
  end
end
