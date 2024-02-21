# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeployKeyPolicy, feature_category: :groups_and_projects do
  subject { described_class.new(current_user, deploy_key) }

  let_it_be(:current_user, refind: true) { create(:user) }
  let_it_be(:admin) { create(:user, :admin) }

  context 'when deploy key is public' do
    let_it_be(:deploy_key) { create(:deploy_key, public: true) }

    context 'and current_user is nil' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:read_deploy_key) }

      it { is_expected.to be_disallowed(:update_deploy_key) }

      it { is_expected.to be_disallowed(:update_deploy_key_title) }
    end

    context 'and current_user is present' do
      it { is_expected.to be_allowed(:read_deploy_key) }

      it { is_expected.to be_disallowed(:update_deploy_key) }

      it { is_expected.to be_disallowed(:update_deploy_key_title) }
    end

    context 'when current_user is admin' do
      let(:current_user) { admin }

      context 'when admin mode enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:read_deploy_key) }

        it { is_expected.to be_allowed(:update_deploy_key) }

        it { is_expected.to be_allowed(:update_deploy_key_title) }
      end

      context 'when admin mode disabled' do
        it { is_expected.to be_allowed(:read_deploy_key) }

        it { is_expected.to be_disallowed(:update_deploy_key) }

        it { is_expected.to be_disallowed(:update_deploy_key_title) }
      end
    end
  end

  context 'when deploy key is private' do
    let_it_be(:deploy_key) { create(:deploy_key, :private) }

    context 'and current_user is nil' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:read_deploy_key) }

      it { is_expected.to be_disallowed(:update_deploy_key) }

      it { is_expected.to be_disallowed(:update_deploy_key_title) }
    end

    context 'when current_user is admin' do
      let(:current_user) { admin }

      context 'when admin mode enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:read_deploy_key) }

        it { is_expected.to be_allowed(:update_deploy_key) }

        it { is_expected.to be_allowed(:update_deploy_key_title) }
      end

      context 'when admin mode disabled' do
        it { is_expected.to be_disallowed(:read_deploy_key) }

        it { is_expected.to be_disallowed(:update_deploy_key) }

        it { is_expected.to be_disallowed(:update_deploy_key_title) }
      end
    end

    context 'when assigned to the project' do
      let_it_be(:deploy_keys_project) { create(:deploy_keys_project, deploy_key: deploy_key) }

      before_all do
        deploy_keys_project.project.add_maintainer(current_user)
      end

      it { is_expected.to be_allowed(:read_deploy_key) }

      it { is_expected.to be_allowed(:update_deploy_key) }

      it { is_expected.to be_allowed(:update_deploy_key_title) }
    end

    context 'when assigned to another project' do
      it { is_expected.to be_disallowed(:read_deploy_key) }

      it { is_expected.to be_disallowed(:update_deploy_key) }

      it { is_expected.to be_disallowed(:update_deploy_key_title) }
    end

    context 'when assigned to miltiple projects' do
      let_it_be(:project_one) { create(:project) }
      let_it_be(:project_two) { create(:project) }

      before_all do
        create(:deploy_keys_project, project: project_one, deploy_key: deploy_key)
        create(:deploy_keys_project, project: project_two, deploy_key: deploy_key)

        project_one.add_maintainer(current_user)
      end

      it { is_expected.to be_allowed(:read_deploy_key) }

      it { is_expected.to be_allowed(:update_deploy_key) }

      it { is_expected.to be_disallowed(:update_deploy_key_title) }
    end
  end
end
