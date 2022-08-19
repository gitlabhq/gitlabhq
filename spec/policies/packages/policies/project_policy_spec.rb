# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Policies::ProjectPolicy do
  include_context 'ProjectPolicy context'

  let(:project) { public_project }

  subject { described_class.new(current_user, project.packages_policy_subject) }

  describe 'deploy token access' do
    let!(:project_deploy_token) do
      create(:project_deploy_token, project: project, deploy_token: deploy_token)
    end

    subject { described_class.new(deploy_token, project.packages_policy_subject) }

    context 'when a deploy token with read_package_registry scope' do
      let(:deploy_token) { create(:deploy_token, read_package_registry: true) }

      it { is_expected.to be_allowed(:read_package) }

      it_behaves_like 'package access with repository disabled'
    end

    context 'when a deploy token with write_package_registry scope' do
      let(:deploy_token) { create(:deploy_token, write_package_registry: true) }

      it { is_expected.to be_allowed(:read_package) }

      it_behaves_like 'package access with repository disabled'
    end
  end

  describe 'read_package' do
    context 'with admin' do
      let(:current_user) { admin }

      it { is_expected.to be_allowed(:read_package) }

      it_behaves_like 'package access with repository disabled'
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:read_package) }
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(:read_package) }
    end

    context 'with developer' do
      let(:current_user) { developer }

      it { is_expected.to be_allowed(:read_package) }
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_allowed(:read_package) }
    end

    context 'with guest' do
      let(:current_user) { guest }

      it { is_expected.to be_allowed(:read_package) }
    end

    context 'with non member' do
      let(:current_user) { non_member }

      it { is_expected.to be_allowed(:read_package) }
    end

    context 'with anonymous' do
      let(:current_user) { anonymous }

      it { is_expected.to be_allowed(:read_package) }
    end
  end
end
